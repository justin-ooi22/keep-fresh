import SwiftUI

public struct InventoryListView: View {
    @EnvironmentObject var store: InventoryStore
    
    @State private var searchText = ""
    @State private var selectedStatusFilter: ExpiryFilter = .all
    @State private var selectedZoneId: UUID? = nil
    @State private var sortOption: SortOption = .expirySoonest
    @State private var showingScanner = false
    @State private var showingAddSheet = false
    @State private var selectedItemForDetail: GroceryItem?
    
    public enum ExpiryFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case urgent = "Eat First"
        case soon = "Soon"
        case fresh = "Fresh"
        case expired = "Expired"
        
        public var id: String { rawValue }
        
        public var localizedTitle: String {
            switch self {
            case .all: return String(localized: "All")
            case .urgent: return String(localized: "Eat First")
            case .soon: return String(localized: "Soon")
            case .fresh: return String(localized: "Fresh")
            case .expired: return String(localized: "Expired")
            }
        }
    }
    
    public enum SortOption: String, CaseIterable, Identifiable {
        case expirySoonest = "Soonest Expiry"
        case expiryFurthest = "Furthest Expiry"
        case name = "Name (A-Z)"
        case zone = "Storage Location"
        
        public var id: String { rawValue }
        
        public var localizedTitle: String {
            switch self {
            case .expirySoonest: return String(localized: "Soonest Expiry")
            case .expiryFurthest: return String(localized: "Furthest Expiry")
            case .name: return String(localized: "Name (A-Z)")
            case .zone: return String(localized: "Storage Location")
            }
        }
    }
    
    public init() {}
    
    private var filteredItems: [GroceryItem] {
        var result = store.activeItems
        
        // Expiration Status Filter
        switch selectedStatusFilter {
        case .all:
            break
        case .urgent:
            result = result.filter { $0.daysUntilExpiry <= 3 && !$0.isExpired }
        case .soon:
            result = result.filter { $0.daysUntilExpiry > 3 && $0.daysUntilExpiry <= 7 }
        case .fresh:
            result = result.filter { $0.daysUntilExpiry > 7 }
        case .expired:
            result = store.items.filter { !$0.isConsumed && $0.isExpired }
        }
        
        // Zone Filter
        if let zoneId = selectedZoneId {
            result = result.filter { $0.zoneId == zoneId }
        }
        
        // Search Filter
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.brand.lowercased().contains(query) ||
                $0.notes.lowercased().contains(query)
            }
        }
        
        // Sorting
        switch sortOption {
        case .expirySoonest:
            result.sort { $0.expiryDate < $1.expiryDate }
        case .expiryFurthest:
            result.sort { $0.expiryDate > $1.expiryDate }
        case .name:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .zone:
            result.sort {
                let zoneA = store.zone(for: $0.zoneId)?.name ?? ""
                let zoneB = store.zone(for: $1.zoneId)?.name ?? ""
                return zoneA < zoneB
            }
        }
        
        return result
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Filter Bar
                filterHeader
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppTheme.cardBackground)
                
                // MARK: - Items List
                if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            ItemRowView(item: item, zone: store.zone(for: item.zoneId))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedItemForDetail = item
                                }
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .leading) {
                                    Button {
                                        withAnimation {
                                            store.markAsConsumed(item)
                                        }
                                    } label: {
                                        Label("Eat", systemImage: "fork.knife")
                                    }
                                    .tint(.green)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            store.deleteItem(item)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .background(AppTheme.screenBackground)
                }
            }
            .background(AppTheme.screenBackground)
            .navigationTitle("Pantry & Groceries")
            .searchable(text: $searchText, prompt: "Search by item, brand, or notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Sort By", selection: $sortOption) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.localizedTitle).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showingScanner = true
                        } label: {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 18))
                        }
                        
                        Button {
                            showingAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                ScannerContainerView()
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEditItemView()
            }
            .sheet(item: $selectedItemForDetail) { item in
                NavigationStack {
                    ItemDetailView(item: item)
                }
            }
        }
    }
    
    // MARK: - Filter Header
    private var filterHeader: some View {
        VStack(spacing: 10) {
            // Status Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ExpiryFilter.allCases) { filter in
                        Button {
                            selectedStatusFilter = filter
                        } label: {
                            Text(filter.localizedTitle)
                                .font(.subheadline.bold())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(selectedStatusFilter == filter ? Color.accentColor : Color(UIColor.tertiarySystemFill))
                                )
                                .foregroundColor(selectedStatusFilter == filter ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Storage Zone Dropdown Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        selectedZoneId = nil
                    } label: {
                        Text("All Rooms")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(selectedZoneId == nil ? Color.primary.opacity(0.12) : Color.clear)
                            )
                            .foregroundColor(selectedZoneId == nil ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                    
                    ForEach(store.zones) { zone in
                        Button {
                            if selectedZoneId == zone.id {
                                selectedZoneId = nil
                            } else {
                                selectedZoneId = zone.id
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: zone.iconName)
                                    .foregroundColor(zone.color)
                                Text(zone.name)
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(selectedZoneId == zone.id ? zone.color.opacity(0.18) : Color.clear)
                            )
                            .foregroundColor(selectedZoneId == zone.id ? zone.color : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Items Found")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Try changing your search or filter options, or tap '+' to scan and add new groceries.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                showingAddSheet = true
            } label: {
                Text("Add Item Now")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.accentColor))
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
