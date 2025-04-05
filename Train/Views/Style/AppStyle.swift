import SwiftUI

enum AppStyle {
    enum Colors {
        static let background = Color(hex: "#0F1115")    // Main background
        static let surface = Color(hex: "#1A1C20")       // Card surface
        static let primary = Color(hex: "#00B4D8")       // Primary accent
        static let secondary = Color(hex: "#FFD166")     // Secondary accent
        static let success = Color(hex: "#06D6A0")       // Success/completion
        static let danger = Color(hex: "#EF476F")        // Danger/warning
        static let textPrimary = Color.white             // Primary text
        static let textSecondary = Color(hex: "#B0B0B0") // Secondary text
    }
    
    enum Layout {
        static let cardCornerRadius: CGFloat = 16
        static let innerCardCornerRadius: CGFloat = 12
        static let cardPadding: CGFloat = 16
        static let standardSpacing: CGFloat = 16
        static let compactSpacing: CGFloat = 8
    }
    
    enum Typography {
        static func title() -> Font {
            .system(.title2, design: .rounded, weight: .bold)
        }
        
        static func headline() -> Font {
            .system(.headline, design: .rounded, weight: .semibold)
        }
        
        static func body() -> Font {
            .system(.body, design: .rounded)
        }
        
        static func caption() -> Font {
            .system(.caption, design: .rounded)
        }
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppStyle.Layout.cardPadding)
            .background(AppStyle.Colors.surface)
            .cornerRadius(AppStyle.Layout.cardCornerRadius)
    }
}

struct InnerCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppStyle.Layout.cardPadding)
            .background(AppStyle.Colors.background)
            .cornerRadius(AppStyle.Layout.innerCardCornerRadius)
    }
}

struct PrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: AppStyle.Layout.innerCardCornerRadius)
                    .fill(AppStyle.Colors.primary)
                    .opacity(configuration.isPressed ? 0.8 : 1)
            )
            .foregroundColor(.white)
            .font(AppStyle.Typography.headline())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: AppStyle.Layout.innerCardCornerRadius)
                    .stroke(AppStyle.Colors.primary, lineWidth: 1.5)
            )
            .foregroundColor(AppStyle.Colors.primary)
            .font(AppStyle.Typography.headline())
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardBackground())
    }
    
    func innerCardStyle() -> some View {
        modifier(InnerCardBackground())
    }
}
