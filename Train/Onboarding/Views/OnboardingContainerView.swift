import SwiftUI

/// Container view that manages the overall onboarding flow
struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppStyle.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator (only show after welcome)
                    if viewModel.currentStep != .welcome {
                        ProgressBar(
                            currentStep: OnboardingStep.allCases.firstIndex(of: viewModel.currentStep) ?? 0,
                            totalSteps: OnboardingStep.allCases.count - 1 // Exclude welcome from count
                        )
                        .padding(.top)
                    }
                    
                    // Step content
                    stepContent
                        .transition(.opacity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(viewModel.currentStep.title)
            .navigationBarHidden(viewModel.currentStep == .welcome)
            #if DEBUG
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        viewModel.resetOnboarding()
                    }
                    .font(.caption)
                    .foregroundColor(AppStyle.Colors.textSecondary)
                }
            }
            #endif
        }
        .environmentObject(viewModel)
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .welcome:
            WelcomeView()
        case .signIn:
            SignInView()
        case .usernameSetup:
            UsernameSetupView()
        case .marketingOptIn:
            MarketingOptInView()
        case .planBuilder:
            OnboardingPlanBuilderView()
        case .completion:
            CompletionView()
        }
    }
}

// MARK: - Progress Bar

/// Reusable progress bar for the onboarding flow
struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Rectangle()
                    .fill(step <= currentStep ? AppStyle.Colors.primary : AppStyle.Colors.surface)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal)
    }
}

#if DEBUG
struct OnboardingContainerView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingContainerView()
            .environmentObject(AppState.shared)
    }
}
#endif
