import Foundation

/// One particulier's claim on part of a `BasketOffer`'s stock.
///
/// Created the moment SAVEAT accepts a reservation request — the actual
/// stock decrement is a server-side atomic transaction (§27, §16-17), this
/// struct is only the client-visible record of the outcome, never the
/// source of truth for how much stock remains.
nonisolated struct Reservation: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var offerID: String
    var merchantID: String
    var userID: String
    var quantity: Int
    var unitPrice: Double
    /// ISO 4217, copied from the offer at reservation time so a later
    /// price change on the offer never rewrites what the user agreed to
    /// pay (§43 — never a hardcoded €).
    var currencyCode: String
    var createdAt: Date
    var pickupStart: Date
    var pickupEnd: Date
    var status: ReservationStatus

    nonisolated var totalPrice: Double { unitPrice * Double(quantity) }
}

/// §26 and §35 — mirrors the offer's own lifecycle without being the same
/// enum, since a reservation can be cancelled independently of its offer.
nonisolated enum ReservationStatus: String, Codable, Sendable {
    case pending
    case confirmed
    case collected
    case cancelled
    case expired
    case noShow = "no_show"

    nonisolated var title: String {
        switch self {
        case .pending: S.Pro.reservationStatusPending.s
        case .confirmed: S.Pro.reservationStatusConfirmed.s
        case .collected: S.Pro.reservationStatusCollected.s
        case .cancelled: S.Pro.reservationStatusCancelled.s
        case .expired: S.Pro.reservationStatusExpired.s
        case .noShow: S.Pro.reservationStatusNoShow.s
        }
    }
}
