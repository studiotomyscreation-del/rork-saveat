import Foundation

/// Looks up a French SIRET or SIREN via **Recherche d'entreprises**, the
/// official keyless API run by DINUM/Etalab (`recherche-entreprises.api.gouv.fr`,
/// free, no API key, ~7 requests/second, aggregates INSEE Sirene and the
/// RNE — see https://recherche-entreprises.api.gouv.fr/docs/). Verified
/// against the live API while building this, not guessed from docs alone.
///
/// **SIRET** is the app's primary entry point (§6) and works precisely
/// here: a 14-digit query resolves to exactly the matched establishment,
/// never a different one at the same company.
///
/// **A bare SIREN is different.** This endpoint is a relevance search, not
/// a "list every establishment" API — querying a SIREN alone comes back
/// with an empty `matching_etablissements`; only the headquarters
/// (`siege`) is reliably available (confirmed live against a 23-establishment
/// SIREN). So today a multi-establishment SIREN (§9) resolves to `.single`
/// on its headquarters, with `totalEstablishmentCount` set so the caller
/// can say "this business has other locations too" instead of silently
/// acting like there's only one. Enumerating every establishment of a large
/// SIREN needs the INSEE Sirene API's own SIREN-filtered `/siret` listing,
/// which requires an OAuth bearer token — not safe to embed client-side, so
/// that path waits for a backend call in a later phase rather than being
/// guessed at here.
nonisolated struct FranceBusinessRegistryProvider: BusinessRegistryProviding {
    let countryCode = "FR"

    private static let baseURL = URL(string: "https://recherche-entreprises.api.gouv.fr/search")!

    func lookup(identifier: String) async throws -> BusinessLookupResult {
        let digits = identifier.filter(\.isNumber)
        guard digits.count == 14 || digits.count == 9 else {
            throw BusinessRegistryError.invalidIdentifierFormat
        }

        guard var components = URLComponents(url: Self.baseURL, resolvingAgainstBaseURL: false) else {
            throw BusinessRegistryError.invalidIdentifierFormat
        }
        components.queryItems = [URLQueryItem(name: "q", value: digits)]
        guard let url = components.url else { throw BusinessRegistryError.invalidIdentifierFormat }

        let response: SearchResponse
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            response = try decoder.decode(SearchResponse.self, from: data)
        } catch {
            throw BusinessRegistryError.serviceUnavailable
        }

        guard let entreprise = response.results.first else { return .notFound }

        if digits.count == 14 {
            let matched = entreprise.matchingEtablissements?.first { $0.siret == digits }
                ?? (entreprise.siege?.siret == digits ? entreprise.siege : nil)
            guard let matched else { return .notFound }
            return .single(record(for: matched, entreprise: entreprise))
        }

        guard let siege = entreprise.siege else { return .notFound }
        return .single(record(for: siege, entreprise: entreprise))
    }

    private func record(for etablissement: EtablissementDTO, entreprise: EntrepriseDTO) -> BusinessRegistryRecord {
        BusinessRegistryRecord(
            siren: entreprise.siren,
            siret: etablissement.siret,
            legalName: entreprise.nomRaisonSociale ?? entreprise.nomComplet ?? "",
            tradeName: etablissement.listeEnseignes?.first ?? etablissement.nomCommercial,
            activityCode: etablissement.activitePrincipale ?? entreprise.activitePrincipale,
            administrativeStatus: Self.administrativeStatus(
                from: etablissement.etatAdministratif ?? entreprise.etatAdministratif
            ),
            address: etablissement.adresse ?? "",
            postalCode: etablissement.codePostal ?? "",
            city: etablissement.libelleCommune ?? "",
            countryCode: "FR",
            isHeadquarters: etablissement.estSiege ?? false,
            totalEstablishmentCount: entreprise.nombreEtablissements
        )
    }

    /// "A" = actif, "F"/"C" = fermé/cessée — anything else is reported as
    /// `.unknown` rather than assumed active (§10: never auto-activate
    /// without evidence).
    private static func administrativeStatus(from code: String?) -> MerchantAdministrativeStatus {
        switch code {
        case "A": .active
        case "F", "C": .closed
        default: .unknown
        }
    }
}

// MARK: - Decoding shape (Recherche d'entreprises `/search` response)

private struct SearchResponse: Decodable {
    var results: [EntrepriseDTO]
}

private struct EntrepriseDTO: Decodable {
    var siren: String
    var nomComplet: String?
    var nomRaisonSociale: String?
    var nombreEtablissements: Int?
    var etatAdministratif: String?
    var activitePrincipale: String?
    var siege: EtablissementDTO?
    var matchingEtablissements: [EtablissementDTO]?
}

private struct EtablissementDTO: Decodable {
    var siret: String
    var adresse: String?
    var codePostal: String?
    var libelleCommune: String?
    var etatAdministratif: String?
    var activitePrincipale: String?
    var nomCommercial: String?
    var listeEnseignes: [String]?
    var estSiege: Bool?
}
