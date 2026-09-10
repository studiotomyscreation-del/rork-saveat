import SwiftUI

/// Rappels anti-gaspi — when SAVEAT is allowed to speak up.
///
/// Refusing the iOS permission never degrades the app: every other feature keeps
/// working exactly the same, only the reminders go quiet.
struct RemindersView: View {
    @Environment(AppStore.self) private var store

    @State private var authorization: NotificationService.Authorization = .unknown

    private var settings: ReminderSettings { store.profile.reminderSettings }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                intro
                masterCard
                if settings.isEnabled { offsetsCard }
                if settings.isEnabled, authorization == .denied { deniedCard }
                explanation
            }
            .padding(.horizontal, Theme.hMargin)
            .padding(.top, 6)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .saveatBackground()
        .navigationTitle(S.Reminders.navTitle.s)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await NotificationService.shared.refreshAuthorization()
            authorization = NotificationService.shared.authorization
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(S.Reminders.introTitle.s)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.ink)
            Text(S.Reminders.introBody.s)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.sageMist, in: .rect(cornerRadius: Theme.tileRadius))
    }

    private var masterCard: some View {
        VStack(spacing: 0) {
            Toggle(isOn: Binding(
                get: { settings.isEnabled },
                set: { newValue in
                    update { $0.isEnabled = newValue }
                    if newValue { requestPermission() }
                    Haptics.light()
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(S.Reminders.enable.s)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text(statusText)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .tint(Theme.sage)
            .padding(16)
            .frame(minHeight: 44)
        }
        .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
        .shadow(color: Theme.ink.opacity(0.04), radius: 10, y: 3)
    }

    private var statusText: String {
        guard settings.isEnabled else { return S.Reminders.statusOff.s }
        switch authorization {
        case .granted: return S.Reminders.statusGranted.s
        case .denied: return S.Reminders.statusDenied.s
        case .unknown: return S.Reminders.statusUnknown.s
        }
    }

    private var offsetsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: S.Reminders.whenSection.s)

            VStack(spacing: 0) {
                offsetRow(
                    title: S.Reminders.fiveDays.s,
                    detail: S.Reminders.planTag.s,
                    isOn: Binding(
                        get: { settings.fiveDays },
                        set: { value in update { $0.fiveDays = value } }
                    )
                )
                Divider().padding(.leading, 16)
                offsetRow(
                    title: S.Reminders.twoDays.s,
                    detail: S.Reminders.rescueTag.s,
                    isOn: Binding(
                        get: { settings.twoDays },
                        set: { value in update { $0.twoDays = value } }
                    )
                )
                Divider().padding(.leading, 16)
                offsetRow(
                    title: S.Reminders.oneDay.s,
                    detail: S.Reminders.rescueTag.s,
                    isOn: Binding(
                        get: { settings.oneDay },
                        set: { value in update { $0.oneDay = value } }
                    )
                )
                Divider().padding(.leading, 16)
                offsetRow(
                    title: S.Reminders.sameDay.s,
                    detail: S.Reminders.checkTag.s,
                    isOn: Binding(
                        get: { settings.sameDay },
                        set: { value in update { $0.sameDay = value } }
                    )
                )
            }
            .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
            .shadow(color: Theme.ink.opacity(0.04), radius: 10, y: 3)
        }
    }

    private func offsetRow(title: String, detail: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: Binding(
            get: { isOn.wrappedValue },
            set: { value in
                isOn.wrappedValue = value
                Haptics.light()
            }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .tint(Theme.sage)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 44)
    }

    private var deniedCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text(S.Reminders.deniedTitle.s)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Spacer(minLength: 0)
            }
            .foregroundStyle(Theme.terracotta)

            Text(S.Reminders.deniedBody.s)
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            if let url = URL(string: UIApplication.openSettingsURLString) {
                Link(destination: url) {
                    Text(S.Reminders.openSettings.s)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.sageDeep)
                        .frame(minHeight: 44)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.terracotta.opacity(0.12), in: .rect(cornerRadius: Theme.cardRadius))
    }

    private var explanation: some View {
        Text(S.Reminders.explanation.s)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(Theme.inkSoft)
            .fixedSize(horizontal: false, vertical: true)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.creamDeep, in: .rect(cornerRadius: 16))
    }

    private func update(_ change: (inout ReminderSettings) -> Void) {
        var updated = store.profile.reminderSettings
        change(&updated)
        store.profile.reminderSettings = updated
    }

    private func requestPermission() {
        Task {
            await NotificationService.shared.requestAuthorization()
            authorization = NotificationService.shared.authorization
            store.scheduleReminders()
        }
    }
}
