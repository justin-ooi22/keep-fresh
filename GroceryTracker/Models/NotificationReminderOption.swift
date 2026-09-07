import Foundation

/// Defines reminder intervals for grocery expiration alerts.
/// Users can select multiple options simultaneously for a single item.
public enum NotificationReminderOption: String, CaseIterable, Codable, Identifiable, Hashable {
    case oneWeek = "oneWeek"
    case threeDays = "threeDays"
    case twoDays = "twoDays"
    case onTheDay = "onTheDay"
    
    public var id: String { rawValue }
    
    /// User friendly label
    public var title: String {
        switch self {
        case .oneWeek:
            return "1 week before"
        case .threeDays:
            return "3 days before"
        case .twoDays:
            return "2 days before"
        case .onTheDay:
            return "On the day of expiry"
        }
    }
    
    /// Short chip label
    public var shortBadge: String {
        switch self {
        case .oneWeek: return "-7d"
        case .threeDays: return "-3d"
        case .twoDays: return "-2d"
        case .onTheDay: return "Day of"
        }
    }
    
    /// Days to offset from expiry date (negative values mean before expiry)
    public var dayOffset: Int {
        switch self {
        case .oneWeek: return -7
        case .threeDays: return -3
        case .twoDays: return -2
        case .onTheDay: return 0
        }
    }
    
    /// Calculates the specific trigger date and time based on expiry date and preferred alert hour/minute.
    public func targetTriggerDate(for expiryDate: Date, alertHour: Int = 9, alertMinute: Int = 0) -> Date? {
        let calendar = Calendar.current
        
        // Offset the date by specified days
        guard let offsetDate = calendar.date(byAdding: .day, value: dayOffset, to: expiryDate) else {
            return nil
        }
        
        // Set the specific time of day (e.g., 9:00 AM)
        var components = calendar.dateComponents([.year, .month, .day], from: offsetDate)
        components.hour = alertHour
        components.minute = alertMinute
        components.second = 0
        
        return calendar.date(from: components)
    }
    
    /// Default set of alarms recommended for perishable goods
    public static var defaultPresets: [NotificationReminderOption] {
        [.threeDays, .onTheDay]
    }
}
