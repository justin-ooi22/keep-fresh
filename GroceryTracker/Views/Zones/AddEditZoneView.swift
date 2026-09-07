import SwiftUI

/// Modal sheet for creating or editing a house storage zone/room.
public struct AddEditZoneView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: InventoryStore
    
    public var zoneToEdit: StorageZone?
    
    @State private var name: String
    @State private var iconName: String
    @State private var colorHex: String
    @State private var roomDescription: String
    
    private let availableIcons = [
        "refrigerator.fill", "snowflake", "cabinet.fill",
        "archivebox.fill", "shippingbox.fill", "wineglass.fill",
        "cup.and.saucer.fill", "basket.fill", "tray.full.fill",
        "takeoutbag.and.cup.and.straw.fill", "house.fill", "door.left.hand.closed"
    ]
    
    private let availableColors = [
        "#007AFF", // Blue
        "#5AC8FA", // Teal / Ice Blue
        "#34C759", // Green
        "#FF9500", // Orange
        "#FF2D55", // Pink
        "#AF52DE", // Purple
        "#5856D6", // Indigo
        "#8E8E93"  // Slate
    ]
    
    public init(zoneToEdit: StorageZone? = nil) {
        self.zoneToEdit = zoneToEdit
        if let existing = zoneToEdit {
            _name = State(initialValue: existing.name)
            _iconName = State(initialValue: existing.iconName)
            _colorHex = State(initialValue: existing.colorHex)
            _roomDescription = State(initialValue: existing.roomDescription)
        } else {
            _name = State(initialValue: "")
            _iconName = State(initialValue: "shippingbox.fill")
            _colorHex = State(initialValue: "#007AFF")
            _roomDescription = State(initialValue: "")
        }
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Room / Location Details") {
                    TextField("Room Name (e.g. Basement Freezer)", text: $name)
                        .font(.headline)
                    
                    TextField("Description (e.g. 2nd floor, garage corner)", text: $roomDescription)
                }
                
                Section("Choose Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 14) {
                        ForEach(availableIcons, id: \.self) { icon in
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(iconName == icon ? Color(hex: colorHex).opacity(0.2) : Color(UIColor.tertiarySystemFill))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(iconName == icon ? Color(hex: colorHex) : Color.clear, lineWidth: 2)
                                    )
                                
                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(iconName == icon ? Color(hex: colorHex) : .secondary)
                            }
                            .onTapGesture {
                                iconName = icon
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Color Accent") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(availableColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: colorHex == hex ? 3 : 0)
                                )
                                .shadow(radius: colorHex == hex ? 2 : 0)
                                .onTapGesture {
                                    colorHex = hex
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(zoneToEdit == nil ? "New Storage Zone" : "Edit Zone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveZone()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func saveZone() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        if var existing = zoneToEdit {
            existing.name = trimmed
            existing.iconName = iconName
            existing.colorHex = colorHex
            existing.roomDescription = roomDescription
            store.updateZone(existing)
        } else {
            let newZone = StorageZone(
                name: trimmed,
                iconName: iconName,
                colorHex: colorHex,
                roomDescription: roomDescription,
                isDefault: false
            )
            store.addZone(newZone)
        }
        
        dismiss()
    }
}
