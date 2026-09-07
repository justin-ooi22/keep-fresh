import Foundation
import SwiftUI
import Combine

/// Central observable store for inventory, storage zones, and notification integration.
@MainActor
public final class InventoryStore: ObservableObject {
    @Published public var items: [GroceryItem] = []
    @Published public var zones: [StorageZone] = []
    @Published public var defaultReminderOptions: [NotificationReminderOption] = [.oneWeek, .threeDays, .twoDays, .onTheDay]
    @Published public var alertHour: Int = 9
    @Published public var alertMinute: Int = 0
    
    private let itemsFileName = "grocery_items.json"
    private let zonesFileName = "storage_zones.json"
    private let settingsFileName = "app_settings.json"
    
    public init() {
        loadData()
    }
    
    // MARK: - CRUD: Items
    
    public func addItem(_ item: GroceryItem) {
        items.append(item)
        saveData()
        
        let zoneName = zone(for: item.zoneId)?.name ?? "House"
        NotificationManager.shared.scheduleNotifications(for: item, zoneName: zoneName)
    }
    
    public func updateItem(_ item: GroceryItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            saveData()
            
            let zoneName = zone(for: item.zoneId)?.name ?? "House"
            NotificationManager.shared.scheduleNotifications(for: item, zoneName: zoneName)
        }
    }
    
    public func markAsConsumed(_ item: GroceryItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isConsumed = true
            saveData()
            NotificationManager.shared.cancelNotifications(for: item.id)
        }
    }
    
    public func deleteItem(_ item: GroceryItem) {
        items.removeAll { $0.id == item.id }
        saveData()
        NotificationManager.shared.cancelNotifications(for: item.id)
    }
    
    public func deleteItems(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { items[$0] }
        for item in itemsToDelete {
            NotificationManager.shared.cancelNotifications(for: item.id)
        }
        items.remove(atOffsets: offsets)
        saveData()
    }
    
    // MARK: - CRUD: Storage Zones
    
    public func addZone(_ zone: StorageZone) {
        zones.append(zone)
        saveData()
    }
    
    public func updateZone(_ zone: StorageZone) {
        if let index = zones.firstIndex(where: { $0.id == zone.id }) {
            zones[index] = zone
            saveData()
        }
    }
    
    public func deleteZone(_ zone: StorageZone) {
        // Prevent deleting if it's the last zone
        guard zones.count > 1 else { return }
        
        // Reassign any items in this zone to the first remaining zone
        if let fallbackZone = zones.first(where: { $0.id != zone.id }) {
            for i in items.indices where items[i].zoneId == zone.id {
                items[i].zoneId = fallbackZone.id
            }
        }
        
        zones.removeAll { $0.id == zone.id }
        saveData()
    }
    
    // MARK: - Helpers & Filtered Queries
    
    public func zone(for id: UUID) -> StorageZone? {
        zones.first { $0.id == id }
    }
    
    /// Unconsumed items sorted by expiration date (soonest first)
    public var activeItems: [GroceryItem] {
        items
            .filter { !$0.isConsumed }
            .sorted { $0.expiryDate < $1.expiryDate }
    }
    
    /// Urgent items expiring today or within 3 days ("Eat First" shelf)
    public var eatFirstItems: [GroceryItem] {
        activeItems.filter { $0.daysUntilExpiry <= 3 }
    }
    
    /// Items that have already expired
    public var expiredItems: [GroceryItem] {
        activeItems.filter { $0.isExpired }
    }
    
    /// Items expiring in 4 to 7 days
    public var expiringSoonItems: [GroceryItem] {
        activeItems.filter { $0.daysUntilExpiry > 3 && $0.daysUntilExpiry <= 7 }
    }
    
    /// Items with plenty of shelf life remaining (> 7 days)
    public var freshItems: [GroceryItem] {
        activeItems.filter { $0.daysUntilExpiry > 7 }
    }
    
    /// Items belonging to a specific storage room
    public func items(in zone: StorageZone) -> [GroceryItem] {
        activeItems.filter { $0.zoneId == zone.id }
    }
    
    // MARK: - Persistence
    
    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    public func saveData() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        // Save items
        if let itemsData = try? encoder.encode(items) {
            let itemsURL = documentsURL.appendingPathComponent(itemsFileName)
            try? itemsData.write(to: itemsURL)
        }
        
        // Save zones
        if let zonesData = try? encoder.encode(zones) {
            let zonesURL = documentsURL.appendingPathComponent(zonesFileName)
            try? zonesData.write(to: zonesURL)
        }
    }
    
    public func loadData() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Load Zones
        let zonesURL = documentsURL.appendingPathComponent(zonesFileName)
        if let zonesData = try? Data(contentsOf: zonesURL),
           let loadedZones = try? decoder.decode([StorageZone].self, from: zonesData),
           !loadedZones.isEmpty {
            self.zones = loadedZones
        } else {
            self.zones = StorageZone.defaultZones
        }
        
        // Load Items
        let itemsURL = documentsURL.appendingPathComponent(itemsFileName)
        if let itemsData = try? Data(contentsOf: itemsURL),
           let loadedItems = try? decoder.decode([GroceryItem].self, from: itemsData) {
            self.items = loadedItems
        } else {
            // Populate rich initial sample data on first launch
            loadSampleData()
        }
    }
    
    /// Seeds realistic sample groceries across the house's storage zones
    public func loadSampleData() {
        let calendar = Calendar.current
        let today = Date()
        
        guard let fridgeZone = zones.first(where: { $0.name.contains("Fridge") }) ?? zones.first,
              let pantryZone = zones.first(where: { $0.name.contains("Pantry") }) ?? zones.first,
              let garageZone = zones.first(where: { $0.name.contains("Garage") }) ?? zones.first,
              let freezerZone = zones.first(where: { $0.name.contains("Freezer") && !$0.name.contains("Garage") }) ?? zones.first else {
            return
        }
        
        self.items = [
            GroceryItem(
                name: "Organic Whole Milk",
                brand: "Horizon Organic",
                category: .dairy,
                expiryDate: calendar.date(byAdding: .day, value: 1, to: today)!,
                zoneId: fridgeZone.id,
                quantity: 1,
                notes: "Opened 2 days ago, use for morning coffee and cereal",
                reminderOptions: [.threeDays, .twoDays, .onTheDay]
            ),
            GroceryItem(
                name: "Greek Yogurt Cups",
                brand: "Chobani",
                category: .dairy,
                expiryDate: calendar.date(byAdding: .day, value: 0, to: today)!, // Expires today
                zoneId: fridgeZone.id,
                quantity: 3,
                notes: "Strawberry flavor",
                reminderOptions: [.oneWeek, .threeDays, .twoDays, .onTheDay]
            ),
            GroceryItem(
                name: "Artisan Sourdough Bread",
                brand: "Local Bakery",
                category: .bakery,
                expiryDate: calendar.date(byAdding: .day, value: 2, to: today)!,
                zoneId: pantryZone.id,
                quantity: 1,
                notes: "Freeze slices if not finished by tomorrow",
                reminderOptions: [.twoDays, .onTheDay]
            ),
            GroceryItem(
                name: "Atlantic Salmon Fillets",
                brand: "Kirkland Signature",
                category: .meat,
                expiryDate: calendar.date(byAdding: .day, value: 4, to: today)!,
                zoneId: fridgeZone.id,
                quantity: 2,
                notes: "For Friday dinner",
                reminderOptions: [.threeDays, .onTheDay]
            ),
            GroceryItem(
                name: "Baby Spinach & Arugula",
                brand: "Organic Girl",
                category: .produce,
                expiryDate: calendar.date(byAdding: .day, value: 3, to: today)!,
                zoneId: fridgeZone.id,
                quantity: 1,
                notes: "Salad crisper drawer",
                reminderOptions: [.threeDays, .twoDays, .onTheDay]
            ),
            GroceryItem(
                name: "Grass-Fed Ground Beef (Bulk)",
                brand: "Wild Fork",
                category: .frozen,
                expiryDate: calendar.date(byAdding: .day, value: 60, to: today)!,
                zoneId: garageZone.id,
                quantity: 4,
                notes: "Stored in bottom basket of garage chest freezer",
                reminderOptions: [.oneWeek, .threeDays, .onTheDay]
            ),
            GroceryItem(
                name: "San Marzano Canned Tomatoes",
                brand: "Centaur",
                category: .pantry,
                expiryDate: calendar.date(byAdding: .day, value: 180, to: today)!,
                zoneId: pantryZone.id,
                quantity: 6,
                notes: "Shelf 2 in main pantry",
                reminderOptions: [.oneWeek, .onTheDay]
            ),
            GroceryItem(
                name: "Frozen Wild Blueberries",
                brand: "Wyman's",
                category: .frozen,
                expiryDate: calendar.date(byAdding: .day, value: 90, to: today)!,
                zoneId: freezerZone.id,
                quantity: 2,
                notes: "For smoothies",
                reminderOptions: [.oneWeek, .onTheDay]
            )
        ]
        
        saveData()
    }
}
