import SwiftUI

/// Colours for the four priority levels, inside the existing SAVEAT palette.
nonisolated enum StatusTint {
    static func color(for status: ConsumptionStatus) -> Color {
        switch status {
        case .keep: Theme.sage
        case .plan: Theme.terracotta
        case .rescue: Theme.clay
        case .reached: Theme.alert
        }
    }
}

/// Small coloured pill naming the priority level, e.g. "🟠 À sauver".
struct StatusPill: View {
    let status: ConsumptionStatus
    var showsDot: Bool = true

    var body: some View {
        HStack(spacing: 5) {
            if showsDot {
                Circle()
                    .fill(StatusTint.color(for: status))
                    .frame(width: 7, height: 7)
            }
            Text(status.shortTitle)
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(StatusTint.color(for: status))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(StatusTint.color(for: status).opacity(0.14), in: .capsule)
        .accessibilityLabel(status.title)
    }
}

/// Cautious notice shown when a date is reached or passed.
///
/// Wording comes from `DateKind.passedNotice` and never guarantees that a food
/// is safe to eat.
struct SafetyNotice: View {
    let kind: DateKind

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: kind == .dlc ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(kind == .dlc ? Theme.alert : Theme.terracotta)

            Text(kind.passedNotice)
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            (kind == .dlc ? Theme.alert : Theme.terracotta).opacity(0.10),
            in: .rect(cornerRadius: 16)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke((kind == .dlc ? Theme.alert : Theme.terracotta).opacity(0.35), lineWidth: 1.1)
        }
    }
}

/// Picker for the kind of date printed on the pack.
struct DateKindPicker: View {
    @Binding var kind: DateKind

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ForEach(DateKind.allCases) { option in
                    Button {
                        kind = option
                        Haptics.light()
                    } label: {
                        Text(option.pickerTitle)
                            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(kind == option ? .white : Theme.ink)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .background(kind == option ? Theme.sage : Theme.creamDeep, in: .capsule)
                    }
                    .buttonStyle(SoftPressStyle())
                    .accessibilityLabel(option.title)
                }
            }

            Text(kind.helpText)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// One product inside the "À sauver" list: photo, name, date, days left, status.
struct RescueRow: View {
    let item: FoodItem

    var body: some View {
        HStack(spacing: 13) {
            ProductThumb(product: item.product, fallbackEmoji: item.emoji, size: 48, radius: 14)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.system(size: 15.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(item.deadlineText)
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(StatusTint.color(for: item.status))
                    if item.dateType != .unknown {
                        Text("• \(item.dateType.badge)")
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            }

            Spacer(minLength: 6)

            StatusPill(status: item.status)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(.rect)
    }
}

/// "✓ Sauvé" / "Jeté" pair, shown on products that are at risk.
///
/// Saving is celebrated, throwing away is recorded without any guilt-tripping.
struct SaveOrDiscardButtons: View {
    let onSaved: () -> Void
    let onDiscarded: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button {
                Haptics.success()
                onSaved()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "checkmark.circle.fill")
                    Text(S.Rescue.markSaved.s)
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
                .background(Theme.sage, in: .capsule)
            }
            .buttonStyle(SoftPressStyle())

            Button {
                Haptics.light()
                onDiscarded()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "trash")
                    Text(S.Rescue.markDiscarded.s)
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
                .background(Theme.creamDeep, in: .capsule)
            }
            .buttonStyle(SoftPressStyle())
        }
    }
}

/// "BIENTÔT — SAVEAT LOCAL" announcement.
///
/// Purely informative: no producer account, no map, no marketplace. It only
/// tells the user where SAVEAT is heading, with no release date.
struct SaveatLocalCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(S.Common.comingSoon.s)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(Theme.sageDeep)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Theme.surface.opacity(0.9), in: .capsule)

                Text("SAVEAT LOCAL 🌱")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)

                Spacer(minLength: 0)
            }

            Text(S.Local.body.s)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            Text(S.Local.goal.s)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            Text(S.Local.tagline.s)
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.sageDeep)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Theme.sageMist, in: .rect(cornerRadius: Theme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.sage.opacity(0.30), lineWidth: 1)
        }
    }
}

/// "Pourquoi scanner vos produits ?" — explains what the scan buys the user.
struct WhyScanCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(S.WhyScan.title.s)
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(Theme.sageDeep)

            Text(S.WhyScan.body.s)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            Text(S.WhyScan.tagline.s)
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.sageDeep)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.creamDeep, in: .rect(cornerRadius: Theme.tileRadius))
    }
}
