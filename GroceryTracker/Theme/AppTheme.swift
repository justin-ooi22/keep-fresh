import SwiftUI

/// App design tokens and styling helpers supporting both Light and Dark mode.
public enum AppTheme {
    // MARK: - Semantic Accent Colors
    public static let primaryGreen = Color(red: 0.18, green: 0.80, blue: 0.44)
    public static let primaryOrange = Color(red: 1.00, green: 0.58, blue: 0.00)
    public static let primaryRed = Color(red: 1.00, green: 0.27, blue: 0.23)
    public static let brandTeal = Color(red: 0.00, green: 0.75, blue: 0.75)
    
    // MARK: - Adaptive Backgrounds
    public static var cardBackground: Color {
        Color(UIColor.secondarySystemGroupedBackground)
    }
    
    public static var secondaryCardBackground: Color {
        Color(UIColor.tertiarySystemGroupedBackground)
    }
    
    public static var screenBackground: Color {
        Color(UIColor.systemGroupedBackground)
    }
}

// MARK: - View Modifiers
public struct AppCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 16
    
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.cardBackground)
                    .shadow(
                        color: colorScheme == .dark
                            ? Color.black.opacity(0.3)
                            : Color.black.opacity(0.06),
                        radius: 8,
                        x: 0,
                        y: 3
                    )
            )
    }
}

public struct StatusBadgeModifier: ViewModifier {
    var status: ExpiryStatus
    
    public func body(content: Content) -> some View {
        content
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(status.color.opacity(0.18))
            )
            .foregroundColor(status.color)
    }
}

extension View {
    /// Applies standard rounded elevated card styling with adaptive shadows
    public func appCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(AppCardModifier(cornerRadius: cornerRadius))
    }
    
    /// Applies traffic-light colored status badge styling
    public func statusBadge(for status: ExpiryStatus) -> some View {
        modifier(StatusBadgeModifier(status: status))
    }
}
