import SwiftUI

/// Introduction to plan creation with options for creating a plan or skipping
struct PlanIntroView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    
    // Track which option the user selects
    @State private var selectedOption: PlanOption? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Text("Your Training Plan")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    
                Text("Dedset is built to help you stay consistent and make real progress")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 32)
            
            // Options cards
            VStack(spacing: 16) {
                // Adaptive Plan option
                PlanOptionCard(
                    icon: "figure.strengthtraining.traditional",
                    title: "Create Adaptive Plan",
                    description: "Answer a few questions and we'll build a plan designed just for you",
                    isSelected: selectedOption == .adaptive,
                    action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedOption = .adaptive
                        }
                        Task {
                            HapticService.shared.impact(style: .light)
                        }
                    }
                )
                
                // Custom Plan option
                PlanOptionCard(
                    icon: "slider.horizontal.3",
                    title: "Build Custom Plan",
                    description: "Start from scratch and create your own custom workout routine",
                    isSelected: selectedOption == .custom,
                    action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedOption = .custom
                        }
                        Task {
                            HapticService.shared.impact(style: .light)
                        }
                    }
                )
                
                // Skip option
                Button {
                    Task {
                        HapticService.shared.impact(style: .light)
                        viewModel.advanceToNextStep()
                        viewModel.advanceToNextStep() // Skip the plan builder step too
                    }
                } label: {
                    Text("Skip for now")
                        .font(AppStyle.Typography.body())
                        .foregroundColor(AppStyle.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppStyle.Colors.surfaceTop)
                        .cornerRadius(AppStyle.Layout.innerCardCornerRadius)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Continue button
            if selectedOption != nil {
                Button {
                    Task {
                        HapticService.shared.impact(style: .light)
                        
                        // In the future, we could route to different builders
                        viewModel.advanceToNextStep()
                    }
                } label: {
                    Text("Continue")
                        .font(AppStyle.Typography.headline())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppStyle.Colors.primary)
                        .cornerRadius(AppStyle.Layout.innerCardCornerRadius)
                        .padding(.horizontal)
                }
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppStyle.Colors.background)
    }
    
    // Plan creation options
    enum PlanOption {
        case adaptive
        case custom
    }
}

/// Card for plan options
struct PlanOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(AppStyle.Colors.surfaceTop)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? AppStyle.Colors.primary : AppStyle.Colors.textSecondary)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppStyle.Typography.headline())
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(isSelected ? AppStyle.Colors.primary : AppStyle.Colors.textPrimary)
                    
                    Text(description)
                        .font(AppStyle.Typography.caption())
                        .foregroundColor(AppStyle.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator - always reserve space
                ZStack {
                    // Invisible placeholder to reserve space
                    Image(systemName: "circle")
                        .font(.system(size: 20))
                        .foregroundColor(.clear)
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppStyle.Colors.primary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppStyle.Layout.innerCardCornerRadius)
                    .fill(isSelected ? AppStyle.Colors.primary.opacity(0.15) : AppStyle.Colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.Layout.innerCardCornerRadius)
                    .strokeBorder(isSelected ? AppStyle.Colors.primary : Color.clear, lineWidth: 2)
            )
            // Add subtle animation for selection
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#if DEBUG
struct PlanIntroView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        let userSessionManager = UserSessionManager()
        
        PlanIntroView()
            .environmentObject(OnboardingViewModel(appState: appState, userSessionManager: userSessionManager))
            .preferredColorScheme(.dark)
    }
}
#endif
