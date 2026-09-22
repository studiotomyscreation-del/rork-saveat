import Foundation

/// Real centres d'aide alimentaire in Liège, from Open Data Wallonie-Bruxelles
/// (ODWB) — "Centres d'aide alimentaire" (Ville de Liège), CC BY,
/// https://www.odwb.be/explore/dataset/centres-aide-alimentaire/information/,
/// last modified on the source 2022-06-17 at the time this was written.
///
/// Pilot Belgian provider (§ audit Open Data Belgique) — same role as
/// `MulhouseOpenDataProvider` played for France: validates the whole
/// pipeline (model, dedup, attribution, `BelgianAdministrativeDivisions`)
/// on a small, individually-verifiable dataset before scaling to more
/// Belgian sources. Coordinates below are copied verbatim from the
/// source's own `geo_point_2d` field (full precision) — never geocoded.
///
/// The source dataset lists 16 records; **2 are excluded here** because the
/// source itself marks them as not currently operating (same rule as the
/// RNA `statut == Active`-only filter — a real place a user could visit
/// matters more than a complete historical count): "Conférence
/// Saint-Vincent de Paul de Griveginée" (`abbreviation`: "Ne fonctionne
/// plus actuellement") and "Conférence Saint-Vincent de Paul de Chênée"
/// (`abbreviation`: "Fermeture temporaire"). Both had `schedule`:
/// "fermeture temporaire - contacter le 04/221.84.20" in the source.
nonisolated struct LiegeOpenDataProvider: AntiWastePlacesProviding {
    nonisolated var supportedCountries: ProviderCountryScope { .countries(["BE"]) }

    func places(in bbox: GeoBoundingBox) async -> [AntiWastePlace] {
        Self.centers.compactMap { center in
            guard (bbox.minLatitude...bbox.maxLatitude).contains(center.latitude),
                  (bbox.minLongitude...bbox.maxLongitude).contains(center.longitude)
            else { return nil }
            return Self.place(from: center)
        }
    }

    // MARK: - Seed data

    private struct Center {
        let id: String
        let name: String
        let street: String
        let postalCode: String
        let city: String
        let phone: String?
        let latitude: Double
        let longitude: Double
    }

    /// Snapshot taken from the dataset's own `/records` export, September
    /// 2026 (each record's `phone_numbers` may list several numbers, or mix
    /// in an email address — only the first genuine phone number is kept
    /// here, the model has no email field to invent one for).
    private static let centers: [Center] = [
        Center(id: "7", name: "Conférence Saint-Vincent de Paul La Cordée", street: "14 rue de l'Ecole Technique", postalCode: "4040", city: "Herstal", phone: "04/264.65.23", latitude: 50.6572832224, longitude: 5.6102669127),
        Center(id: "18", name: "Armée du Salut ASBL", street: "192 quai des Ardennes", postalCode: "4032", city: "Liège", phone: "04 341 04 95", latitude: 50.6128790983, longitude: 5.6129917007),
        Center(id: "8", name: "Conférence Saint-Vincent de Paul de Rocourt", street: "34 rue des Héros", postalCode: "4000", city: "Liège", phone: "04/278.07.63", latitude: 50.6818952792, longitude: 5.5528979167),
        Center(id: "10", name: "La Maison de Fragnée", street: "11 place des Franchises", postalCode: "4000", city: "Liège", phone: "04/254.12.39", latitude: 50.623638716, longitude: 5.5712807632),
        Center(id: "3", name: "Conférence Saint-Vincent de Paul Angleur", street: "3 place Andréa Jadoulle", postalCode: "4031", city: "Liège", phone: "04/344.14.42", latitude: 50.6114322412, longitude: 5.6001306252),
        Center(id: "9", name: "Conférence Saint-Vincent de Paul Sart Tilman", street: "rue Françoise Bernheim", postalCode: "4031", city: "Liège", phone: "04/247.15.11", latitude: 50.5927404523, longitude: 5.5701178499),
        Center(id: "13", name: "Centre Liégeois de Service Social du Laveu", street: "43 rue des Wallons", postalCode: "4000", city: "Liège", phone: "04/253.33.30", latitude: 50.6306049671, longitude: 5.5585585502),
        Center(id: "12", name: "ASBL Sainte-Walburge", street: "71 rue Sainte-Walburge", postalCode: "4000", city: "Liège", phone: "04/226.43.28", latitude: 50.6559534055, longitude: 5.5712591815),
        Center(id: "2", name: "Conférence Saint-Vincent de Paul Amercoeur", street: "20 rue d'Amercoeur", postalCode: "4020", city: "Liège", phone: "0490 18 58 94", latitude: 50.6372715235, longitude: 5.5891168886),
        Center(id: "14", name: "Centre Liégeois de Service Social Ouest", street: "72 rue Chevaufosse", postalCode: "4000", city: "Liège", phone: "04/225.13.16", latitude: 50.6386275239, longitude: 5.5569226739),
        Center(id: "6", name: "Conférence Saint-Vincent de Paul de Jupille", street: "145 rue du Couvent", postalCode: "4020", city: "Liège", phone: "0491/87.13.93", latitude: 50.6434352888, longitude: 5.6466782006),
        Center(id: "1", name: "Accueil Botanique", street: "12-14 rue de l'Evêché", postalCode: "4000", city: "Liège", phone: "0472/91.90.09", latitude: 50.6372776731, longitude: 5.5720499227),
        Center(id: "16", name: "La Nouvelle Jérusalem", street: "369 rue Winston Churchill", postalCode: "4020", city: "Liège", phone: "0465 57 63 65", latitude: 50.6428725199, longitude: 5.6138575516),
        Center(id: "17", name: "Allons Vivre Ensemble ASBL (AVE)", street: "4 rue Marengo", postalCode: "4000", city: "Liège", phone: "0470/94.09.30", latitude: 50.6488230479, longitude: 5.5907738634)
    ]

    // MARK: - Mapping

    private static func place(from center: Center) -> AntiWastePlace {
        AntiWastePlace(
            id: "odwb-liege-\(center.id)",
            name: center.name,
            category: .foodDistribution,
            latitude: center.latitude,
            longitude: center.longitude,
            address: center.street,
            city: center.city,
            postalCode: center.postalCode,
            department: BelgianAdministrativeDivisions.province(fromPostalCode: center.postalCode),
            countryCode: "BE",
            region: BelgianAdministrativeDivisions.region(fromPostalCode: center.postalCode),
            description: S.Map.foodDistributionDescription.s,
            phone: center.phone,
            source: .odwb,
            sourceID: center.id,
            sourceURLString: "https://www.odwb.be/explore/dataset/centres-aide-alimentaire/information/",
            license: "CC BY — Ville de Liège",
            isVerified: false
        )
    }
}
