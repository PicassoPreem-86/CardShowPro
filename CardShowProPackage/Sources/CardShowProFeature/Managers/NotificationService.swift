import Foundation
import UserNotifications
import SwiftData

// MARK: - Notification Category

/// The types of notifications the app can send
enum NotificationCategory: String, CaseIterable, Codable, Sendable {
    case staleListings = "STALE_LISTINGS"
    case contactFollowUp = "CONTACT_FOLLOW_UP"
    case eventReminder = "EVENT_REMINDER"
    case slowInventory = "SLOW_INVENTORY"
    case goalAchievement = "GOAL_ACHIEVEMENT"

    var title: String {
        switch self {
        case .staleListings: "Stale Listing Alerts"
        case .contactFollowUp: "Follow-Up Reminders"
        case .eventReminder: "Event Reminders"
        case .slowInventory: "Slow Inventory Warnings"
        case .goalAchievement: "Goal Achievements"
        }
    }

    var description: String {
        switch self {
        case .staleListings: "Cards listed too long without selling"
        case .contactFollowUp: "Scheduled contact follow-ups"
        case .eventReminder: "Day before and morning of events"
        case .slowInventory: "Cards sitting in stock too long"
        case .goalAchievement: "When you hit revenue targets"
        }
    }

    var icon: String {
        switch self {
        case .staleListings: "tag.slash.fill"
        case .contactFollowUp: "person.crop.circle.badge.clock"
        case .eventReminder: "calendar.badge.exclamationmark"
        case .slowInventory: "clock.arrow.circlepath"
        case .goalAchievement: "trophy.fill"
        }
    }
}

// MARK: - Notification Settings

/// User preferences for notification behavior, persisted via UserDefaults
struct NotificationSettings: Codable, Sendable {
    var enabledCategories: Set<String> = Set(NotificationCategory.allCases.map(\.rawValue))
    var staleListingDays: Int = 14
    var slowInventoryDays: Int = 90
    var maxDailyNotifications: Int = 3

    /// Whether a given category is enabled
    func isEnabled(_ category: NotificationCategory) -> Bool {
        enabledCategories.contains(category.rawValue)
    }

    /// Toggle a category on or off
    mutating func toggle(_ category: NotificationCategory) {
        if enabledCategories.contains(category.rawValue) {
            enabledCategories.remove(category.rawValue)
        } else {
            enabledCategories.insert(category.rawValue)
        }
    }
}

// MARK: - Notification Service

