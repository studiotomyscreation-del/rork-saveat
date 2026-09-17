import SwiftUI

/// §8 of the SAVEAT PRO spec — a professional identifies their business by
/// SIRET (the app's primary entry point) or SIREN, via
/// `FranceBusinessRegistryProvider`. No other country is offered yet
/// (§42/§57 — only implement a country once a real, reliable source exists).
struct BusinessIdentifierView: View {
    var onConfirmed: (BusinessRegistryRecord) -> Void

    @State private var input = ""
    @State private var state: LookupState = .idle
    @FocusState private var isFieldFocused: Bool

    private enum LookupState {
        case idle
        case searching
        case found(BusinessRegistryRecord)
        case multiple([BusinessRegistryRecord])
        case notFound
        case error(String)
    }

    private let provider = FranceBusinessRegistryProvider()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                fieldCard

                switch state {
                case .found(let record):
                    resultCard(record)
                case .multiple(let records):
                    multipleCard(records)
                case .idle, .searching, .notFound, .error:
                    EmptyView()
                }
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .background(SaveatColors.background.ignoresSafeArea())
        .navigationTitle(S.Pro.signUpTitle.s)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(S.Pro.signUpTitle.s)
                .font(SaveatTypography.title(22))
                .foregroundStyle(SaveatColors.textPrimary)
            Text(S.Pro.signUpSubtitle.s)
                .font(SaveatTypography.body(15))
                .foregroundStyle(SaveatColors.textSecondary)
            SaveatBadge(text: S.Pro.signUpFreeNotice.s, tone: .brand, icon: "checkmark.seal.fill")
                .padding(.top, 2)
        }
    }

    private var fieldCard: some View {
        SaveatCard {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(S.Pro.siretFieldLabel.s)
                        .font(SaveatTypography.caption(12))
                        .foregroundStyle(SaveatColors.textSecondary)
                    TextField(S.Pro.siretFieldPlaceholder.s, text: $input)
                        .keyboardType(.numberPad)
                        .font(SaveatTypography.numeric(20))
                        .focused($isFieldFocused)
                        .onChange(of: input) { _, newValue in
                            input = String(newValue.filter(\.isNumber).prefix(14))
                        }
                    Divider()
                }

                if case .searching = state {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text(S.Pro.searchingEstablishment.s)
                            .font(SaveatTypography.caption(13))
                            .foregroundStyle(SaveatColors.textSecondary)
                    }
                } else if case .notFound = state {
                    inlineNotice(S.Pro.establishmentNotFound.s)
                } else if case .error(let message) = state {
                    inlineNotice(message)
                }

                SaveatPrimaryButton(
                    title: S.Pro.findEstablishmentCTA.s,
                    isLoading: isSearching,
                    isEnabled: canSearch
                ) {
                    Task { await search() }
                }
            }
        }
    }

    private var isSearching: Bool { if case .searching = state { true } else { false } }

    private var canSearch: Bool {
        (input.count == 14 || input.count == 9) && !isSearching
    }

    private func inlineNotice(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(SaveatBadgeTone.alert.foreground)
            Text(text)
                .font(SaveatTypography.caption(12.5))
                .foregroundStyle(SaveatBadgeTone.alert.foreground)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func resultCard(_ record: BusinessRegistryRecord) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SaveatBadge(
                text: record.administrativeStatus == .closed
                    ? S.Pro.statusEstablishmentClosed.s
                    : S.Pro.statusEstablishmentIdentified.s,
                tone: record.administrativeStatus == .closed ? .alert : .brand,
                icon: record.administrativeStatus == .closed ? "exclamationmark.triangle.fill" : "checkmark.seal.fill"
            )

            SaveatCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text(record.tradeName ?? record.legalName)
                        .font(SaveatTypography.headline(17))
                        .foregroundStyle(SaveatColors.textPrimary)
                    if let tradeName = record.tradeName, tradeName != record.legalName {
                        Text(record.legalName)
                            .font(SaveatTypography.caption(12.5))
                            .foregroundStyle(SaveatColors.textSecondary)
                    }

                    Divider()

                    detailRow(icon: "mappin.and.ellipse", text: "\(record.address), \(record.postalCode) \(record.city)")
                    if let activityCode = record.activityCode {
                        detailRow(icon: "briefcase.fill", text: activityCode)
                    }
                    detailRow(icon: "number", text: record.siret)

                    if let total = record.totalEstablishmentCount, total > 1 {
                        Text(S.Pro.otherEstablishmentsNotice.s)
                            .font(SaveatTypography.caption(11.5))
                            .foregroundStyle(SaveatColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 4)
                    }
                }
            }

            VStack(spacing: 10) {
                SaveatPrimaryButton(
                    title: S.Pro.thisIsMyEstablishment.s,
                    isEnabled: record.administrativeStatus != .closed
                ) {
                    onConfirmed(record)
                }
                SaveatTextButton(title: S.Pro.notMyEstablishment.s) {
                    withAnimation { state = .idle }
                    input = ""
                }
            }
        }
    }

    private func multipleCard(_ records: [BusinessRegistryRecord]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(S.Pro.multipleEstablishmentsTitle.s)
                .font(SaveatTypography.headline(15))
                .foregroundStyle(SaveatColors.textPrimary)

            VStack(spacing: 10) {
                ForEach(records) { record in
                    Button {
                        onConfirmed(record)
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "circle")
                                .foregroundStyle(SaveatColors.brand)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.city)
                                    .font(SaveatTypography.headline(14))
                                    .foregroundStyle(SaveatColors.textPrimary)
                                Text(record.address)
                                    .font(SaveatTypography.caption(12))
                                    .foregroundStyle(SaveatColors.textSecondary)
                                Text(record.siret)
                                    .font(SaveatTypography.caption(11))
                                    .foregroundStyle(SaveatColors.textSecondary)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background(SaveatColors.surface, in: .rect(cornerRadius: 14))
                    }
                    .buttonStyle(SoftPressStyle())
                }
            }
        }
    }

    private func detailRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(SaveatColors.textSecondary)
                .frame(width: 16)
            Text(text)
                .font(SaveatTypography.caption(13))
                .foregroundStyle(SaveatColors.textPrimary)
        }
    }

    private func search() async {
        isFieldFocused = false
        withAnimation { state = .searching }
        do {
            let result = try await provider.lookup(identifier: input)
            withAnimation {
                switch result {
                case .single(let record): state = .found(record)
                case .multiple(let records): state = .multiple(records)
                case .notFound: state = .notFound
                }
            }
        } catch BusinessRegistryError.invalidIdentifierFormat {
            withAnimation { state = .error(S.Pro.invalidIdentifierFormat.s) }
        } catch {
            withAnimation { state = .error(S.Pro.lookupServiceUnavailable.s) }
        }
    }
}

#Preview {
    NavigationStack {
        BusinessIdentifierView(onConfirmed: { _ in })
    }
}
