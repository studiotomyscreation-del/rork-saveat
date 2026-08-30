import SwiftUI

/// Gamified weekly anti-waste challenges with a shareable achievement card.
struct ChallengesView: View {
    @Environment(AppStore.self) private var store

    private var completed: Int { store.challenges.filter(\.isDone).count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                zeroWasteCard
                headerCard
                challengeList
                badgeCard
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .saveatBackground()
        .navigationTitle("Défi Zéro Gaspi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    /// Challenge Zéro Gaspi — celebrates what was saved, never blames what was thrown.
    ///
    /// Counts products only: SAVEAT never invents a money figure it cannot prove.
    private var zeroWasteCard: some View {
        let saved = store.savedThisWeek
        let goal = store.weeklySaveGoal
        let streak = store.zeroWasteStreakDays
        let remaining = max(goal - saved, 0)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("Challenge Zéro Gaspi")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 0)
                if streak > 0 {
                    HStack(spacing: 4) {
                        Text("🔥").font(.system(size: 12))
                        Text("\(streak) j")
                            .font(.system(size: 12.5, weight: .bold, design: .rounded).monospacedDigit())
                    }
                    .foregroundStyle(Theme.terracotta)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.terracotta.opacity(0.15), in: .capsule)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(saved)")
                    .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.sageDeep)
                    .contentTransition(.numericText())
                Text("produit\(saved > 1 ? "s" : "") sauvé\(saved > 1 ? "s" : "") cette semaine")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
                Spacer(minLength: 0)
            }

            SoftProgressBar(fraction: min(Double(saved) / Double(max(goal, 1)), 1))

            Text(remaining > 0
                 ? "Encore \(remaining) produit\(remaining > 1 ? "s" : "") pour atteindre ton objectif."
                 : "Objectif de la semaine atteint. Beau travail 🌿")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.sageDeep)
                .fixedSize(horizontal: false, vertical: true)

            if streak > 0 {
                Text("🔥 \(streak) jour\(streak > 1 ? "s" : "") consécutif\(streak > 1 ? "s" : "") sans rien jeter.")
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
            }

            Divider()

            HStack(spacing: 18) {
                monthStat(value: "\(store.savedThisMonth)", label: "ce mois-ci")
                monthStat(value: "\(store.savedAllTime)", label: "depuis le début")
                Spacer(minLength: 0)
            }
        }
        .saveatCard()
    }

    private func monthStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.system(size: 19, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text("🏅").font(.system(size: 32))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Défi Zéro Gaspi — 7 jours")
                        .font(Theme.title(18))
                        .foregroundStyle(Theme.ink)
                    Text("\(completed)/\(store.challenges.count) missions accomplies")
                        .font(Theme.body(13))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer(minLength: 0)
            }

            SoftProgressBar(fraction: Double(completed) / Double(max(store.challenges.count, 1)))
        }
        .saveatCard()
    }

    private var challengeList: some View {
        VStack(spacing: 12) {
            ForEach(store.challenges) { challenge in
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        FoodBadge(emoji: challenge.emoji,
                                  tint: challenge.isDone ? Theme.sage.opacity(0.25) : Theme.sageMist,
                                  size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(challenge.title)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(challenge.detail)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer(minLength: 0)
                        if challenge.isDone {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Theme.sage)
                        } else {
                            Text("\(challenge.progress)/\(challenge.target)")
                                .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(Theme.sageDeep)
                        }
                    }

                    SoftProgressBar(
                        fraction: challenge.fraction,
                        tint: challenge.isDone ? Theme.sage : Theme.terracotta,
                        height: 7
                    )
                }
                .saveatCard(padding: 16)
            }
        }
    }

    private var badgeCard: some View {
        let impact = store.weeklyImpact
        let text = "Cette semaine j'ai économisé \(Format.euro(impact.moneySaved)) et sauvé \(impact.savedItems) produits avec SAVEAT."

        return VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: "Ta carte de réussite")

            VStack(spacing: 10) {
                Text("🌱").font(.system(size: 34))
                Text("Cette semaine j'ai économisé \(Format.euro(impact.moneySaved)) et sauvé \(impact.savedItems) produits.")
                    .font(Theme.display(18))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text("SAVEAT")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity)
            .padding(22)
            .background(
                LinearGradient(colors: [Theme.sage, Theme.sageDeep], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: .rect(cornerRadius: 20)
            )

            ShareLink(item: text) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Partager")
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.sageDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.sageMist, in: .rect(cornerRadius: Theme.pillRadius))
            }
        }
        .saveatCard()
    }
}
