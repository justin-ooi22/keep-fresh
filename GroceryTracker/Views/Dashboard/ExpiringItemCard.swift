import SwiftUI

/// Visual card representing an item needing urgent attention on the "Eat First" carousel.
public struct ExpiringItemCard: View {
    public let item: GroceryItem
    public let zone: StorageZone?
    public var onConsume: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    public init(item: GroceryItem, zone: StorageZone?, onConsume: @escaping () -> Void = {}) {
        self.item = item
        self.zone = zone
        self.onConsume = onConsume
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Category Icon & Urgency Badge
            HStack {
                ZStack {
                    Circle()
                        .fill(item.category.color.opacity(0.18))
                        .frame(width: 38, height: 38)
                    Image(systemName: item.category.iconName)
                        .foregroundColor(item.category.color)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Spacer()
                
                // Countdown Badge
                HStack(spacing: 4) {
                    Image(systemName: item.status.iconName)
                        .font(.system(size: 11, weight: .bold))
                    Text(item.countdownDescription)
                        .font(.caption.bold())
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(item.status.color.opacity(0.18))
                )
                .foregroundColor(item.status.color)
            }
            
            // Item Name & Brand
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if !item.brand.isEmpty {
                    Text(item.brand)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer(minLength: 4)
            
            // Location Badge & Consume Action
            HStack {
                if let zone = zone {
                    HStack(spacing: 5) {
                        Image(systemName: zone.iconName)
                            .font(.system(size: 11))
                            .foregroundColor(zone.color)
                        Text(zone.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(UIColor.tertiarySystemFill))
                    )
                }
                
                Spacer()
                
                Button(action: onConsume) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                        Text("Eat")
                            .font(.caption.bold())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(14)
        .frame(width: 240, height: 160)
        .appCard()
    }
}
