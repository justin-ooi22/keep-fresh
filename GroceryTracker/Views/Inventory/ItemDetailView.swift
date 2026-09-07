import SwiftUI

/// Detailed view for inspecting a grocery item, reviewing active alarm dates, and moving rooms.
public struct ItemDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: InventoryStore
    
    public let item: GroceryItem
    
    @State private var showingEditSheet = false
    @State private var showingZonePicker = false
    
    public init(item: GroceryItem) {
        self.item = item
    }
    
    // Fetch live item from store if possible to reflect updates
    private var liveItem: GroceryItem {
        store.items.first(where: { $0.id == item.id }) ?? item
    }
    
    private var currentZone: StorageZone? {
        store.zone(for: liveItem.zoneId)
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Header Status Card
                headerCard
                
                // MARK: - Storage Room Location
                locationCard
                
                // MARK: - Scheduled Notifications (Multi-Alarm)
                notificationsCard
                
                // MARK: - Product Metadata & Notes
                metadataCard
                
                // MARK: - Action Buttons
                actionsSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(AppTheme.screenBackground)
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            AddEditItemView(itemToEdit: liveItem)
        }
        .confirmationDialog("Move to Room", isPresented: $showingZonePicker, titleVisibility: .visible) {
            ForEach(store.zones) { zone in
                Button(zone.name) {
                    var updated = liveItem
                    updated.zoneId = zone.id
                    store.updateItem(updated)
                }
            }
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(liveItem.category.color.opacity(0.18))
                    .frame(width: 72, height: 72)
                Image(systemName: liveItem.category.iconName)
                    .font(.system(size: 34))
                    .foregroundColor(liveItem.category.color)
            }
            
            VStack(spacing: 4) {
                Text(liveItem.name)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                if !liveItem.brand.isEmpty {
                    Text(liveItem.brand)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Expiry Status Banner
            HStack(spacing: 6) {
                Image(systemName: liveItem.status.iconName)
                Text(liveItem.countdownDescription)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(liveItem.status.color.opacity(0.18)))
            .foregroundColor(liveItem.status.color)
            
            Text("Expiry Date: \(liveItem.formattedExpiryDate)")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .appCard()
    }
    
    // MARK: - Location Card
    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("House Storage Location", systemImage: "house.fill")
                    .font(.headline)
                Spacer()
                Button("Move Room") {
                    showingZonePicker = true
                }
                .font(.subheadline.bold())
                .foregroundColor(.accentColor)
            }
            
            if let zone = currentZone {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(zone.color.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: zone.iconName)
                            .foregroundColor(zone.color)
                            .font(.system(size: 20))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(zone.name)
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        if !zone.roomDescription.isEmpty {
                            Text(zone.roomDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.tertiarySystemFill))
                )
                .onTapGesture {
                    showingZonePicker = true
                }
            }
        }
        .padding(16)
        .appCard()
    }
    
    // MARK: - Notifications Card
    private var notificationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Active Expiry Alarms", systemImage: "bell.badge.fill")
                .font(.headline)
            
            if liveItem.reminderOptions.isEmpty {
                Text("No reminders set for this item.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(liveItem.reminderOptions) { option in
                        let triggerDate = option.targetTriggerDate(for: liveItem.expiryDate)
                        let isPast = (triggerDate ?? Date()) < Date()
                        
                        HStack {
                            Image(systemName: isPast ? "checkmark.circle" : "alarm.fill")
                                .foregroundColor(isPast ? .secondary : .orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.title)
                                    .font(.subheadline.bold())
                                    .foregroundColor(isPast ? .secondary : .primary)
                                
                                if let trigger = triggerDate {
                                    Text(isPast ? "Triggered: \(formattedDate(trigger))" : "Scheduled: \(formattedDate(trigger)) at 9:00 AM")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Text(option.shortBadge)
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.secondary.opacity(0.15)))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        if option != liveItem.reminderOptions.last {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(16)
        .appCard()
    }
    
    // MARK: - Metadata Card
    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Details & Notes", systemImage: "info.circle.fill")
                .font(.headline)
            
            VStack(spacing: 8) {
                detailRow(label: "Category", value: liveItem.category.rawValue)
                detailRow(label: "Quantity", value: "\(liveItem.quantity)")
                detailRow(label: "Added On", value: formattedDate(liveItem.addedDate))
                
                if let barcode = liveItem.barcode {
                    detailRow(label: "Barcode", value: barcode)
                }
                
                if !liveItem.notes.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes:")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        Text(liveItem.notes)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(16)
        .appCard()
    }
    
    // MARK: - Action Buttons
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation {
                    store.markAsConsumed(liveItem)
                    dismiss()
                }
            } label: {
                HStack {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.title3)
                    Text("Mark as Consumed / Eaten")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.green)
                )
            }
            
            Button(role: .destructive) {
                withAnimation {
                    store.deleteItem(liveItem)
                    dismiss()
                }
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Item")
                }
                .font(.subheadline.bold())
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
