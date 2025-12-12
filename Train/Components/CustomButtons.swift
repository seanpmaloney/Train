import SwiftUI

// MARK: - Custom Button Components

struct CustomPrimaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ? AppStyle.Colors.primary : AppStyle.Colors.textSecondary.opacity(0.3))
            )
        }
        .disabled(!isEnabled || isLoading)
    }
}

struct CustomSecondaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isEnabled ? AppStyle.Colors.textPrimary : AppStyle.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppStyle.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppStyle.Colors.surface.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .disabled(!isEnabled)
    }
}

struct CustomTertiaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isEnabled ? AppStyle.Colors.textSecondary : AppStyle.Colors.textSecondary.opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
        .disabled(!isEnabled)
    }
}

struct CustomIconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 44
    var iconSize: CGFloat = 20
    var backgroundColor: Color = AppStyle.Colors.surface
    var foregroundColor: Color = AppStyle.Colors.textPrimary
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(foregroundColor)
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: size / 4)
                        .fill(backgroundColor)
                )
        }
    }
}

struct CustomNavigationButton: View {
    let title: String
    let destination: AnyView
    var isEnabled: Bool = true
    
    var body: some View {
        NavigationLink(destination: destination) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isEnabled ? AppStyle.Colors.textPrimary : AppStyle.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppStyle.Colors.surface)
                )
        }
        .disabled(!isEnabled)
    }
}

struct CustomBackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                Text("Back")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(AppStyle.Colors.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppStyle.Colors.surface.opacity(0.5))
            )
        }
    }
}

struct CustomCloseButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppStyle.Colors.textSecondary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(AppStyle.Colors.surface.opacity(0.5))
                )
        }
    }
}

// MARK: - Button Modifiers

extension View {
    func customButtonStyle() -> some View {
        self.buttonStyle(CustomButtonStyle())
    }
}

struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        CustomPrimaryButton(title: "Primary Button") {
            print("Primary tapped")
        }
        
        CustomSecondaryButton(title: "Secondary Button") {
            print("Secondary tapped")
        }
        
        CustomTertiaryButton(title: "Tertiary Button") {
            print("Tertiary tapped")
        }
        
        HStack {
            CustomIconButton(icon: "gear") {
                print("Settings tapped")
            }
            
            CustomIconButton(icon: "plus") {
                print("Add tapped")
            }
            
            CustomCloseButton {
                print("Close tapped")
            }
        }
        
        CustomBackButton {
            print("Back tapped")
        }
    }
    .padding()
    .background(AppStyle.Colors.background)
}
