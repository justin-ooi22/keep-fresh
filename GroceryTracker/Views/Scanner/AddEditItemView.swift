import SwiftUI

/// Form to review scanned item details, assign house storage room, and configure multi-alarm notifications.
public struct AddEditItemView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: InventoryStore
    
    public var itemToEdit: GroceryItem?
    public var onSaved: () -> Void = {}
    
    @State private var name: String
    @State private var brand: String
    @State private var barcode: String
    @State private var category: ItemCategory
    @State private var expiryDate: Date
    @State private var selectedZoneId: UUID
    @State private var quantity: Int
    @State private var notes: String
    @State private var selectedReminders: Set<NotificationReminderOption>
    
    public init(
        itemToEdit: GroceryItem? = nil,
        prefilledName: String = "",
        prefilledBrand: String = "",
        prefilledBarcode: String = "",
        prefilledCategory: ItemCategory = .dairy,
        prefilledExpiryDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
        onSaved: @escaping () -> Void = {}
    ) {
        self.itemToEdit = itemToEdit
        self.onSaved = onSaved
        
        if let existing = itemToEdit {
            _name = State(initialValue: existing.name)
            _brand = State(initialValue: existing.brand)
            _barcode = State(initialValue: existing.barcode ?? "")
            _category = State(initialValue: existing.category)
            _expiryDate = State(initialValue: existing.expiryDate)
            _selectedZoneId = State(initialValue: existing.zoneId)
            _quantity = State(initialValue: existing.quantity)
            _notes = State(initialValue: existing.notes)
            _selectedReminders = State(initialValue: Set(existing.reminderOptions))
        } else {
            _name = State(initialValue: prefilledName)
            _brand = State(initialValue: prefilledBrand)
            _barcode = State(initialValue: prefilledBarcode)
            _category = State(initialValue: prefilledCategory)
            _expiryDate = State(initialValue: prefilledExpiryDate)
            _selectedZoneId = State(initialValue: UUID())
            _quantity = State(initialValue: 1)
            _notes = State(initialValue: "")
            _selectedReminders = State(initialValue: [.threeDays, .onTheDay])
        }
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // MARK: - Product Details
                Section("Product Information") {
                    TextField("Item Name (e.g. Greek Yogurt)", text: $name)
                        .font(.headline)
                    
                    TextField("Brand (Optional)", text: $brand)
                    
                    if !barcode.isEmpty {
                        HStack {
                            Text("Barcode")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(barcode)
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(ItemCategory.allCases) { cat in
                            Label(cat.localizedName, systemImage: cat.iconName)
                                .tag(cat)
                        }
                    }
                }
                
                // MARK: - House Storage Zone
                Section {
                    Picker("Storage Location", selection: $selectedZoneId) {
                        ForEach(store.zones) { zone in
                            HStack {
                                Image(systemName: zone.iconName)
                                    .foregroundColor(zone.color)
                                Text(zone.name)
                            }
                            .tag(zone.id)
                        }
                    }
                } header: {
                    Text("Storage in Your House")
                } footer: {
                    Text("Helps you remember which room or fridge this item was put in.")
                }
                
                // MARK: - Expiration Date
                Section("Best Before / Expiry Date") {
                    DatePicker(
                        "Expiry Date",
                        selection: $expiryDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    
                    // Quick Date Shortcuts
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            quickDateButton(title: String(localized: "+3 Days"), days: 3)
                            quickDateButton(title: String(localized: "+1 Week"), days: 7)
                            quickDateButton(title: String(localized: "+2 Weeks"), days: 14)
                            quickDateButton(title: String(localized: "+1 Month"), days: 30)
                            quickDateButton(title: String(localized: "+6 Months"), days: 180)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // MARK: - Multi-Alarm Notifications
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Select when you want to receive alerts before this item expires. You can enable multiple alarms.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(NotificationReminderOption.allCases) { option in
                            Button {
                                toggleReminder(option)
                            } label: {
                                HStack {
                                    Image(systemName: selectedReminders.contains(option) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedReminders.contains(option) ? .accentColor : .secondary)
                                        .font(.system(size: 20))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(option.title)
                                            .font(.subheadline.bold())
                                            .foregroundColor(.primary)
                                        
                                        if let triggerDate = option.targetTriggerDate(for: expiryDate) {
                                            let dateString = formattedDate(triggerDate)
                                            Text("Scheduled: \(dateString) at 9:00 AM")
                                                .font(.caption2)
                                                .foregroundColor(triggerDate < Date() ? .red : .secondary)
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
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Label("Expiry Notifications (Multi-Alarm)", systemImage: "bell.badge.fill")
                }
                
                // MARK: - Quantity & Notes
                Section("Additional Details") {
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
                    
                    TextField("Notes (e.g., crisper drawer, keep sealed)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(itemToEdit == nil ? "New Grocery Item" : "Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                // Ensure valid default zone is selected
                if !store.zones.contains(where: { $0.id == selectedZoneId }) {
                    if let firstZone = store.zones.first {
                        selectedZoneId = firstZone.id
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Date Shortcut Button
    private func quickDateButton(title: String, days: Int) -> some View {
        Button {
            if let newDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) {
                self.expiryDate = newDate
            }
        } label: {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
    }
    
    private func toggleReminder(_ option: NotificationReminderOption) {
        if selectedReminders.contains(option) {
            selectedReminders.remove(option)
        } else {
            selectedReminders.insert(option)
        }
    }
    
    private func saveItem() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        if var existing = itemToEdit {
            existing.name = trimmedName
            existing.brand = brand.trimmingCharacters(in: .whitespaces)
            existing.barcode = barcode.isEmpty ? nil : barcode
            existing.category = category
            existing.expiryDate = expiryDate
            existing.zoneId = selectedZoneId
            existing.quantity = quantity
            existing.notes = notes
            existing.reminderOptions = Array(selectedReminders)
            store.updateItem(existing)
        } else {
            let newItem = GroceryItem(
                name: trimmedName,
                brand: brand.trimmingCharacters(in: .whitespaces),
                barcode: barcode.isEmpty ? nil : barcode,
                category: category,
                expiryDate: expiryDate,
                zoneId: selectedZoneId,
                quantity: quantity,
                notes: notes,
                reminderOptions: Array(selectedReminders)
            )
            store.addItem(newItem)
        }
        
        onSaved()
        dismiss()
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