/// Manages all local notifications for CardShowPro.
///
/// Responsibilities:
/// - Request notification permission
/// - Schedule and cancel local notifications
/// - Check inventory/contacts/events on app launch
/// - Enforce daily notification limit (max 3/day)
@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private let settingsKey = "com.cardshowpro.notificationSettings"
    private let dailyCountKey = "com.cardshowpro.dailyNotificationCount"
    private let dailyCountDateKey = "com.cardshowpro.dailyNotificationDate"

    private(set) var settings: NotificationSettings {
        didSet { persistSettings() }
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = NotificationSettings()
        }
    }

    // MARK: - Permission

    /// Request notification permission. Called lazily on first relevant action.
    func requestPermissionIfNeeded() async -> Bool {
        let currentSettings = await center.notificationSettings()
        switch currentSettings.authorizationStatus {
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    /// Whether notifications are authorized at the system level
    func isAuthorized() async -> Bool {
        let currentSettings = await center.notificationSettings()
        return currentSettings.authorizationStatus == .authorized
            || currentSettings.authorizationStatus == .provisional
    }

    // MARK: - Settings Management

    func updateSettings(_ newSettings: NotificationSettings) {
        settings = newSettings
    }

    func toggleCategory(_ category: NotificationCategory) {
        settings.toggle(category)
    }

    func setStaleListingDays(_ days: Int) {
        settings.staleListingDays = days
    }

    func setSlowInventoryDays(_ days: Int) {
        settings.slowInventoryDays = days
    }

    private func persistSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    // MARK: - Daily Limit

    /// Returns how many notifications have been sent today
    private func dailyCount() -> Int {
        let storedDate = UserDefaults.standard.string(forKey: dailyCountDateKey) ?? ""
        let today = todayString()
        if storedDate != today {
            // Reset for new day
            UserDefaults.standard.set(0, forKey: dailyCountKey)
            UserDefaults.standard.set(today, forKey: dailyCountDateKey)
            return 0
        }
        return UserDefaults.standard.integer(forKey: dailyCountKey)
    }

    private func incrementDailyCount() {
        let today = todayString()
        UserDefaults.standard.set(today, forKey: dailyCountDateKey)
        let current = UserDefaults.standard.integer(forKey: dailyCountKey)
        UserDefaults.standard.set(current + 1, forKey: dailyCountKey)
    }

    private func canSendNotification() -> Bool {
        dailyCount() < settings.maxDailyNotifications
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // MARK: - Schedule Notification

    /// Schedule a local notification with daily limit enforcement
    private func scheduleNotification(
        id: String,
        title: String,
        body: String,
        category: NotificationCategory,
        trigger: UNNotificationTrigger? = nil,
        bypassDailyLimit: Bool = false
    ) async {
        guard settings.isEnabled(category) else { return }

        if !bypassDailyLimit && !canSendNotification() { return }

        let authorized = await requestPermissionIfNeeded()
        guard authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category.rawValue

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            if !bypassDailyLimit {
                incrementDailyCount()
            }
        } catch {
            #if DEBUG
            print("Failed to schedule notification: \(error)")
            #endif
        }
    }

    /// Cancel a specific pending notification
    func cancelNotification(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// Cancel all notifications for a category
    func cancelCategory(_ category: NotificationCategory) {
        center.getPendingNotificationRequests { [weak center] requests in
            let ids = requests
                .filter { $0.content.categoryIdentifier == category.rawValue }
                .map(\.identifier)
            center?.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    /// Cancel all app notifications
    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - App Launch Checks

    /// Run all notification checks on app launch or foreground.
    /// Call this from ContentView.task or ScenePhase.active.
    func performLaunchChecks(modelContext: ModelContext) async {
        await checkStaleListings(modelContext: modelContext)
        await checkSlowInventory(modelContext: modelContext)
        await scheduleContactFollowUps(modelContext: modelContext)
        await scheduleEventReminders(modelContext: modelContext)
    }

    // MARK: - 1. Stale Listing Alerts

    /// Check for cards listed longer than the configured threshold
    func checkStaleListings(modelContext: ModelContext) async {
        guard settings.isEnabled(.staleListings) else { return }

        let threshold = settings.staleListingDays
        let descriptor = FetchDescriptor<InventoryCard>()

        guard let cards = try? modelContext.fetch(descriptor) else { return }

        let staleCards = cards.filter { card in
            card.cardStatus == .listed &&
            card.listedDate != nil &&
            Calendar.current.dateComponents(
                [.day],
                from: card.listedDate ?? Date(),
                to: Date()
            ).day ?? 0 >= threshold
        }

        guard !staleCards.isEmpty else { return }

        let count = staleCards.count
        let body = "\(count) card\(count == 1 ? " has" : "s have") been listed for \(threshold)+ days. Consider repricing."

        await scheduleNotification(
            id: "stale_listings_\(todayString())",
            title: "Stale Listings",
            body: body,
            category: .staleListings
        )
    }

    // MARK: - 2. Contact Follow-Up Reminders

    /// Schedule notifications for contacts with upcoming followUpDates
    func scheduleContactFollowUps(modelContext: ModelContext) async {
        guard settings.isEnabled(.contactFollowUp) else { return }

        // Cancel existing follow-up notifications to reschedule
        cancelCategory(.contactFollowUp)

        let descriptor = FetchDescriptor<Contact>()
        guard let contacts = try? modelContext.fetch(descriptor) else { return }

        let now = Date()
        let contactsWithFollowUp = contacts.filter { contact in
            guard let followUpDate = contact.followUpDate else { return false }
            // Only schedule for today or future dates within 7 days
            return followUpDate >= now && followUpDate <= Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        }

        for contact in contactsWithFollowUp {
            guard let followUpDate = contact.followUpDate else { continue }

            let note = contact.followUpNote ?? "your conversation"
            let body = "Reminder: Follow up with \(contact.name) about \(note)"

            // Schedule at 9 AM on the follow-up date
            var components = Calendar.current.dateComponents([.year, .month, .day], from: followUpDate)
            components.hour = 9
            components.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            await scheduleNotification(
                id: "follow_up_\(contact.id.uuidString)",
                title: "Contact Follow-Up",
                body: body,
                category: .contactFollowUp,
                trigger: trigger,
                bypassDailyLimit: true // Scheduled notifications bypass daily limit
            )
        }
    }

    // MARK: - 3. Event Reminders

    /// Schedule day-before and morning-of notifications for upcoming events
    func scheduleEventReminders(modelContext: ModelContext) async {
        guard settings.isEnabled(.eventReminder) else { return }

        // Cancel existing event notifications to reschedule
        cancelCategory(.eventReminder)

        let descriptor = FetchDescriptor<Event>()
        guard let events = try? modelContext.fetch(descriptor) else { return }

        let now = Date()
        let upcomingEvents = events.filter { event in
            !event.isCompleted && event.date >= now
        }

        for event in upcomingEvents {
            // Day before notification (6 PM the evening before)
            let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: event.date)
            if let dayBefore, dayBefore > now {
                var components = Calendar.current.dateComponents([.year, .month, .day], from: dayBefore)
                components.hour = 18
                components.minute = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

                await scheduleNotification(
                    id: "event_day_before_\(event.id.uuidString)",
                    title: "Event Tomorrow",
                    body: "Card show at \(event.venue) tomorrow!",
                    category: .eventReminder,
                    trigger: trigger,
                    bypassDailyLimit: true
                )
            }

            // Morning of notification (2 hours before event, or 8 AM if no specific time)
            var morningComponents = Calendar.current.dateComponents([.year, .month, .day], from: event.date)
            morningComponents.hour = 8
            morningComponents.minute = 0

            let morningTrigger = UNCalendarNotificationTrigger(dateMatching: morningComponents, repeats: false)

            let morningDate = Calendar.current.date(from: morningComponents) ?? event.date
            if morningDate > now {
                await scheduleNotification(
                    id: "event_morning_\(event.id.uuidString)",
                    title: "Event Today",
                    body: "Card show at \(event.venue) today! Get ready.",
                    category: .eventReminder,
                    trigger: morningTrigger,
                    bypassDailyLimit: true
                )
            }
        }
    }

    // MARK: - 4. Slow Inventory Warning

    /// Weekly check for cards sitting in stock too long
    func checkSlowInventory(modelContext: ModelContext) async {
        guard settings.isEnabled(.slowInventory) else { return }

        // Only run once per week
        let lastCheckKey = "com.cardshowpro.lastSlowInventoryCheck"
        if let lastCheck = UserDefaults.standard.object(forKey: lastCheckKey) as? Date {
            let daysSince = Calendar.current.dateComponents([.day], from: lastCheck, to: Date()).day ?? 0
            if daysSince < 7 { return }
        }

        let threshold = settings.slowInventoryDays
        let descriptor = FetchDescriptor<InventoryCard>()

        guard let cards = try? modelContext.fetch(descriptor) else { return }

        let slowCards = cards.filter { card in
            card.cardStatus == .inStock && card.daysInInventory >= threshold
        }

        guard !slowCards.isEmpty else { return }

        UserDefaults.standard.set(Date(), forKey: lastCheckKey)

        let count = slowCards.count
        let body = "\(count) card\(count == 1 ? " has" : "s have") been in stock \(threshold)+ days. Review slow-moving inventory."

        await scheduleNotification(
            id: "slow_inventory_\(todayString())",
            title: "Slow Inventory",
            body: body,
            category: .slowInventory
        )
    }

    // MARK: - 5. Goal Achievement

    /// Fire a notification when an event revenue target is hit.
    /// Call this after recording a sale during an active event.
    func checkGoalAchievement(
        eventName: String,
        currentRevenue: Double,
        revenueGoal: Double
    ) async {
        guard settings.isEnabled(.goalAchievement) else { return }
        guard currentRevenue >= revenueGoal else { return }

        let formattedGoal = String(format: "$%.0f", revenueGoal)

        await scheduleNotification(
            id: "goal_\(eventName.replacingOccurrences(of: " ", with: "_"))_\(formattedGoal)",
            title: "Goal Reached!",
            body: "You hit your \(formattedGoal) revenue goal at \(eventName)!",
            category: .goalAchievement
        )
    }
}
