import Foundation

/// Best-effort food-solidarity places from ADEME's open "Longue vie aux
/// objets — Acteurs de l'économie circulaire" dataset
/// (https://data.ademe.fr/datasets/longue-vie-aux-objets-acteurs-de-leconomie-circulaire,
/// live REST API on Data Fair, Licence Ouverte 2.0 / Etalab, ~387k rows,
/// updated weekly).
///
/// **Important limitation, checked before writing this code**: this dataset
/// is about *object* reuse and repair (furniture, clothing, appliances,
/// books…), not food. It has no food-specific category — `type_dacteur`
/// (commerce, artisan, collectivité, point d'apport volontaire…) and
/// `type_de_services` (achat/revente, don, réparation…) are both generic
/// across every object type, and a plain full-text search on "alimentaire"
/// mostly returns supermarkets and municipal food-waste collection points,
/// not food-donation places.
///
/// So this provider does **not** trust the dataset's own categorisation. It
/// keeps only records whose name or description actually names a known
/// French food-solidarity organisation (`foodKeywords`), verified
/// client-side after the query — a deliberately narrow, lower-recall filter
/// that favours precision over completeness.
///
/// **Verified live during Phase 3, with real queries against the production
/// API (not assumed): across a bounding box covering the whole Paris region,
/// `size=100` results and every keyword below, not one record's name
/// contained the matched phrase** — the dataset's full-text relevance
/// ranking surfaces unrelated matches instead (e.g. "La Banque Postale" for
/// "banque alimentaire"), and there is no exact-phrase query mode that
/// changed that. This provider is implemented and works against the real
/// API, but is **not** included in `AntiWasteRepository.shared` — see that
/// file. It is kept here, documented, in case a future dataset or a smarter
/// matching strategy makes it worth activating.
nonisolated struct ADEMEProvider: AntiWastePlacesProviding {
    /// This dataset only ever covers France — never queried for a map area
    /// resolved to another country (§ architecture internationale, ADEME).
    var supportedCountries: ProviderCountryScope { .countries(["FR"]) }

    private static let datasetID = "longue-vie-aux-objets-acteurs-de-leconomie-circulaire"
    private static let linesURL = "https://data.ademe.fr/data-fair/api/v1/datasets/\(datasetID)/lines"

    /// The API returns `date_de_derniere_modification` as a bare "yyyy-MM-dd"
    /// — `ISO8601DateFormatter` expects a time component and would silently
    /// return `nil` for it.
    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Known food-solidarity organisation names, used both as the full-text
    /// query and as the client-side verification phrase. Deliberately a
    /// short, high-confidence list rather than a generic "alimentaire" match.
    private static let foodKeywords = [
        "banque alimentaire",
        "restos du coeur",
        "restaurants du coeur",
        "épicerie solidaire",
        "épicerie sociale",
        "secours populaire",
        "croix-rouge",
        "croix rouge"
    ]

    func places(in bbox: GeoBoundingBox) async -> [AntiWastePlace] {
        await withTaskGroup(of: [AntiWastePlace].self) { group -> [AntiWastePlace] in
            for keyword in Self.foodKeywords {
                group.addTask { await Self.fetch(keyword: keyword, in: bbox) }
            }
            var byID: [String: AntiWastePlace] = [:]
            for await batch in group {
                for place in batch { byID[place.id] = place }
            }
            return Array(byID.values)
        }
    }

    private static func fetch(keyword: String, in bbox: GeoBoundingBox) async -> [AntiWastePlace] {
        var components = URLComponents(string: linesURL)
        components?.queryItems = [
            URLQueryItem(name: "bbox", value: "\(bbox.minLongitude),\(bbox.minLatitude),\(bbox.maxLongitude),\(bbox.maxLatitude)"),
            URLQueryItem(name: "q", value: keyword),
            URLQueryItem(name: "size", value: "50"),
            URLQueryItem(name: "select", value: "identifiant,paternite,nom,nom_commercial,description,adresse,ville,code_postal,latitude,longitude,site_web,telephone,horaires_osm,horaires_description,date_de_derniere_modification")
        ]
        guard let url = components?.url else { return [] }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return []
            }
            let decoded = try JSONDecoder().decode(AdemeResponse.self, from: data)
            return decoded.results.compactMap { row in
                place(from: row, matching: keyword)
            }
        } catch {
            // A slow or briefly unreachable ADEME endpoint never breaks the
            // map — it simply contributes no places for that keyword.
            return []
        }
    }

    /// `nil` unless the keyword genuinely appears in the record's own text —
    /// the query's relevance ranking alone is not trusted (see file doc).
    private static func place(from row: AdemeRow, matching keyword: String) -> AntiWastePlace? {
        let haystack = MealEngine.normalize([row.nom, row.nomCommercial, row.description]
            .compactMap { $0 }.joined(separator: " "))
        guard haystack.contains(MealEngine.normalize(keyword)) else { return nil }
        guard let lat = row.latitude, let lon = row.longitude else { return nil }

        let displayName = row.nomCommercial?.isEmpty == false ? row.nomCommercial! : (row.nom ?? keyword)
        let updatedAt = row.dateDeDerniereModification.flatMap(Self.dateOnlyFormatter.date(from:))

        return AntiWastePlace(
            id: "ademe-\(row.identifiant ?? UUID().uuidString)",
            name: displayName,
            category: .association,
            latitude: lat,
            longitude: lon,
            address: row.adresse ?? "",
            city: row.ville ?? "",
            postalCode: row.codePostal ?? "",
            countryCode: "FR",
            description: row.description ?? "",
            openingHours: row.horairesOsm ?? row.horairesDescription,
            websiteURLString: row.siteWeb,
            phone: row.telephone,
            source: .ademe,
            sourceID: row.identifiant ?? "",
            license: row.paternite.map { "Licence Ouverte 2.0 (Etalab) — \($0)" } ?? "Licence Ouverte 2.0 (Etalab)",
            lastUpdated: updatedAt,
            isVerified: false
        )
    }
}

// MARK: - ADEME / Data Fair response

private nonisolated struct AdemeResponse: Decodable, Sendable {
    var total: Int
    var results: [AdemeRow]
}

private nonisolated struct AdemeRow: Decodable, Sendable {
    var identifiant: String?
    var paternite: String?
    var nom: String?
    var nomCommercial: String?
    var description: String?
    var adresse: String?
    var ville: String?
    var codePostal: String?
    var latitude: Double?
    var longitude: Double?
    var siteWeb: String?
    var telephone: String?
    var horairesOsm: String?
    var horairesDescription: String?
    var dateDeDerniereModification: String?

    enum CodingKeys: String, CodingKey {
        case identifiant, paternite, nom, description, adresse, ville, latitude, longitude, telephone
        case nomCommercial = "nom_commercial"
        case codePostal = "code_postal"
        case siteWeb = "site_web"
        case horairesOsm = "horaires_osm"
        case horairesDescription = "horaires_description"
        case dateDeDerniereModification = "date_de_derniere_modification"
    }
}
