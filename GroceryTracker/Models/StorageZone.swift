import SwiftUI

/// Represents a physical storage location or room in the house where groceries are kept.
public struct StorageZone: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var iconName: String
    public var colorHex: String
    public var roomDescription: String
    public var isDefault: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "shippingbox.fill",
        colorHex: String = "#0A84FF",
        roomDescription: String = "",
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.roomDescription = roomDescription
        self.isDefault = isDefault
    }
    
    /// Color representation from stored hex string
    public var color: Color {
        Color(hex: colorHex)
    }
    
    /// Default locations curated for large homes
    public static let defaultZones: [StorageZone] = [
        StorageZone(
            name: "Kitchen Fridge",
            iconName: "refrigerator.fill",
            colorHex: "#007AFF", // Blue
            roomDescription: "Main refrigerator in the kitchen",
            isDefault: true
        ),
        StorageZone(
            name: "Kitchen Freezer",
            iconName: "snowflake",
            colorHex: "#5AC8FA", // Light Blue
            roomDescription: "Freezer compartment in kitchen",
            isDefault: true
        ),
        StorageZone(
            name: "Main Pantry",
            iconName: "cabinet.fill",
            colorHex: "#FF9500", // Orange
            roomDescription: "Kitchen walk-in food pantry",
            isDefault: true
        ),
        StorageZone(
            name: "Garage Freezer",
            iconName: "archivebox.fill",
            colorHex: "#5856D6", // Indigo
            roomDescription: "Chest or deep freezer in the garage",
            isDefault: true
        ),
        StorageZone(
            name: "Basement Cellar / Storage",
            iconName: "shippingbox.fill",
            colorHex: "#AF52DE", // Purple
            roomDescription: "Bulk goods and overflow in basement",
            isDefault: true
        ),
        StorageZone(
            name: "Beverage Cooler",
            iconName: "wineglass.fill",
            colorHex: "#FF2D55", // Pink
            roomDescription: "Bar or beverage fridge",
            isDefault: true
        )
    ]
}

// MARK: - Color Hex Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 122, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
