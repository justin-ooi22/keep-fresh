import SwiftUI

/// Root tab container view with navigation tabs, badge counts, and appearance management.
public struct ContentView: View {
    @EnvironmentObject var store: InventoryStore
    @AppStorage("userColorScheme") private var userColorScheme: String = "system"
    @State private var selectedTab: Int = 0
    
    public init() {}
    
    private var colorSchemeOverride: ColorScheme? {
        switch userColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .badge(store.eatFirstItems.count > 0 ? store.eatFirstItems.count : 0)
                .tag(0)
            
            InventoryListView()
                .tabItem {
                    Label("Inventory", systemImage: "list.bullet.rectangle.portrait.fill")
                }
                .tag(1)
            
            ZonesListView()
                .tabItem {
                    Label("Rooms & Zones", systemImage: "square.grid.2x2.fill")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .preferredColorScheme(colorSchemeOverride)
    }
}
