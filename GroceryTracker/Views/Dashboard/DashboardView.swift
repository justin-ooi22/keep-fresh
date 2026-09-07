import SwiftUI

public struct DashboardView: View {
    @EnvironmentObject var store: InventoryStore
    @State private var showingScanner = false
    @State private var showingManualAdd = false
    @State private var selectedItemForDetail: GroceryItem?
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    // MARK: - Metrics Overview
                    metricsSection
                    
                    // MARK: - Eat First / Urgent Shelf
                    eatFirstSection
                    
                    // MARK: - Quick Action Buttons
                    actionButtonsSection
                    
                    // MARK: - House Zones Quick Overview
                    houseZonesSection
                    
                    // MARK: - Recently Added / Expiring Soon List
                    allExpiringSoonSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(AppTheme.screenBackground)
            .navigationTitle("FreshKeep")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingScanner = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                ScannerContainerView()
            }
            .sheet(isPresented: $showingManualAdd) {
                AddEditItemView()
            }
            .sheet(item: $selectedItemForDetail) { item in
                NavigationStack {
                    ItemDetailView(item: item)
                }
            }
        }
    }
    
    // MARK: - Metrics Section
    private var metricsSection: some View {
        HStack(spacing: 12) {
            MetricCard(
                title: "Active",
                value: "\(store.activeItems.count)",
                icon: "basket.fill",
                color: .blue
            )
            MetricCard(
                title: "Eat Soon",
                value: "\(store.eatFirstItems.count)",
                icon: "flame.fill",
                color: .orange
            )
            MetricCard(
                title: "Expired",
                value: "\(store.expiredItems.count)",
                icon: "exclamationmark.triangle.fill",
                color: .red
            )
            MetricCard(
                title: "Rooms",
                value: "\(store.zones.count)",
                icon: "house.fill",
                color: .purple
            )
        }
    }
    
    // MARK: - Eat First Shelf
    private var eatFirstSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Eat First Shelf", systemImage: "bolt.badge.clock.fill")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !store.eatFirstItems.isEmpty {
                    Text("\(store.eatFirstItems.count) urgent")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.orange.opacity(0.15)))
                }
            }
            
            if store.eatFirstItems.isEmpty {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.green)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No food at risk!")
                            .font(.subheadline.bold())
                        Text("All items in your house have plenty of shelf life remaining.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .appCard()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(store.eatFirstItems) { item in
                            ExpiringItemCard(
                                item: item,
                                zone: store.zone(for: item.zoneId),
                                onConsume: {
                                    withAnimation {
                                        store.markAsConsumed(item)
                                    }
                                }
                            )
                            .onTapGesture {
                                selectedItemForDetail = item
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        HStack(spacing: 14) {
            Button {
                showingScanner = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "camera.viewfinder")
                        .font(.headline)
                    Text("Scan Groceries")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.accentColor)
                )
            }
            
            Button {
                showingManualAdd = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.headline)
                    Text("Add Item")
                        .font(.headline)
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .appCard(cornerRadius: 14)
            }
        }
    }
    
    // MARK: - House Zones Overview
    private var houseZonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Storage Across Your House", systemImage: "house.fill")
                    .font(.title3.bold())
                Spacer()
                NavigationLink(destination: ZonesListView()) {
                    Text("See All")
                        .font(.subheadline.bold())
                        .foregroundColor(.accentColor)
                }
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(store.zones.prefix(4)) { zone in
                    let count = store.items(in: zone).count
                    NavigationLink(destination: ZoneDetailView(zone: zone)) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(zone.color.opacity(0.18))
                                    .frame(width: 40, height: 40)
                                Image(systemName: zone.iconName)
                                    .foregroundColor(zone.color)
                                    .font(.system(size: 18))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(zone.name)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Text("\(count) items")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(12)
                        .appCard()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - All Expiring Soon List
    private var allExpiringSoonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expiring This Week")
                .font(.title3.bold())
            
            if store.activeItems.prefix(5).isEmpty {
                Text("No items tracked yet. Tap 'Scan Groceries' to begin!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 10) {
                    ForEach(store.activeItems.prefix(5)) { item in
                        ItemRowView(item: item, zone: store.zone(for: item.zoneId))
                            .onTapGesture {
                                selectedItemForDetail = item
                            }
                    }
                }
            }
        }
    }
}

// MARK: - Mini Metric Card
private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.primary)
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .appCard(cornerRadius: 14)
    }
}
