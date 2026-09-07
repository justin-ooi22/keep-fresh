import SwiftUI

/// Categories for organizing grocery items with corresponding icons and colors.
public enum ItemCategory: String, CaseIterable, Codable, Identifiable {
    case dairy = "Dairy & Eggs"
    case produce = "Fruits & Vegetables"
    case meat = "Meat & Seafood"
    case bakery = "Bakery & Bread"
    case pantry = "Pantry & Canned"
    case frozen = "Frozen Foods"
    case beverages = "Beverages"
    case condiments = "Condiments & Sauces"
    case snacks = "Snacks & Sweets"
    case prepared = "Prepared Meals"
    case other = "Other"

    public var id: String { rawValue }

    /// Localized display name
    public var localizedName: String {
        switch self {
        case .dairy: return String(localized: "Dairy & Eggs")
        case .produce: return String(localized: "Fruits & Vegetables")
        case .meat: return String(localized: "Meat & Seafood")
        case .bakery: return String(localized: "Bakery & Bread")
        case .pantry: return String(localized: "Pantry & Canned")
        case .frozen: return String(localized: "Frozen Foods")
        case .beverages: return String(localized: "Beverages")
        case .condiments: return String(localized: "Condiments & Sauces")
        case .snacks: return String(localized: "Snacks & Sweets")
        case .prepared: return String(localized: "Prepared Meals")
        case .other: return String(localized: "Other")
        }
    }

    public var iconName: String {
        switch self {
        case .dairy: return "cup.and.saucer.fill"
        case .produce: return "carrot.fill"
        case .meat: return "fork.knife"
        case .bakery: return "birthday.cake.fill"
        case .pantry: return "takeoutbag.and.cup.and.straw.fill"
        case .frozen: return "snowflake"
        case .beverages: return "waterbottle.fill"
        case .condiments: return "drop.fill"
        case .snacks: return "popcorn.fill"
        case .prepared: return "frying.pan.fill"
        case .other: return "tag.fill"
        }
    }

    public var color: Color {
        switch self {
        case .dairy: return .blue
        case .produce: return .green
        case .meat: return .red
        case .bakery: return .brown
        case .pantry: return .orange
        case .frozen: return .cyan
        case .beverages: return .teal
        case .condiments: return .yellow
        case .snacks: return .purple
        case .prepared: return .indigo
        case .other: return .gray
        }
    }
}
