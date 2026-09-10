import SwiftUI

/// Motivating impact dashboard — every figure clearly labelled as an estimate.
struct ImpactView: View {
    @Environment(AppStore.self) private var store

    private var week: ImpactSummary { store.weeklyImpact }
    private var lifetime: ImpactSummary { store.lifetimeImpact }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                weekCard
                lifetimeCard
                shareCard
                historySection
                disclaimer
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .saveatBackground()
        .navigationTitle(S.Impact.navTitle.s)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(text: S.Impact.thisWeek.s)

            HStack(spacing: 18) {
                ProgressRing(fraction: week.goalFraction, size: 118)
                VStack(alignment: .leading, spacing: 12) {
                    metric("🌱", "\(week.savedItems)", S.Impact.savedItems.s, Theme.ink)
                    metric("🍲", "\(week.mealsCooked)", S.Impact.mealsCooked.s, Theme.ink)
                    metric("🐷", Format.euro(week.moneySaved), S.Impact.moneySaved.s, Theme.terracotta)
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "leaf.fill").font(.system(size: 11))
                Text(S.Impact.wasteAvoided.f(Format.kg(week.wasteAvoidedKg)))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundStyle(Theme.sageDeep)
        }
        .saveatCard()
    }

    private func metric(_ emoji: String, _ value: String, _ label: String, _ tint: Color) -> some View {
        HStack(spacing: 10) {
            Text(emoji).font(.system(size: 18))
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(Theme.numeric(19))
                    .foregroundStyle(tint)
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    private var lifetimeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(S.Impact.sinceJoining.s)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.85))

            Text(Format.euro(lifetime.moneySaved))
                .font(.system(size: 42, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)

            Text(S.Impact.lifetimeNote.s)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                SoftPill(text: S.Impact.itemsPill.f(lifetime.savedItems), tint: Theme.sageDeep, background: .white.opacity(0.95))
                SoftPill(text: S.Impact.mealsPill.f(lifetime.mealsCooked), tint: Theme.sageDeep, background: .white.opacity(0.95))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(colors: [Theme.sage, Theme.sageDeep], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: .rect(cornerRadius: Theme.cardRadius)
        )
        .shadow(color: Theme.sageDeep.opacity(0.22), radius: 16, y: 6)
    }

    private var shareCard: some View {
        let text = S.Challenges.shareText.f(Format.euro(week.moneySaved), week.savedItems)
        return VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: S.Impact.shareCard.s)

            VStack(alignment: .leading, spacing: 10) {
                Text("SAVEAT")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(Theme.sageDeep)
                Text(S.Challenges.cardText.f(Format.euro(week.moneySaved), week.savedItems))
                    .font(Theme.display(19))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(S.Impact.shareTagline.s)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Theme.sageMist, in: .rect(cornerRadius: 20))

            ShareLink(item: text) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text(S.Impact.shareAction.s)
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Theme.sage, in: .rect(cornerRadius: Theme.pillRadius))
            }
        }
        .saveatCard()
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: S.Impact.historySection.s)
            VStack(spacing: 0) {
                let recent = Array(store.lifetimeImpact.mealsCooked > 0 ? recentMeals : [])
                ForEach(recent) { meal in
                    HStack(spacing: 12) {
                        FoodBadge(emoji: meal.wasZeroEuro ? "🥘" : "🍽️",
                                  tint: meal.wasZeroEuro ? Theme.sageMist : Theme.terracotta.opacity(0.14),
                                  size: 38)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(SeedCopy.display(meal.recipeName))
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                                .lineLimit(1)
                            Text(relativeDate(meal.date))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer(minLength: 0)
                        Text("+\(Format.euro(meal.moneySaved))")
                            .font(.system(size: 14, weight: .semibold, design: .rounded).monospacedDigit())
                            .foregroundStyle(Theme.sageDeep)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    if meal.id != recent.last?.id { Divider().padding(.leading, 66) }
                }
            }
            .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
            .shadow(color: Theme.ink.opacity(0.04), radius: 10, y: 3)
        }
    }

    private var recentMeals: [CookedMeal] {
        Array(store.lifetimeMeals.sorted { $0.date > $1.date }.prefix(6))
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = LanguageRuntime.current.locale
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: .now)
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle").font(.system(size: 12))
            Text(S.Impact.disclaimer.s)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(Theme.inkSoft)
        .padding(14)
        .background(Theme.creamDeep, in: .rect(cornerRadius: 16))
    }
}
