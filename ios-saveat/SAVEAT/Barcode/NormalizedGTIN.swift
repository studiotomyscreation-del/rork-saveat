import Foundation

/// The single source of truth for barcode identity in SAVEAT.
///
/// Keeps three things side by side:
/// - `rawValue`: the string exactly as the scanner (or the user) gave it — for
///   display, debugging, traceability and providers that want it verbatim;
/// - `lookupCode`: that same code with only presentation characters removed —
///   what Open Food Facts receives, identical to the request made before
///   normalisation existed;
/// - `normalizedValue`: the canonical **GTIN-14** (GS1 left-zero padding, UPC-E
///   expanded to UPC-A first), present only for a valid code. All comparisons
///   go through it.
///
/// A GTIN is an international product identity: nothing here reads the
/// country, the language, the currency or `MarketContext`. It is always a
/// `String` — never an integer — so leading zeros keep their meaning.
///
/// Parsing never throws and never blocks the scan: an invalid or unsupported
/// code simply has no canonical form and still flows through the pipeline.
nonisolated struct NormalizedGTIN: Hashable, Sendable, CustomStringConvertible {

    /// Shape of the code as received.
    nonisolated enum Format: String, Hashable, Sendable {
        case gtin8
        case upcA
        case upcE
        case ean13
        case gtin14
    }

    /// Symbology reported by the camera. Only matters for 8 digits, where the
    /// same string can be a GTIN-8 (EAN-8) or a UPC-E.
    nonisolated enum SymbologyHint: Hashable, Sendable {
        case ean8
        case upcE
        case other
    }

    nonisolated enum InvalidReason: Hashable, Sendable {
        /// The last digit doesn't match the GS1 check digit.
        case checkDigit
        /// Declared UPC-E, but the number system isn't 0 or 1.
        case upcEStructure
    }

    nonisolated enum UnsupportedReason: Hashable, Sendable {
        case empty
        /// Something other than ASCII digits, spaces or hyphens.
        case nonNumeric
        /// Only 8, 12, 13 and 14 digits are GTINs.
        case length(Int)
    }

    nonisolated enum Validity: Hashable, Sendable {
        case valid
        case invalid(InvalidReason)
        case unsupported(UnsupportedReason)
    }

    /// Exactly as received, whitespace included.
    let rawValue: String
    /// ASCII digits once presentation characters are removed; nil if not numeric.
    let digits: String?
    /// Nil when the code isn't a supported GTIN shape.
    let format: Format?
    let validity: Validity
    /// Canonical 14-digit GTIN, only when `validity == .valid`.
    let normalizedValue: String?
    /// The UPC-A behind a UPC-E (check digit included), whatever its validity.
    let expandedUPCA: String?
    /// 8 digits read without a symbology hint that are valid both as a GTIN-8 and
    /// as a UPC-E. Resolved as GTIN-8 (the literal GS1 reading); later phases
    /// can decide to be more cautious.
    let isAmbiguousEightDigit: Bool

    nonisolated var isValid: Bool { validity == .valid }

    /// What external lookups receive: the scanned code, presentation characters
    /// removed. Non-numeric codes (demo items, Code 128 labels) pass through
    /// trimmed, exactly as before.
    nonisolated var lookupCode: String {
        digits ?? rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Identity used by `==` and `hash`: the canonical GTIN when valid, else the
    /// scanned code itself — so two invalid codes are only equal when identical.
    nonisolated var identityKey: String {
        if let normalizedValue { return "gtin:" + normalizedValue }
        return "raw:" + lookupCode
    }

    nonisolated var description: String {
        "GTIN(\(format?.rawValue ?? "none"), \(validity), raw: \"\(rawValue)\", canonical: \(normalizedValue ?? "nil"))"
    }

    // MARK: - Parsing

    /// Parses any scanned or typed string. Never fails; see `validity`.
    ///
    /// Only surrounding/inner whitespace and hyphens are treated as
    /// presentation ("0-12345-67890-5", "3 017620 422003"). Anything else makes
    /// the code non-numeric — an arbitrary string is never coerced into a GTIN.
    nonisolated init(parsing raw: String, hint: SymbologyHint? = nil) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            self.init(raw: raw, digits: nil, format: nil, validity: .unsupported(.empty))
            return
        }

        let stripped = trimmed.filter { !$0.isWhitespace && $0 != "-" }
        guard !stripped.isEmpty, stripped.allSatisfy({ GTINCheckDigit.digitValue($0) != nil }) else {
            self.init(raw: raw, digits: nil, format: nil, validity: .unsupported(.nonNumeric))
            return
        }

        switch stripped.count {
        case 8:
            self.init(raw: raw, eightDigits: stripped, hint: hint)
        case 12:
            self.init(raw: raw, digits: stripped, format: .upcA, padding: 2)
        case 13:
            self.init(raw: raw, digits: stripped, format: .ean13, padding: 1)
        case 14:
            self.init(raw: raw, digits: stripped, format: .gtin14, padding: 0)
        default:
            self.init(raw: raw, digits: stripped, format: nil, validity: .unsupported(.length(stripped.count)))
        }
    }

    /// Unsupported or failed-before-format results.
    private nonisolated init(raw: String, digits: String?, format: Format?, validity: Validity) {
        rawValue = raw
        self.digits = digits
        self.format = format
        self.validity = validity
        normalizedValue = nil
        expandedUPCA = nil
        isAmbiguousEightDigit = false
    }

    /// GTIN-12/13/14: validate, then left-pad with zeros to 14.
    private nonisolated init(raw: String, digits: String, format: Format, padding: Int) {
        rawValue = raw
        self.digits = digits
        self.format = format
        let valid = GTINCheckDigit.isValid(digits)
        validity = valid ? .valid : .invalid(.checkDigit)
        normalizedValue = valid ? String(repeating: "0", count: padding) + digits : nil
        expandedUPCA = nil
        isAmbiguousEightDigit = false
    }

    /// 8 digits: GTIN-8, or UPC-E expanded to UPC-A before padding.
    private nonisolated init(raw: String, eightDigits: String, hint: SymbologyHint?) {
        rawValue = raw
        digits = eightDigits

        let expansion = UPCE.expand(eightDigits)
        let isValidGTIN8 = GTINCheckDigit.isValid(eightDigits)
        let isValidUPCE = expansion.map(GTINCheckDigit.isValid) ?? false

        let resolvedFormat: Format
        switch hint {
        case .upcE:
            resolvedFormat = .upcE
        case .ean8:
            resolvedFormat = .gtin8
        case .other, nil:
            // Without the symbology, the literal GS1 reading (GTIN-8) wins unless
            // only the UPC-E reading carries a valid check digit.
            resolvedFormat = (!isValidGTIN8 && isValidUPCE) ? .upcE : .gtin8
        }
        format = resolvedFormat
        isAmbiguousEightDigit = (hint == nil || hint == .other) && isValidGTIN8 && isValidUPCE

        switch resolvedFormat {
        case .upcE:
            expandedUPCA = expansion
            if let expansion {
                validity = isValidUPCE ? .valid : .invalid(.checkDigit)
                normalizedValue = isValidUPCE ? "00" + expansion : nil
            } else {
                validity = .invalid(.upcEStructure)
                normalizedValue = nil
            }
        default:
            expandedUPCA = nil
            validity = isValidGTIN8 ? .valid : .invalid(.checkDigit)
            normalizedValue = isValidGTIN8 ? "000000" + eightDigits : nil
        }
    }

    // MARK: - Representations

    /// The canonical GTIN in a shorter GS1 field (8, 12, 13 or 14 digits), when
    /// only zeros need dropping. `036000291452` → 13: `0036000291452`; → 8: nil.
    nonisolated func representation(length: Int) -> String? {
        guard let normalizedValue, [8, 12, 13, 14].contains(length) else { return nil }
        let dropCount = 14 - length
        guard normalizedValue.prefix(dropCount).allSatisfy({ $0 == "0" }) else { return nil }
        return String(normalizedValue.dropFirst(dropCount))
    }

    // MARK: - Comparison

    nonisolated static func == (lhs: NormalizedGTIN, rhs: NormalizedGTIN) -> Bool {
        lhs.identityKey == rhs.identityKey
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(identityKey)
    }

    /// Same product: same canonical GTIN, or the very same scanned digits (so a
    /// code stored before normalisation, read without its symbology, still
    /// matches a fresh scan of the same pack).
    nonisolated func matches(_ other: NormalizedGTIN) -> Bool {
        if self == other { return true }
        if let digits, digits == other.digits { return true }
        return false
    }

    /// Compares two stored barcode strings (legacy or new) by normalising them
    /// at read time. Exact string equality — the historical rule — always holds.
    nonisolated static func sameProduct(_ lhs: String?, _ rhs: String?) -> Bool {
        guard let lhs, let rhs else { return false }
        if lhs == rhs { return true }
        return NormalizedGTIN(parsing: lhs).matches(NormalizedGTIN(parsing: rhs))
    }
}
