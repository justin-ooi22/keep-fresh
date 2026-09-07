import Foundation
import UserNotifications

/// Manages scheduling, updating, and canceling local expiration alert notifications.
public final class NotificationManager: ObservableObject {
    public static let shared = NotificationManager()
    
    @Published public var isAuthorized: Bool = false
    @Published public var preferredAlertHour: Int = 9
    @Published public var preferredAlertMinute: Int = 0
    
    private let center = UNUserNotificationCenter.current()
    
    public init() {
        checkAuthorization()
    }
    
    /// Requests user notification permissions
    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            await MainActor.run {
                self.isAuthorized = false
            }
            return false
        }
    }
    
    /// Checks current permission status
    public func checkAuthorization() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
            }
        }
    }
    
    /// Schedules multiple alarms for a single grocery item based on its reminderOptions
    public func scheduleNotifications(for item: GroceryItem, zoneName: String) {
        // First cancel any existing notifications for this item to avoid duplicates
        cancelNotifications(for: item.id)
        
        // Don't schedule if already consumed
        guard !item.isConsumed else { return }
        
        for option in item.reminderOptions {
            guard let triggerDate = option.targetTriggerDate(
                for: item.expiryDate,
                alertHour: preferredAlertHour,
                alertMinute: preferredAlertMinute
            ), triggerDate > Date() else {
                continue // Skip past dates
            }
            
            let content = UNMutableNotificationContent()
            content.sound = .default
            
            switch option {
            case .oneWeek:
                content.title = "📅 Expiry in 1 Week"
                content.body = "\(item.name) in \(zoneName) expires in 7 days. Plan to use it soon!"
            case .threeDays:
                content.title = "⚠️ Expiry in 3 Days"
                content.body = "\(item.name) in \(zoneName) expires in 3 days. Check on it today!"
            case .twoDays:
                content.title = "⏳ Expiry in 2 Days"
                content.body = "\(item.name) in \(zoneName) expires in 2 days. Don't let it go to waste!"
            case .onTheDay:
                content.title = "🚨 Expires Today!"
                content.body = "\(item.name) in \(zoneName) expires today! Use it first."
            }
            
            content.userInfo = [
                "itemId": item.id.uuidString,
                "option": option.rawValue
            ]
            
            let calendar = Calendar.current
            let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            
            let identifier = "freshkeep-\(item.id.uuidString)-\(option.rawValue)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("Error scheduling notification for \(item.name): \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Cancels all scheduled alarms for a specific grocery item
    public func cancelNotifications(for itemId: UUID) {
        let identifiers = NotificationReminderOption.allCases.map {
            "freshkeep-\(itemId.uuidString)-\($0.rawValue)"
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    /// Schedules a test notification to fire in 5 seconds
    public func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🔔 FreshKeep Test Alert"
        content.body = "Notifications are working perfectly! You'll receive alerts before your groceries expire."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "freshkeep-test-notification", content: content, trigger: trigger)
        
        center.add(request)
    }
    
    /// Reschedules all notifications across all items
    public func rescheduleAll(items: [GroceryItem], zones: [StorageZone]) {
        let zoneMap = Dictionary(uniqueKeysWithValues: zones.map { ($0.id, $0.name) })
        for item in items where !item.isConsumed {
            let zoneName = zoneMap[item.zoneId] ?? "House"
            scheduleNotifications(for: item, zoneName: zoneName)
        }
    }
}
