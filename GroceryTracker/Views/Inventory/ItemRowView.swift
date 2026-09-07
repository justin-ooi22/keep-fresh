import SwiftUI

/// Standard row component for displaying a grocery item in inventory lists.
public struct ItemRowView: View {
    public let item: GroceryItem
    public let zone: StorageZone?
    
    public init(item: GroceryItem, zone: StorageZone?) {
        self.item = item
        self.zone = zone
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            // Category Icon Badge
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(item.category.color.opacity(0.18))
                    .frame(width: 46, height: 46)
                Image(systemName: item.category.iconName)
                    .foregroundColor(item.category.color)
                    .font(.system(size: 20))
            }
            
            // Name, Brand, and Room Location
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.body.bold())
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if item.quantity > 1 {
                        Text("×\(item.quantity)")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(UIColor.tertiarySystemFill)))
                    }
                }
                
                HStack(spacing: 8) {
                    if !item.brand.isEmpty {
                        Text(item.brand)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if let zone = zone {
                        HStack(spacing: 4) {
                            Image(systemName: zone.iconName)
                                .font(.system(size: 10))
                                .foregroundColor(zone.color)
                            Text(zone.name)
                                .font(.caption2.bold())
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(UIColor.tertiarySystemFill)))
                    }
                }
            }
            
            Spacer()
            
            // Expiry Countdown & Status Pill
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: item.status.iconName)
                        .font(.system(size: 11))
                    Text(item.countdownDescription)
                        .font(.caption.bold())
                }
                .foregroundColor(item.status.color)
                
                Text(item.formattedExpiryDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .appCard(cornerRadius: 14)
    }
}
