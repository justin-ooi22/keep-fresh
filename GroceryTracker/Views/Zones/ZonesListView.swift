import SwiftUI

/// Main screen showcasing all storage locations across a large house.
public struct ZonesListView: View {
    @EnvironmentObject var store: InventoryStore
    @State private var showingAddZone = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Header Subtitle
                    Text("Organize and find groceries quickly across your different refrigerators, pantries, and storage rooms.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                    
                    // Zones Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(store.zones) { zone in
                            NavigationLink(destination: ZoneDetailView(zone: zone)) {
                                zoneCard(for: zone)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 14)
            }
            .background(AppTheme.screenBackground)
            .navigationTitle("House Storage")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddZone = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                    }
                }
            }
            .sheet(isPresented: $showingAddZone) {
                AddEditZoneView()
            }
        }
    }
    
    private func zoneCard(for zone: StorageZone) -> some View {
        let items = store.items(in: zone)
        let earliestExpiring = items.sorted { $0.expiryDate < $1.expiryDate }.first
        
        return VStack(alignment: .leading, spacing: 12) {
            // Icon & Count Badge
            HStack {
                ZStack {
                    Circle()
                        .fill(zone.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: zone.iconName)
                        .foregroundColor(zone.color)
                        .font(.system(size: 20))
                }
                
                Spacer()
                
                Text("\(items.count)")
                    .font(.headline.bold())
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(UIColor.tertiarySystemFill)))
            }
            
            // Name & Description
            VStack(alignment: .leading, spacing: 3) {
                Text(zone.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if !zone.roomDescription.isEmpty {
                    Text(zone.roomDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer(minLength: 4)
            
            // Earliest Expiring Item Teaser
            if let nextItem = earliestExpiring {
                HStack(spacing: 5) {
                    Image(systemName: nextItem.status.iconName)
                        .font(.system(size: 10))
                        .foregroundColor(nextItem.status.color)
                    Text(nextItem.countdownDescription)
                        .font(.caption2.bold())
                        .foregroundColor(nextItem.status.color)
                        .lineLimit(1)
                }
                .padding(.top, 4)
            } else {
                Text("Empty room")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(14)
        .frame(height: 155)
        .appCard()
    }
}
