import SwiftUI

@main
struct GroceryTrackerApp: App {
    @StateObject private var store = InventoryStore()
    
    init() {
        // Request notification authorization on launch
        Task {
            _ = await NotificationManager.shared.requestAuthorization()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .task {
                    // Reschedule any pending notifications
                    NotificationManager.shared.rescheduleAll(items: store.items, zones: store.zones)
                }
        }
    }
}
