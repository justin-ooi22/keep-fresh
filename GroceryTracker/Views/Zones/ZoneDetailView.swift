import SwiftUI

/// Detailed view showing all groceries stored in a specific house location.
public struct ZoneDetailView: View {
    @EnvironmentObject var store: InventoryStore
    public let zone: StorageZone
    
    @State private var showingAddSheet = false
    @State private var showingEditZone = false
    @State private var selectedItemForDetail: GroceryItem?
    
    public init(zone: StorageZone) {
        self.zone = zone
    }
    
    private var liveZone: StorageZone {
        store.zones.first(where: { $0.id == zone.id }) ?? zone
    }
    
    private var itemsInZone: [GroceryItem] {
        store.items(in: liveZone)
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // MARK: - Zone Banner
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(liveZone.color.opacity(0.2))
                            .frame(width: 64, height: 64)
                        Image(systemName: liveZone.iconName)
                            .foregroundColor(liveZone.color)
                            .font(.system(size: 28))
                    }
                    
                    VStack(spacing: 4) {
                        Text(liveZone.name)
                            .font(.title2.bold())
                        if !liveZone.roomDescription.isEmpty {
                            Text(liveZone.roomDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Text("\(itemsInZone.count) items stored")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        
                        let urgentCount = itemsInZone.filter { $0.daysUntilExpiry <= 3 }.count
                        if urgentCount > 0 {
                            Text("\(urgentCount) need attention")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .appCard()
                .padding(.horizontal, 16)
                
                // MARK: - Items in this Room
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Stored Groceries")
                            .font(.headline)
                        Spacer()
                        Button {
                            showingAddSheet = true
                        } label: {
                            Label("Add Item", systemImage: "plus.circle.fill")
                                .font(.subheadline.bold())
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    if itemsInZone.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "tray")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary)
                            Text("No items stored here yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(itemsInZone) { item in
                                ItemRowView(item: item, zone: liveZone)
                                    .onTapGesture {
                                        selectedItemForDetail = item
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 14)
        }
        .background(AppTheme.screenBackground)
        .navigationTitle(liveZone.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit Zone") {
                    showingEditZone = true
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddEditItemView(prefilledCategory: .other)
        }
        .sheet(isPresented: $showingEditZone) {
            AddEditZoneView(zoneToEdit: liveZone)
        }
        .sheet(item: $selectedItemForDetail) { item in
            NavigationStack {
                ItemDetailView(item: item)
            }
        }
    }
}
