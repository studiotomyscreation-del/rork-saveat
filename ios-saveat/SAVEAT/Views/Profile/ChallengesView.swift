import SwiftUI

/// Gamified weekly anti-waste challenges with a shareable achievement card.
struct ChallengesView: View {
    @Environment(AppStore.self) private var store

    private var completed: Int { store.challenges.filter(\.isDone).count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
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
