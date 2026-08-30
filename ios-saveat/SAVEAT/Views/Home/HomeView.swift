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
                bigActions
                stockCard
                weekCard
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
            Text("Bonjour 👋")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.sageDeep)
            Text("Qu'est-ce qu'on mange\naujourd'hui ?")
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
                        Text("Trouver mon repas")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Avec ce que tu as déjà chez toi")
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
                    Text("\(store.totalProducts) produits connus • l'IA cuisine avec ton stock réel")
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

    // MARK: Large actions

    private var bigActions: some View {
        VStack(spacing: 10) {
            actionRow(
                emoji: "🛒",
                title: "Scanner mes courses",
                subtitle: "Enregistre rapidement tes achats",
                tint: Theme.sage
            ) { onScan() }

            actionRow(
                emoji: "💰",
                title: "Repas à 0 €",
                subtitle: "Cuisine uniquement avec ton stock",
                tint: Theme.sageDeep
            ) { path.append(Route.zeroEuro) }

            actionRow(
                emoji: "♻️",
                title: "À sauver",
                subtitle: rescueSubtitle,
                tint: Theme.clay,
                isAlert: !store.urgentItems.isEmpty
            ) { path.append(Route.rescue) }

            actionRow(
                emoji: "💶",
                title: "Fin de mois",
                subtitle: "Optimise ton budget alimentaire",
                tint: Theme.terracotta
            ) { path.append(Route.endOfMonth) }
        }
    }

    private var rescueSubtitle: String {
        let count = store.urgentItems.count
        if count == 0 {
            let soon = store.soonItems.count
            return soon == 0 ? "Rien d'urgent, tout va bien" : "\(soon) produits à consommer bientôt"
        }
        return "\(count) produit\(count > 1 ? "s" : "") à utiliser rapidement"
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
                        SectionLabel(text: "Mon stock")
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(store.totalProducts)")
                                .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(Theme.ink)
                            Text("produits")
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
                SectionLabel(text: "Cette semaine")
                Button {
                    path.append(Route.impact)
                } label: {
                    HStack(spacing: 3) {
                        Text("Détails")
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
                    stat(value: Format.euro(impact.moneySaved), label: "économisés", tint: Theme.terracotta)
                    stat(value: "\(impact.savedItems)", label: "produits sauvés", tint: Theme.sageDeep)
                    stat(value: "\(impact.mealsCooked)", label: "repas préparés", tint: Theme.ink)
                }
                Spacer(minLength: 0)
            }

            Text("Estimations calculées à partir des prix moyens des produits que tu sauves.")
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
            Text("Scanne tes courses. SAVEAT se souvient de ce que tu as.")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.sageDeep)
            Text("Mange ce que tu as. Achète seulement ce qu'il te manque. Jette le moins possible.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.sageMist, in: .rect(cornerRadius: Theme.tileRadius))
    }
}
