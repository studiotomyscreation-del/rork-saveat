import Foundation

/// Real places from OpenStreetMap, fetched through the public Overpass API.
///
/// **Tags used** (each checked against the OpenStreetMap Wiki before use,
/// never assumed):
/// - `amenity=food_sharing` — a shared shelf, box, cabinet or fridge for
///   surplus food (https://wiki.openstreetmap.org/wiki/Tag:amenity=food_sharing)
///   → `.communityFridge`
/// - `amenity=social_facility` + `social_facility=food_bank` — a place that
///   distributes pre-packaged food, usually for free
///   (https://wiki.openstreetmap.org/wiki/Tag:social_facility=food_bank)
///   → `.association`
/// - `amenity=social_facility` + `social_facility=soup_kitchen` — a place
///   that serves prepared meals, usually for free
///   (https://wiki.openstreetmap.org/wiki/Tag:social_facility=soup_kitchen)
///   → `.restaurant`
///
/// There is **no** OSM tag for "anti-waste grocery store" or "SAVEAT
/// partner deal" as such — `.antiWasteStore`, `.partner`, `.deal` and
/// `.basket` are not populated from OpenStreetMap (see the Phase 3 report).
///
/// Data is © OpenStreetMap contributors, ODbL — attribution is shown on the
/// map screen and on every place card sourced here.
nonisolated struct OpenStreetMapProvider: AntiWastePlacesProviding {
    private static let endpoint = URL(string: "https://overpass-api.de/api/interpreter")!
    /// Overpass asks clients to identify themselves; this is not an API key.
    private static let userAgent = "SAVEAT/1.0 (iOS; anti-gaspillage alimentaire; contact via App Store)"

    func places(in bbox: GeoBoundingBox) async -> [AntiWastePlace] {
        if let cached = await OverpassCache.shared.value(for: bbox) {
            return cached
        }

        guard let request = Self.makeRequest(for: bbox) else { return [] }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return []
            }
            let decoded = try JSONDecoder().decode(OverpassResponse.self, from: data)
            let places = decoded.elements.compactMap(Self.place(from:))
            await OverpassCache.shared.store(places, for: bbox)
            return places
        } catch {
            // Overpass being briefly unreachable (rate limit, network blip)
            // must never break the map — it just shows fewer pins this time.
            return []
        }
    }

    // MARK: - Request

    private static func makeRequest(for bbox: GeoBoundingBox) -> URLRequest? {
        // Overpass filter order is (south, west, north, east).
        let box = "\(bbox.minLatitude),\(bbox.minLongitude),\(bbox.maxLatitude),\(bbox.maxLongitude)"
        let query = """
        [out:json][timeout:25];
        (
          node["amenity"="food_sharing"](\(box));
          way["amenity"="food_sharing"](\(box));
          node["amenity"="social_facility"]["social_facility"="food_bank"](\(box));
          way["amenity"="social_facility"]["social_facility"="food_bank"](\(box));
          node["amenity"="social_facility"]["social_facility"="soup_kitchen"](\(box));
          way["amenity"="social_facility"]["social_facility"="soup_kitchen"](\(box));
        );
        out center tags;
        """

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 25
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        // `.urlQueryAllowed` leaves "=" and "&" unescaped, which would corrupt
        // this exact Overpass QL query (it contains `="food_sharing"`) once
        // embedded in a `data=` form body — only RFC 3986 "unreserved"
        // characters are safe to leave as-is here.
        let unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: unreserved) else {
            return nil
        }
        request.httpBody = "data=\(encodedQuery)".data(using: .utf8)
        return request
    }

    // MARK: - Mapping

    private static func place(from element: OverpassElement) -> AntiWastePlace? {
        guard let lat = element.latitude, let lon = element.longitude else { return nil }
        let tags = element.tags ?? [:]

        let category: AntiWasteCategory
        switch (tags["amenity"], tags["social_facility"]) {
        case ("food_sharing", _): category = .communityFridge
        case (_, "food_bank"): category = .association
        case (_, "soup_kitchen"): category = .restaurant
        default: return nil
        }

        let street = [tags["addr:housenumber"], tags["addr:street"]]
            .compactMap { $0 }
            .joined(separator: " ")
        let name = tags["name"] ?? category.title

        return AntiWastePlace(
            id: "osm-\(element.type)-\(element.id)",
            name: name,
            category: category,
            latitude: lat,
            longitude: lon,
            address: street,
            city: tags["addr:city"] ?? "",
            postalCode: tags["addr:postcode"] ?? "",
            // `addr:country` is a free but usually-present OSM tag, already
            // ISO 3166-1 alpha-2 by convention on the wiki — taken as-is,
            // never inferred from anything else.
            countryCode: tags["addr:country"],
            region: tags["addr:state"] ?? tags["addr:province"],
            description: tags["description"] ?? "",
            openingHours: tags["opening_hours"],
            websiteURLString: tags["website"] ?? tags["contact:website"],
            phone: tags["phone"] ?? tags["contact:phone"],
            source: .openStreetMap,
            sourceID: "\(element.type)/\(element.id)",
            sourceURLString: "https://www.openstreetmap.org/\(element.type)/\(element.id)",
            license: "ODbL — © OpenStreetMap contributors",
            isVerified: false
        )
    }
}

// MARK: - Overpass response

private nonisolated struct OverpassResponse: Decodable, Sendable {
    var elements: [OverpassElement]
}

private nonisolated struct OverpassElement: Decodable, Sendable {
    var type: String
    var id: Int
    var lat: Double?
    var lon: Double?
    var center: OverpassCenter?
    var tags: [String: String]?

    var latitude: Double? { lat ?? center?.lat }
    var longitude: Double? { lon ?? center?.lon }
}

private nonisolated struct OverpassCenter: Decodable, Sendable {
    var lat: Double
    var lon: Double
}

// MARK: - Cache

/// Short-lived in-memory cache so panning the map a little doesn't refire
/// the same Overpass query — the public instance explicitly asks callers not
/// to hammer it.
private actor OverpassCache {
    static let shared = OverpassCache()

    private struct Entry {
        let bbox: GeoBoundingBox
        let places: [AntiWastePlace]
        let fetchedAt: Date
    }

    private var entries: [Entry] = []
    private let ttl: TimeInterval = 600

    func value(for bbox: GeoBoundingBox) -> [AntiWastePlace]? {
        entries.removeAll { Date().timeIntervalSince($0.fetchedAt) > ttl }
        return entries.first { $0.bbox.generouslyContains(bbox) }?.places
    }

    func store(_ places: [AntiWastePlace], for bbox: GeoBoundingBox) {
        entries.removeAll { Date().timeIntervalSince($0.fetchedAt) > ttl }
        entries.append(Entry(bbox: bbox, places: places, fetchedAt: Date()))
        if entries.count > 20 { entries.removeFirst() }
    }
}
