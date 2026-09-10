import Foundation
import UserNotifications

/// Plans the anti-waste reminders from the household stock.
///
/// Design rules, in order of importance:
/// - never more than one notification per day, whatever the number of products;
/// - the wording follows the most urgent product of that day;
/// - nothing is scheduled when the user turned reminders off or refused the
///   iOS permission — the app keeps working exactly the same either way.
@Observable
final class NotificationService {
    static let shared = NotificationService()

    /// Where the user stands regarding the iOS permission.
    nonisolated enum Authorization: Sendable {
        case unknown
        case granted
        case denied
    }

    private(set) var authorization: Authorization = .unknown
    /// Bumped when the user taps a reminder, so the shell can open "À sauver".
    private(set) var rescueRequest: UUID?

    private var refreshTask: Task<Void, Never>?

    /// Prefix identifying every reminder SAVEAT schedules, so we only ever
    /// cancel our own notifications.
    private static let prefix = "saveat.expiry."
    static let categoryIdentifier = "SAVEAT_EXPIRY"
    static let openRescueAction = "SAVEAT_OPEN_RESCUE"
    /// iOS keeps at most 64 pending notifications; stay well below.
    private static let maxScheduled = 48

    private init() {}

    // MARK: - Set-up

    /// Registers the notification category and its "see what to use" action.
    func configure() {
        let action = UNNotificationAction(
            identifier: Self.openRescueAction,
            title: S.Reminders.action.s,
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [action],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    /// Reads the current permission without ever prompting the user.
    func refreshAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorization = Self.authorization(from: settings.authorizationStatus)
    }

    /// Asks for the permission, only when the user opted into reminders.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            authorization = granted ? .granted : .denied
            return granted
        } catch {
            // A refused or failed permission is never an error for the user.
            authorization = .denied
            return false
        }
    }

    /// Asks for the permission at a natural moment — right after a shopping run,
    /// when the user has just entered real dates — and only if never answered.
    func requestAuthorizationIfUndetermined(settings: ReminderSettings) async {
        guard settings.isEnabled, settings.hasAnyOffset else { return }
        await refreshAuthorization()
        guard authorization == .unknown else { return }
        await requestAuthorization()
    }

    private nonisolated static func authorization(
        from status: UNAuthorizationStatus
    ) -> Authorization {
        switch status {
        case .authorized, .provisional, .ephemeral: .granted
        case .denied: .denied
        case .notDetermined: .unknown
        @unknown default: .unknown
        }
    }

    // MARK: - Deep link

    /// Called when a reminder is opened.
    func requestRescueScreen() {
        rescueRequest = UUID()
    }

    /// Called by the shell once it has navigated.
    func clearRescueRequest() {
        rescueRequest = nil
    }

    // MARK: - Scheduling

    /// Re-plans every reminder. Safe to call on each stock change: the work is
    /// debounced so a burst of edits only triggers one rebuild.
    func refresh(inventory: [FoodItem], settings: ReminderSettings) {
        let plan = Self.plan(inventory: inventory, settings: settings)
        refreshTask?.cancel()
        refreshTask = Task { [plan] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await Self.apply(plan)
        }
    }

    /// Cancels every SAVEAT reminder and schedules the given plan.
    private nonisolated static func apply(_ plan: [ReminderPlan]) async {
        let center = UNUserNotificationCenter.current()

        let pending = await center.pendingNotificationRequests()
        let ours = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        if !ours.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: ours)
        }

        guard !plan.isEmpty else { return }

        let status = await center.notificationSettings().authorizationStatus
        guard authorization(from: status) == .granted else { return }

        for entry in plan.prefix(maxScheduled) {
            let content = UNMutableNotificationContent()
            content.title = entry.title
            content.body = entry.body
            content.sound = .default
            content.categoryIdentifier = categoryIdentifier
            content.userInfo = ["destination": "rescue"]

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: entry.components,
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: entry.identifier,
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    // MARK: - Plan building

    /// One notification, already worded.
    nonisolated struct ReminderPlan: Sendable {
        var identifier: String
        var title: String
        var body: String
        var components: DateComponents
    }

    /// Builds at most one reminder per day from the stock.
    ///
    /// Products landing on the same day are merged into a single grouped message
    /// rather than sent one after the other.
    nonisolated static func plan(
        inventory: [FoodItem],
        settings: ReminderSettings
    ) -> [ReminderPlan] {
        guard settings.isEnabled, settings.hasAnyOffset else { return [] }

        let calendar = Calendar.current
        let now = Date.now
        let today = calendar.startOfDay(for: now)

        /// Products to remind about on a given day, with the offset that triggered it.
        var buckets: [Date: (offset: Int, names: [String])] = [:]

        for item in inventory where item.quantity > 0 {
            guard let bestBefore = item.bestBefore else { continue }
            // A date already reached is handled in the app, not by a reminder.
            guard calendar.startOfDay(for: bestBefore) >= today else { continue }

            for offset in settings.offsets {
                guard let day = calendar.date(
                    byAdding: .day,
                    value: -offset,
                    to: calendar.startOfDay(for: bestBefore)
                ) else { continue }

                guard let fireDate = calendar.date(
                    bySettingHour: settings.hour, minute: 0, second: 0, of: day
                ), fireDate > now else { continue }

                let key = calendar.startOfDay(for: day)
                var bucket = buckets[key] ?? (offset: offset, names: [])
                // The most urgent product of the day drives the wording.
                bucket.offset = min(bucket.offset, offset)
                // Stored under the display name so the notification reads in
                // the same language as the rest of the app.
                if !bucket.names.contains(item.displayName) {
                    bucket.names.append(item.displayName)
                }
                buckets[key] = bucket
            }
        }

        return buckets
            .sorted { $0.key < $1.key }
            .compactMap { day, bucket -> ReminderPlan? in
                guard var components = calendar.dateComponents(
                    [.year, .month, .day], from: day
                ) as DateComponents? else { return nil }
                components.hour = settings.hour
                components.minute = 0

                let copy = wording(offset: bucket.offset, names: bucket.names)
                return ReminderPlan(
                    identifier: "\(prefix)\(Int(day.timeIntervalSince1970))",
                    title: copy.title,
                    body: copy.body,
                    components: components
                )
            }
    }

    /// Wording for one reminder, singular or grouped, in the reader's language.
    ///
    /// Never states that a food is or isn't safe to eat: the copy sends the user
    /// back to the package, exactly as the in-app notices do.
    nonisolated static func wording(
        offset: Int,
        names: [String]
    ) -> (title: String, body: String) {
        let count = names.count
        let list = enumerate(names)

        if count == 1, let name = names.first {
            switch offset {
            case 0:
                return (
                    S.Reminders.checkTitleOne.s,
                    S.Reminders.bodyTodayOne.f(name)
                )
            case 1:
                return (
                    S.Reminders.rescueTitleOne.s,
                    S.Reminders.bodyTomorrowOne.f(name)
                )
            case 2:
                return (
                    S.Reminders.rescueTitleOne.s,
                    S.Reminders.bodySoonOne.f(name)
                )
            default:
                return (
                    S.Reminders.planTitleOne.s,
                    S.Reminders.bodyPlanOne.f(name)
                )
            }
        }

        switch offset {
        case 0:
            return (
                S.Reminders.checkTitleMany.f(count),
                S.Reminders.bodyTodayMany.f(list)
            )
        case 1:
            return (
                S.Reminders.rescueTitleTomorrow.f(count),
                S.Reminders.bodyTomorrowMany.f(list)
            )
        case 2:
            return (
                S.Reminders.rescueTitleMany.f(count),
                S.Reminders.bodySoonMany.f(list)
            )
        default:
            return (
                S.Reminders.planTitleMany.f(count),
                S.Reminders.bodyPlanMany.f(list)
            )
        }
    }

    /// "a, b and c", capped so the message stays readable.
    nonisolated static func enumerate(_ names: [String]) -> String {
        let shown = Array(names.prefix(3))
        let rest = names.count - shown.count

        var text: String
        switch shown.count {
        case 0: text = ""
        case 1: text = shown[0]
        default:
            text = shown.dropLast().joined(separator: ", ")
                + S.Reminders.listJoiner.s
                + (shown.last ?? "")
        }

        if rest > 0 {
            text += rest > 1
                ? S.Reminders.listMorePlural.f(rest)
                : S.Reminders.listMore.f(rest)
        }
        return text
    }
}

/// Routes reminder taps back into the app.
final class SaveatNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = SaveatNotificationDelegate()

    /// Reminders stay visible while the app is open — they are rare by design.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let destination = response.notification.request.content.userInfo["destination"] as? String
        guard destination == "rescue" else { return }
        await MainActor.run {
            NotificationService.shared.requestRescueScreen()
        }
    }
}
