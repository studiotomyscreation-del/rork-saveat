import SwiftUI

/// SAVEAT V2 Home (§12) — reads the same `AppStore` as the existing
/// `HomeView`, styled with the V2 design system (`SaveatColors` /
/// `SaveatTypography` / `SaveatCard`). The real Accueil tab as of Phase 5
/// (Navigation V2) — `RootView` now wires every action closure for real.
///
/// `quickModes` (Mode 0 €, Fin de mois, Liste de courses) has no place in
/// the §12 card list, but those three screens had no other entry point
/// anywhere in the app before this screen replaced `HomeView` — dropping
/// them would have made them unreachable, which nothing here is allowed to
/// do. They keep working exactly as before, just via `path` instead of
/// dedicated big buttons.
struct NewHomeView: View {
    @Environment(AppStore.self) private var store
    @Environment(SubscriptionStore.self) private var subscriptions
    @State private var viewModel = HomeViewModel()
    @State private var showsPaywall = false
    @Binding var path: NavigationPath

    let onScan: () -> Void
    let onOpenRecipes: () -> Void
    var onOpenStock: (() -> Void)? = nil
    let onOpenMap: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                savingsCard
                rescueCard
                recipeCard
                nearbyCard
                actions
                quickModes
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(SaveatColors.background.ignoresSafeArea())
        .sheet(isPresented: $showsPaywall) { PaywallSheet(feature: .endOfMonth) }
        .task {
            await viewModel.loadNearbyIfNeeded()
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(S.Home.greeting.s)
                .font(SaveatTypography.headline(15))
                .foregroundStyle(SaveatColors.brand)
            Text(S.NewHome.headline.s)
                .font(SaveatTypography.hero(27))
                .foregroundStyle(SaveatColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(store.profile.householdText)
                .font(SaveatTypography.caption(13))
                .foregroundStyle(SaveatColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    // MARK: Économies ce mois-ci

    private var savingsCard: some View {
        SaveatCard {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: S.NewHome.savingsCardLabel.s, color: SaveatColors.forestDeep)
                Text(Format.euro(store.monthlyImpact.moneySaved))
                    .font(SaveatTypography.numeric(32))
                    .foregroundStyle(SaveatColors.brand)
                Text(S.Home.estimateNote.s)
                    .font(SaveatTypography.caption(11.5))
                    .foregroundStyle(SaveatColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Aliments à sauver

    @ViewBuilder
    private var rescueCard: some View {
        let queue = store.rescueQueue
        SaveatCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: S.NewHome.rescueCardLabel.s, color: SaveatColors.forestDeep)
                if queue.isEmpty {
                    Text(S.Home.nothingUrgent.s)
                        .font(SaveatTypography.body(14))
                        .foregroundStyle(SaveatColors.textSecondary)
                } else {
                    ForEach(queue.prefix(3)) { item in
                        HStack(spacing: 10) {
                            Text(item.emoji).font(.system(size: 18))
                            Text(item.displayName)
                                .font(SaveatTypography.headline(14))
                                .foregroundStyle(SaveatColors.textPrimary)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            Text(item.deadlineText)
                                .font(SaveatTypography.caption(12))
                                .foregroundStyle(StatusTint.color(for: item.status))
                        }
                    }
                    if queue.count > 3 {
                        Text(queue.count - 3 > 1
                             ? S.Home.rescueSubtitlePlural.f(queue.count - 3)
                             : S.Home.rescueSubtitle.f(queue.count - 3))
                            .font(SaveatTypography.caption(12))
                            .foregroundStyle(SaveatColors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: Recette du jour

    private var recipeCard: some View {
        SaveatCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: S.NewHome.recipeCardLabel.s, color: SaveatColors.forestDeep)
                if let recipe = store.suggestions().first {
                    HStack(spacing: 12) {
                        Text(recipe.emoji).font(.system(size: 26))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(recipe.displayName)
                                .font(SaveatTypography.headline(15))
                                .foregroundStyle(SaveatColors.textPrimary)
                            Text(recipe.timeText)
                                .font(SaveatTypography.caption(12))
                                .foregroundStyle(SaveatColors.textSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                } else {
                    Text(S.NewHome.recipeEmpty.s)
                        .font(SaveatTypography.body(14))
                        .foregroundStyle(SaveatColors.textSecondary)
                }
            }
        }
    }

    // MARK: Bons plans autour de moi

    private var nearbyCard: some View {
        SaveatCard {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: S.NewHome.nearbyCardLabel.s, color: SaveatColors.forestDeep)
                if viewModel.isLoadingNearby {
                    ProgressView().tint(SaveatColors.brand)
                } else if viewModel.nearbyPlaces.isEmpty {
                    Text(S.NewHome.nearbyEmpty.s)
                        .font(SaveatTypography.body(14))
                        .foregroundStyle(SaveatColors.textSecondary)
                } else {
                    Text(viewModel.nearbyPlaces.count > 1
                         ? S.NewHome.nearbyCountPlural.f(viewModel.nearbyPlaces.count)
                         : S.NewHome.nearbyCount.f(viewModel.nearbyPlaces.count))
                        .font(SaveatTypography.headline(16))
                        .foregroundStyle(SaveatColors.textPrimary)
                }
                if viewModel.locationManager.status != .authorized {
                    Text(S.NewHome.nearbyLocationHint.s)
                        .font(SaveatTypography.caption(11.5))
                        .foregroundStyle(SaveatColors.textSecondary)
                }
            }
        }
    }

    // MARK: Actions

    private var actions: some View {
        VStack(spacing: 10) {
            SaveatPrimaryButton(title: S.NewHome.scanCTA.s, action: onScan)
            actionRow(title: S.NewHome.stockCTA.s, icon: "shippingbox.fill", action: onOpenStock)
            actionRow(title: S.NewHome.recipesCTA.s, icon: "sparkles", action: onOpenRecipes)
            actionRow(title: S.NewHome.mapCTA.s, icon: "map.fill", action: onOpenMap)
        }
    }

    private func actionRow(title: String, icon: String, action: (() -> Void)?) -> some View {
        Button {
            Haptics.light()
            action?()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SaveatColors.brand)
                    .frame(width: 24)
                Text(title)
                    .font(SaveatTypography.headline(15))
                    .foregroundStyle(SaveatColors.textPrimary)
                Spacer(minLength: 0)
                if action == nil {
                    SaveatBadge(text: S.NewHome.notWiredYet.s, tone: .neutral)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SaveatColors.textSecondary.opacity(0.6))
                }
            }
            .padding(14)
            .background(SaveatColors.surface, in: .rect(cornerRadius: Theme.tileRadius))
        }
        .buttonStyle(SoftPressStyle())
        .disabled(action == nil)
    }

    // MARK: Quick modes — kept reachable, see the type's doc comment

    private var quickModes: some View {
        VStack(spacing: 10) {
            actionRow(title: S.Home.zeroEuroTitle.s, icon: "eurosign.circle.fill") {
                path.append(Route.zeroEuro)
            }
            actionRow(title: S.Home.endOfMonthTitle.s, icon: "banknote.fill") {
                if subscriptions.canUse(.endOfMonth) {
                    path.append(Route.endOfMonth)
                } else {
                    Haptics.warning()
                    showsPaywall = true
                }
            }
            actionRow(title: S.Shopping.navTitle.s, icon: "cart.fill") {
                path.append(Route.shopping)
            }
        }
    }
}

#Preview {
    NavigationStack {
        NewHomeView(path: .constant(NavigationPath()), onScan: {}, onOpenRecipes: {}, onOpenMap: {})
            .environment(AppStore())
    }
}
