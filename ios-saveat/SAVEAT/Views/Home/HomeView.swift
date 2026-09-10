import SwiftUI

/// Home dashboard built around the SAVEAT loop:
/// scanner ses courses → connaître son stock → demander à l'IA quoi cuisiner.
struct HomeView: View {
    @Environment(AppStore.self) private var store
    @Binding var path: NavigationPath
    let onScan: () -> Void
    let onAskAI: (MealPrompt) -> Void

    private var impact: ImpactSummary { store.weeklyImpact }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                greeting
                aiHero
                rescueSection
                bigActions
                stockCard
                weekCard
                WhyScanCard()
                SaveatLocalCard()
                promise
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .saveatBackground()
    }

    // MARK: Greeting

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(S.Home.greeting.s)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.sageDeep)
            Text(S.Home.headline.s)
                .font(Theme.display(29))
                .foregroundStyle(Theme.ink)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    // MARK: AI hero

    private var aiHero: some View {
        Button {
            onAskAI(MealPrompt(text: nil, zeroEuroOnly: false))
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    BrandMark(size: 52)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(S.Home.heroTitle.s)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(S.Home.heroSubtitle.s)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                }

                HStack(spacing: 6) {
                    Image(systemName: "sparkles").font(.system(size: 11))
                    Text(S.Home.heroStock.f(store.totalProducts))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .foregroundStyle(.white.opacity(0.92))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.16), in: .capsule)
            }
            .padding(18)
            .background(
                LinearGradient(colors: [Theme.sage, Theme.sageDeep],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: .rect(cornerRadius: Theme.cardRadius)
            )
            .shadow(color: Theme.sageDeep.opacity(0.3), radius: 16, y: 6)
        }
        .buttonStyle(SoftPressStyle())
    }

    // MARK: À sauver

    /// The heart of the loop: what has to be eaten first, and a way to cook it.
    /// 🟠 comes first, then 🟡. Reached dates get their own cautious row.
    @ViewBuilder
    private var rescueSection: some View {
        let queue = store.rescueQueue
        let reached = store.reachedItems

        if !queue.isEmpty || !reached.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    SectionLabel(text: S.Home.rescueSection.s)
                    Spacer(minLength: 0)
                    if !queue.isEmpty {
                        Text("\(queue.count)")
                            .font(.system(size: 12.5, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(Theme.clay)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Theme.clay.opacity(0.14), in: .capsule)
                    }
                }

                if !queue.isEmpty {
                    Text(queue.count > 1
                        ? S.Home.rescueCountPlural.f(queue.count)
                        : S.Home.rescueCount.f(queue.count))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                }

                VStack(spacing: 0) {
                    ForEach(Array(queue.prefix(4).enumerated()), id: \.element.id) { index, item in
                        Button {
                            Haptics.light()
                            path.append(Route.food(item))
                        } label: {
                            RescueRow(item: item)
                        }
                        .buttonStyle(SoftPressStyle())

                        if index < min(queue.count, 4) - 1 { Divider().padding(.leading, 76) }
                    }

                    if !reached.isEmpty {
                        if !queue.isEmpty { Divider().padding(.leading, 76) }
                        Button {
                            Haptics.light()
                            path.append(Route.rescue)
                        } label: {
                            HStack(spacing: 10) {
                                Text("🔴").font(.system(size: 14))
                                Text(reached.count > 1
                                    ? S.Home.reachedCountPlural.f(reached.count)
                                    : S.Home.reachedCount.f(reached.count))
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Theme.ink)
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Theme.inkSoft.opacity(0.6))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                            .contentShape(.rect)
                        }
                        .buttonStyle(SoftPressStyle())
                    }
                }
                .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
                .shadow(color: Theme.ink.opacity(0.04), radius: 10, y: 3)

                if !queue.isEmpty {
                    Button {
                        Haptics.soft()
                        onAskAI(MealPrompt(
                            text: S.Home.rescuePrompt.s,
                            zeroEuroOnly: false
                        ))
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text(S.Home.rescueCTA.s)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                        .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Theme.clay, in: .capsule)
                    }
                    .buttonStyle(SoftPressStyle())
                }
            }
            .padding(16)
            .background(Theme.clay.opacity(0.07), in: .rect(cornerRadius: Theme.cardRadius))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.cardRadius)
                    .stroke(Theme.clay.opacity(0.28), lineWidth: 1.1)
            }
        }
    }

    // MARK: Large actions

    private var bigActions: some View {
        VStack(spacing: 10) {
            actionRow(
                emoji: "🛒",
                title: S.Home.scanTitle.s,
                subtitle: S.Home.scanSubtitle.s,
                tint: Theme.sage
            ) { onScan() }

            actionRow(
                emoji: "💰",
                title: S.Home.zeroEuroTitle.s,
                subtitle: S.Home.zeroEuroSubtitle.s,
                tint: Theme.sageDeep
            ) { path.append(Route.zeroEuro) }

            actionRow(
                emoji: "♻️",
                title: S.Home.rescueTitle.s,
                subtitle: rescueSubtitle,
                tint: Theme.clay,
                isAlert: !store.rescueItems.isEmpty
            ) { path.append(Route.rescue) }

            actionRow(
                emoji: "💶",
                title: S.Home.endOfMonthTitle.s,
                subtitle: S.Home.endOfMonthSubtitle.s,
                tint: Theme.terracotta
            ) { path.append(Route.endOfMonth) }
        }
    }

    private var rescueSubtitle: String {
        let count = store.rescueItems.count
        if count == 0 {
            let soon = store.planItems.count
            if soon == 0 { return S.Home.nothingUrgent.s }
            return soon > 1 ? S.Home.planSubtitlePlural.f(soon) : S.Home.planSubtitle.f(soon)
        }
        return count > 1 ? S.Home.rescueSubtitlePlural.f(count) : S.Home.rescueSubtitle.f(count)
    }

    private func actionRow(
        emoji: String,
        title: String,
        subtitle: String,
        tint: Color,
        isAlert: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            Haptics.light()
            action()
        } label: {
            HStack(spacing: 14) {
                Text(emoji)
                    .font(.system(size: 22))
                    .frame(width: 46, height: 46)
                    .background(tint.opacity(0.16), in: .rect(cornerRadius: 15))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(isAlert ? Theme.clay : Theme.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft.opacity(0.5))
            }
            .padding(14)
            .background(Theme.surface, in: .rect(cornerRadius: Theme.tileRadius))
            .overlay {
                if isAlert {
                    RoundedRectangle(cornerRadius: Theme.tileRadius)
                        .stroke(Theme.clay.opacity(0.35), lineWidth: 1.2)
                }
            }
            .shadow(color: Theme.ink.opacity(0.04), radius: 9, y: 3)
        }
        .buttonStyle(SoftPressStyle())
    }

    // MARK: Stock summary

    private var stockCard: some View {
        Button {
            Haptics.light()
            path.append(Route.shopping)
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        SectionLabel(text: S.Home.stockSection.s)
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(store.totalProducts)")
                                .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(Theme.ink)
                            Text(S.Common.products.s)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                    Spacer()
                    Text("≈ \(Format.euro(store.stockValue, decimals: 0))")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.sageDeep)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.sageMist, in: .capsule)
                }

                HStack(spacing: 10) {
                    ForEach(StorageLocation.allCases) { location in
                        VStack(spacing: 4) {
                            Text(location.emoji).font(.system(size: 18))
                            Text("\(store.count(in: location))")
                                .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(Theme.ink)
                            Text(location.title)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.inkSoft)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.creamDeep, in: .rect(cornerRadius: 16))
                    }
                }
            }
            .saveatCard()
        }
        .buttonStyle(SoftPressStyle())
    }

    // MARK: This week

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionLabel(text: S.Home.weekSection.s)
                Button {
                    path.append(Route.impact)
                } label: {
                    HStack(spacing: 3) {
                        Text(S.Home.details.s)
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
                    }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.sageDeep)
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .center, spacing: 18) {
                ProgressRing(fraction: impact.goalFraction, size: 118)

                VStack(alignment: .leading, spacing: 14) {
                    stat(value: Format.euro(impact.moneySaved), label: S.Home.savedMoney.s, tint: Theme.terracotta)
                    stat(value: "\(impact.savedItems)", label: S.Home.savedItemsLabel.s, tint: Theme.sageDeep)
                    stat(value: "\(impact.mealsCooked)", label: S.Home.mealsCookedLabel.s, tint: Theme.ink)
                }
                Spacer(minLength: 0)
            }

            Text(S.Home.estimateNote.s)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .saveatCard()
    }

    private func stat(value: String, label: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(tint)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    // MARK: Promise

    private var promise: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(S.Home.promiseTitle.s)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.sageDeep)
            Text(S.Home.promiseBody.s)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.sageMist, in: .rect(cornerRadius: Theme.tileRadius))
    }
}
