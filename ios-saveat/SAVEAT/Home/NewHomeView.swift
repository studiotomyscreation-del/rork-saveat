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
                chefCard
                savingsCard
                rescueCard
                nearbyCard
                actions
                quickModes
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .saveatSoftBackdrop()
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

    // MARK: Chef SAVEAT — "what do we eat" hub (single meal or a whole week)

    /// Replaces the old single-recipe "Recette du jour" card — same slot,
    /// but leads with the Chef itself rather than one suggestion, and is the
    /// entry point into `WeeklyPlanGenerator` (Phase 3-4 of the Chef/semaine
    /// roadmap). "Trouver un repas" reuses the existing Repas tab
    /// (`onOpenRecipes`); "Préparer ma semaine" pushes the real `Route.weeklyPlan`
    /// screen — nothing here is a demo, every number shown is real.
    private static let chefCardPhoto = "french_toast_berries"

    private var chefCard: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { geo in
                Image(Self.chefCardPhoto)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }

            LinearGradient(
                colors: [.black.opacity(0.05), .black.opacity(0.35), .black.opacity(0.78)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 10) {
                Text(S.NewHome.chefCardEyebrow.s)
                    .font(SaveatTypography.eyebrow(11))
                    .tracking(1.2)
                    .foregroundStyle(SaveatColors.brandLight)
                Text(S.NewHome.chefCardTitle.s)
                    .font(SaveatTypography.hero(21))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(S.NewHome.chefCardSubtitle.s)
                    .font(SaveatTypography.caption(12.5))
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Button {
                        Haptics.light()
                        onOpenRecipes()
                    } label: {
                        Text(S.NewHome.chefFindMealCTA.s)
                            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(SaveatColors.forestDeep)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.white, in: .capsule)
                    }
                    Button {
                        Haptics.light()
                        path.append(Route.weeklyPlan)
                    } label: {
                        Text(S.NewHome.chefPrepareWeekCTA.s)
                            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.white.opacity(0.16), in: .capsule)
                            .overlay {
                                Capsule().stroke(.white.opacity(0.5), lineWidth: 1)
                            }
                    }
                }
                .padding(.top, 4)
            }
            .padding(18)
        }
        .frame(height: 300)
        .clipShape(.rect(cornerRadius: 24))
        .overlay(alignment: .topTrailing) {
            if store.totalProducts > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 11))
                    Text(S.NewHome.chefStockBadge.f(store.totalProducts))
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(SaveatColors.forestDeep)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.white.opacity(0.92), in: .capsule)
                .padding(12)
            }
        }
        .shadow(color: SaveatColors.nightBlue.opacity(0.12), radius: 16, y: 8)
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
