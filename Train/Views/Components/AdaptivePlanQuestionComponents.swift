import SwiftUI

// MARK: - UI Components for Adaptive Plan Questionnaire

/// Reusable components for the adaptive plan setup questionnaire
struct AdaptivePlanComponents {
    
    // MARK: - UI Styles
    
    /// Style for primary action buttons
    struct PrimaryButton: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppStyle.Colors.primary)
                .foregroundColor(.white)
                .cornerRadius(10)
                .opacity(configuration.isPressed ? 0.8 : 1)
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }
    
    /// Style for secondary action buttons
    struct SecondaryButton: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppStyle.Colors.surface)
                .foregroundColor(AppStyle.Colors.textPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppStyle.Colors.textSecondary.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(10)
                .opacity(configuration.isPressed ? 0.8 : 1)
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }
    
    // MARK: - Header Components
    
    /// Question header with title
    struct QuestionHeader: View {
        let title: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(AppStyle.Typography.title())
                    .foregroundColor(AppStyle.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Divider()
                    .background(AppStyle.Colors.textSecondary.opacity(0.3))
                    .padding(.bottom, 8)
            }
        }
    }
    
    /// Progress indicator for questionnaire
    struct ProgressBar: View {
        let current: Int
        let total: Int
        
        var body: some View {
            HStack(spacing: 4) {
                ForEach(0..<total, id: \.self) { index in
                    Rectangle()
                        .fill(index <= current ? AppStyle.Colors.primary : AppStyle.Colors.surface)
                        .frame(height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.3), value: current)
                }
            }
            .cornerRadius(2)
        }
    }
    
    // MARK: - Selection Components
    
    /// Option button with title and description
    struct OptionButton<T: Identifiable>: View where T: Equatable {
        let option: T
        let title: String
        let description: String
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(AppStyle.Typography.headline())
                            .foregroundColor(AppStyle.Colors.textPrimary)
                        
                        Text(description)
                            .font(AppStyle.Typography.caption())
                            .foregroundColor(AppStyle.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppStyle.Colors.primary)
                            .font(.system(size: 24))
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? 
                              AppStyle.Colors.surface.opacity(0.8) : 
                              AppStyle.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? 
                                        AppStyle.Colors.primary : 
                                        Color.clear, 
                                       lineWidth: 2)
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    /// Checkbox option for equipment selection
    struct CheckboxOption: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void
        let icon: String?
        
        init(title: String, isSelected: Bool, action: @escaping () -> Void, icon: String? = nil) {
            self.title = title
            self.isSelected = isSelected
            self.action = action
            self.icon = icon
        }
        
        var body: some View {
            Button(action: action) {
                HStack {
                    if let iconName = icon {
                        Image(systemName: iconName)
                            .foregroundColor(AppStyle.Colors.textPrimary)
                            .frame(width: 30)
                    }
                    
                    Text(title)
                        .font(AppStyle.Typography.body())
                        .foregroundColor(AppStyle.Colors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? AppStyle.Colors.primary : AppStyle.Colors.textSecondary)
                        .font(.system(size: 20))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? 
                              AppStyle.Colors.surface.opacity(0.8) : 
                              AppStyle.Colors.surface)
                )
                .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    /// Section for grouping selections with title
    struct SectionWithTitle<Content: View>: View {
        let title: String
        let content: Content
        
        init(title: String, @ViewBuilder content: () -> Content) {
            self.title = title
            self.content = content()
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(AppStyle.Typography.headline())
                    .foregroundColor(AppStyle.Colors.textPrimary)
                    .padding(.leading, 4)
                
                content
            }
            .padding(.bottom, 16)
        }
    }
    
    /// Navigation buttons row (back/next)
    struct NavigationButtons: View {
        let currentQuestion: Int
        let totalQuestions: Int
        let canProceed: Bool
        let onBack: () -> Void
        let onNext: () -> Void
        
        var body: some View {
            HStack {
                // Back button (hidden on first question)
                if currentQuestion > 0 {
                    Button(action: onBack) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                    .buttonStyle(SecondaryButton())
                }
                
                Spacer()
                
                // Next/Finish button
                Button(action: onNext) {
                    HStack {
                        Text(currentQuestion < totalQuestions - 1 ? "Next" : "Finish")
                        Image(systemName: currentQuestion < totalQuestions - 1 ? "chevron.right" : "checkmark")
                    }
                }
                .buttonStyle(PrimaryButton())
                .disabled(!canProceed)
                .opacity(canProceed ? 1.0 : 0.5)
            }
        }
    }
    
    /// Muscle group button with selection toggle
    struct MuscleButton: View {
        let muscle: MuscleGroup
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Circle()
                        .fill(muscle.color)
                        .frame(width: 12, height: 12)
                    
                    Text(muscle.displayName)
                        .font(AppStyle.Typography.body())
                        .foregroundColor(AppStyle.Colors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? AppStyle.Colors.primary : AppStyle.Colors.textSecondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? 
                              AppStyle.Colors.surface.opacity(0.8) : 
                              AppStyle.Colors.surface)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}
