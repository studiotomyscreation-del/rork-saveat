import Foundation

/// Real associations distributing food aid, from the RNA (Répertoire
/// National des Associations) — Ministère de l'Intérieur, Licence Ouverte
/// 2.0 (Etalab). Source pipeline (§ audit RNA, `scripts/test_rna_filtrage.py`
/// + `scripts/geocode_rna_candidates.py`): the national `rna_waldec` export
/// filtered on 9 keywords in the free-text `objet` field, `statut ==
/// Active` only, a second-level exclusion for animal food aid (a real
/// false-positive shape found in manual review — e.g. an association whose
/// `objet` matches "aide alimentaire" but is actually about feeding stray
/// animals), then batch-geocoded through the Géoplateforme CSV endpoint —
/// 4321 of 4389 candidates successfully geocoded (98.4%), never a guessed
/// coordinate for the rest.
///
/// **4321 places — far larger than `MulhouseOpenDataProvider`/
/// `LiegeOpenDataProvider`'s hand-written seed arrays (5 and 14 entries).**
/// That pattern does not scale here: this provider instead bundles
/// `Resources/RNACentresAideAlimentaire.csv` as an app resource and parses
/// it once, lazily, into a cached array — see `RNACache` below — rather
/// than a multi-thousand-line Swift literal.
///
/// Every record's `objet` (its own stated purpose, real free text from the
/// source) is used directly as `description` — more informative than a
/// fixed generic string, and it's exactly what a human reviewer read to
/// judge relevance in the first place.
///
/// A ~15% residual noise rate is a known, accepted trade-off after the two
/// filter levels (confirmed on two independent 40-row manual samples) —
/// mostly a keyword matching an `objet` that's actually about something
/// else (generic service clubs, advocacy-only associations, AMAP-style
/// local-farming support). Not filtered further: too easy to also drop a
/// real positive with a simple keyword rule. `isVerified` stays `false`
/// for every record, same as every other open-data import.
nonisolated struct RNAProvider: AntiWastePlacesProviding {
    /// Every address is in France — the RNA only covers French associations
    /// (metropolitan + DOM-TOM, minus Alsace-Moselle's separate local-law
    /// regime — see `test_rna_filtrage.py`'s doc comment).
    nonisolated var supportedCountries: ProviderCountryScope { .countries(["FR"]) }

    func places(in bbox: GeoBoundingBox) async -> [AntiWastePlace] {
        let all = await RNACache.shared.places()
        return all.filter {
            (bbox.minLatitude...bbox.maxLatitude).contains($0.latitude)
                && (bbox.minLongitude...bbox.maxLongitude).contains($0.longitude)
        }
    }

    // MARK: - Cache

    /// Parses the bundled CSV once per app run and caches the result — the
    /// same lazy-once-per-launch pattern as `NousAntiGaspiProvider`'s
    /// `GeocodeCache`, adapted here to a CSV parse instead of a network
    /// geocode (no network call at all: coordinates are already in the
    /// file, geocoded ahead of time by `geocode_rna_candidates.py`).
    private actor RNACache {
        static let shared = RNACache()

        private var resolved: [AntiWastePlace]?

        func places() async -> [AntiWastePlace] {
            if let resolved { return resolved }
            let places = RNAProvider.loadPlaces()
            resolved = places
            return places
        }
    }

    // MARK: - Loading

    private static func loadPlaces() -> [AntiWastePlace] {
        // TEMPORAIRE — diagnostic de chargement, à retirer une fois le
        // bundling du CSV confirmé par un vrai lancement de l'app.
        guard let url = Bundle.main.url(forResource: "RNACentresAideAlimentaire", withExtension: "csv"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else {
            #if DEBUG
            print("🔴 RNAProvider: fichier CSV introuvable dans le bundle")
            #endif
            // Never crashes the app over a missing/misbundled resource —
            // the map simply shows fewer pins, exactly like a provider
            // whose network call failed.
            return []
        }
        let rows = parseCSV(text)
        let header = rows.first ?? []
        let columnIndex = Dictionary(uniqueKeysWithValues: header.enumerated().map { ($1, $0) })

        func field(_ row: [String], _ name: String) -> String {
            guard let index = columnIndex[name], index < row.count else { return "" }
            return row[index]
        }

        let dataRows = rows.isEmpty ? [] : Array(rows.dropFirst())
        let places = dataRows.enumerated().compactMap { index, row -> AntiWastePlace? in
            guard let latitude = Double(field(row, "latitude")),
                  let longitude = Double(field(row, "longitude"))
            else { return nil }

            let postalCode = field(row, "postal_code")
            let name = field(row, "nom")
            let objet = field(row, "objet")

            return AntiWastePlace(
                id: "rna-\(index)",
                name: name,
                category: .association,
                latitude: latitude,
                longitude: longitude,
                address: field(row, "street"),
                city: field(row, "city"),
                postalCode: postalCode,
                department: AdministrativeDivisions.subdivision(countryCode: "FR", postalCode: postalCode),
                countryCode: "FR",
                region: AdministrativeDivisions.region(countryCode: "FR", postalCode: postalCode),
                description: objet,
                source: .dataGouvFr,
                sourceID: field(row, "siret"),
                sourceURLString: "https://www.data.gouv.fr/fr/datasets/repertoire-national-des-associations/",
                license: "Licence Ouverte 2.0 (Etalab) — Ministère de l'Intérieur (RNA)",
                isVerified: false
            )
        }

        #if DEBUG
        if places.isEmpty {
            print("🔴 RNAProvider: fichier trouvé mais 0 lieu parsé")
        } else {
            print("✅ RNAProvider: \(places.count) lieux chargés depuis le CSV")
        }
        #endif
        return places
    }

    /// Minimal RFC 4180 CSV parser — no third-party library available, and
    /// this file's `objet` column routinely has embedded commas (and,
    /// unlike a simple `.components(separatedBy: ",")` split, quoted
    /// fields with `""`-escaped quotes must survive intact). Written to
    /// match exactly how Python's own `csv` module (which produced this
    /// file, in `geocode_rna_candidates.py`) quotes fields — not a general
    /// CSV superset, just correct for this specific, self-produced file.
    private static func parseCSV(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var insideQuotes = false
        var previousWasCR = false

        let characters = Array(text)
        var index = 0
        while index < characters.count {
            let character = characters[index]
            if insideQuotes {
                if character == "\"" {
                    if index + 1 < characters.count, characters[index + 1] == "\"" {
                        currentField.append("\"")
                        index += 1
                    } else {
                        insideQuotes = false
                    }
                } else {
                    currentField.append(character)
                }
            } else if character == "\"" {
                insideQuotes = true
            } else if character == "," {
                currentRow.append(currentField)
                currentField = ""
            } else if character == "\n" {
                if !previousWasCR {
                    currentRow.append(currentField)
                    rows.append(currentRow)
                    currentRow = []
                    currentField = ""
                }
            } else if character == "\r" {
                currentRow.append(currentField)
                rows.append(currentRow)
                currentRow = []
                currentField = ""
            } else {
                currentField.append(character)
            }
            previousWasCR = character == "\r"
            index += 1
        }
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            rows.append(currentRow)
        }
        return rows
    }
}
