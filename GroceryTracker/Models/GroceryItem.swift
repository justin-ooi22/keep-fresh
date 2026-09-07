import SwiftUI

/// Status representing the urgency of an item's expiration.
public enum ExpiryStatus: String, CaseIterable, Codable {
    case expired = "Expired"
    case critical = "Use Urgently" // 0 to 2 days left
    case soon = "Expiring Soon"    // 3 to 7 days left
    case fresh = "Fresh"           // > 7 days left
    
    public var color: Color {
        switch self {
        case .expired: return .red
        case .critical: return .orange
        case .soon: return .yellow
        case .fresh: return .green
        }
    }
    
    public var iconName: String {
        switch self {
        case .expired: return "exclamationmark.triangle.fill"
        case .critical: return "flame.fill"
        case .soon: return "clock.fill"
        case .fresh: return "checkmark.circle.fill"
        }
    }
}

/// Represents a tracked grocery item.
public struct GroceryItem: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var brand: String
    public var barcode: String?
    public var category: ItemCategory
    public var expiryDate: Date
    public var addedDate: Date
    public var openedDate: Date?
    public var zoneId: UUID
    public var quantity: Int
    public var notes: String
    public var reminderOptions: [NotificationReminderOption]
    public var isConsumed: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        brand: String = "",
        barcode: String? = nil,
        category: ItemCategory = .other,
        expiryDate: Date,
        addedDate: Date = Date(),
        openedDate: Date? = nil,
        zoneId: UUID,
        quantity: Int = 1,
        notes: String = "",
        reminderOptions: [NotificationReminderOption] = [.threeDays, .onTheDay],
        isConsumed: Bool = false
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.category = category
        self.expiryDate = expiryDate
        self.addedDate = addedDate
        self.openedDate = openedDate
        self.zoneId = zoneId
        self.quantity = quantity
        self.notes = notes
        self.reminderOptions = reminderOptions
        self.isConsumed = isConsumed
    }
    
    /// Number of calendar days between today and expiry date
    public var daysUntilExpiry: Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfExpiry = calendar.startOfDay(for: expiryDate)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfExpiry)
        return components.day ?? 0
    }
    
    /// True if the item is past its expiration date
    public var isExpired: Bool {
        daysUntilExpiry < 0
    }
    
    /// Current expiration urgency status
    public var status: ExpiryStatus {
        if daysUntilExpiry < 0 {
            return .expired
        } else if daysUntilExpiry <= 2 {
            return .critical
        } else if daysUntilExpiry <= 7 {
            return .soon
        } else {
            return .fresh
        }
    }
    
    /// Human readable countdown (e.g. "Expires in 2 days", "Expires today", "Expired 1 day ago")
    public var countdownDescription: String {
        let days = daysUntilExpiry
        if days < -1 {
            return "Expired \(-days) days ago"
        } else if days == -1 {
            return "Expired yesterday"
        } else if days == 0 {
            return "Expires today!"
        } else if days == 1 {
            return "Expires tomorrow"
        } else {
            return "Expires in \(days) days"
        }
    }
    
    /// Short date string for UI display
    public var formattedExpiryDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: expiryDate)
    }
}
