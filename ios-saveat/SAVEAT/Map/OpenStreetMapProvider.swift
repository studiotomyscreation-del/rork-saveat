import Foundation

/// Real places from OpenStreetMap, fetched through the public Overpass API.
///
/// **Tags used** (each checked against the OpenStreetMap Wiki before use,
/// never assumed):
/// - `amenity=food_sharing` — a shared shelf, box or cabinet for surplus
///   food (https://wiki.openstreetmap.org/wiki/Tag:amenity=food_sharing)
///   → `.foodSharing`. Still a rarely-used tag worldwide — kept as its own
///   query rather than assumed to cover France on its own (§1 of the map
///   sources import brief).
/// - `amenity=fridge` — a public/community fridge, tagged more often than
///   `food_sharing` for the same real-world concept
///   (https://wiki.openstreetmap.org/wiki/Tag:amenity=fridge) → `.communityFridge`
/// - `amenity=social_facility` + `social_facility=community_fridge` —
///   another naming convention for the same concept as `amenity=fridge`
///   → `.communityFridge`
/// - `amenity=social_facility` + `social_facility=food_bank` — a place that
///   distributes pre-packaged food, usually for free
///   (https://wiki.openstreetmap.org/wiki/Tag:social_facility=food_bank)
///   → `.foodDistribution`. Kept distinct from `.communityFridge`/`.foodSharing`
///   on purpose: not every food bank is freely open to the public the way a
///   community fridge is (§1 of the import brief).
/// - `amenity=social_facility` + `social_facility=soup_kitchen` — a place
///   that serves prepared meals, usually for free
///   (https://wiki.openstreetmap.org/wiki/Tag:social_facility=soup_kitchen)
///   → `.restaurant`
///
/// There is **no** OSM tag for "anti-waste grocery store", "épicerie
/// solidaire" or "SAVEAT partner deal" as such — `.antiWasteStore`,
/// `.solidarityGrocery`, `.partner`, `.deal` and `.basket` are not populated
/// from OpenStreetMap (see the Phase 3 report).
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
          node["amenity"="fridge"](\(box));
          way["amenity"="fridge"](\(box));
          node["amenity"="social_facility"]["social_facility"="community_fridge"](\(box));
          way["amenity"="social_facility"]["social_facility"="community_fridge"](\(box));
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
        case ("food_sharing", _): category = .foodSharing
        case ("fridge", _): category = .communityFridge
        case (_, "community_fridge"): category = .communityFridge
        case (_, "food_bank"): category = .foodDistribution
        case (_, "soup_kitchen"): category = .restaurant
        default: return nil
        }

        let street = [tags["addr:housenumber"], tags["addr:street"]]
            .compactMap { $0 }
            .joined(separator: " ")
        let name = tags["name"] ?? category.title
        let postalCode = tags["addr:postcode"] ?? ""

        return AntiWastePlace(
            id: "osm-\(element.type)-\(element.id)",
            name: name,
            category: category,
            latitude: lat,
            longitude: lon,
            address: street,
            city: tags["addr:city"] ?? "",
            postalCode: postalCode,
            // Routed through `AdministrativeDivisions` so this stays correct
            // for every country OSM covers, not just France — the postal
            // code alone is never enough (a `nil`/unmapped `addr:country`
            // yields `nil`, never a guess).
            department: AdministrativeDivisions.subdivision(countryCode: tags["addr:country"] ?? "", postalCode: postalCode),
            // `addr:country` is a free but usually-present OSM tag, already
            // ISO 3166-1 alpha-2 by convention on the wiki — taken as-is,
            // never inferred from anything else.
            countryCode: tags["addr:country"],
            // OSM's own tag wins when present; `AdministrativeDivisions`
            // only fills the gap for a country whose région/équivalent can
            // be derived from the postal code alone (none yet — see that
            // file).
            region: tags["addr:state"] ?? tags["addr:province"]
                ?? AdministrativeDivisions.region(countryCode: tags["addr:country"] ?? "", postalCode: postalCode),
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
