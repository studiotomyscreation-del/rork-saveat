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
        .navigationTitle(S.Challenges.navTitle.s)
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
                Text(S.Challenges.cardTitle.s)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 0)
                if streak > 0 {
                    HStack(spacing: 4) {
                        Text("🔥").font(.system(size: 12))
                        Text(S.Challenges.streakDays.f(streak))
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
                Text(saved > 1 ? S.Challenges.savedThisWeekPlural.s : S.Challenges.savedThisWeek.s)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
                Spacer(minLength: 0)
            }

            SoftProgressBar(fraction: min(Double(saved) / Double(max(goal, 1)), 1))

            Text(remaining > 0
                 ? (remaining > 1
                    ? S.Challenges.remainingPlural.f(remaining)
                    : S.Challenges.remaining.f(remaining))
                 : S.Challenges.goalReached.s)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.sageDeep)
                .fixedSize(horizontal: false, vertical: true)

            if streak > 0 {
                Text(streak > 1
                    ? S.Challenges.streakLinePlural.f(streak)
                    : S.Challenges.streakLine.f(streak))
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
            }

            Divider()

            HStack(spacing: 18) {
                monthStat(value: "\(store.savedThisMonth)", label: S.Challenges.thisMonth.s)
                monthStat(value: "\(store.savedAllTime)", label: S.Challenges.allTime.s)
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
                    Text(S.Challenges.sevenDays.s)
                        .font(Theme.title(18))
                        .foregroundStyle(Theme.ink)
                    Text(S.Challenges.missionsDone.f(completed, store.challenges.count))
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
                            Text(SeedCopy.display(challenge.title))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(SeedCopy.display(challenge.detail))
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
        let text = S.Challenges.shareText.f(Format.euro(impact.moneySaved), impact.savedItems)

        return VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: S.Challenges.achievementCard.s)

            VStack(spacing: 10) {
                Text("🌱").font(.system(size: 34))
                Text(S.Challenges.cardText.f(Format.euro(impact.moneySaved), impact.savedItems))
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
                    Text(S.Challenges.share.s)
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
