import SwiftUI
import Combine
import AuthenticationServices

/// Errors that can occur during the onboarding process
enum OnboardingError: Error, LocalizedError {
    case missingUserSessionManager
    case missingAppState
    
    var errorDescription: String? {
        switch self {
        case .missingUserSessionManager:
            return "UserSessionManager is required for onboarding completion"
        case .missingAppState:
            return "AppState is required for onboarding completion"
        }
    }
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var currentStep: OnboardingStep = .welcome
    @Published var user: UserEntity?
    @Published var marketingOptIn: Bool = true
    @Published var generatedPlan: TrainingPlanEntity?
    
    // MARK: - Dependencies
    let appState: AppState
    let userSessionManager: UserSessionManager
    
    // MARK: - Private Properties
    
    @AppStorage("isOnboardingCompleted") private var isOnboardingCompleted: Bool = false
    
    // MARK: - Initialization
    
    init(appState: AppState, userSessionManager: UserSessionManager) {
        self.appState = appState
        self.userSessionManager = userSessionManager
    }
    
    // MARK: - Navigation Methods
    
    func advanceToNextStep() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex + 1 < OnboardingStep.allCases.count else {
            completeOnboarding()
            return
        }
        
        withAnimation {
            currentStep = OnboardingStep.allCases[currentIndex + 1]
        }
        
        Task {
            HapticService.shared.impact(style: .medium)
        }
    }
    
    func goBack() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex > 0 else {
            return
        }
        
        withAnimation {
            currentStep = OnboardingStep.allCases[currentIndex - 1]
        }
    }
    
    /// Navigates to a specific step in the onboarding flow
    /// - Parameter step: The step to navigate to
    func navigateToStep(_ step: OnboardingStep) {
        withAnimation {
            currentStep = step
        }
        
        Task {
            HapticService.shared.impact(style: .medium)
        }
    }
    
    func completeOnboarding() {
        guard let currentUser = user else { return }
        
        // Create a mutable copy of the user with updated preferences
        var updatedUser = currentUser
        updatedUser.marketingOptIn = marketingOptIn
        
        // Set completion flag
        isOnboardingCompleted = true
        
        // Now we can directly use the injected AppState
        Task { @MainActor in
            do {
                // Pass the UserSessionManager to the finalizeOnboarding method
                try await appState.finalizeOnboarding(
                    user: updatedUser,
                    plan: generatedPlan,
                    marketingOptIn: marketingOptIn,
                    userSessionManager: userSessionManager
                )
                
                HapticService.shared.success()
            } catch {
                // Handle error if needed
                print("Error finalizing onboarding: \(error)")
            }
        }
    }
    
    // The continuation-based methods have been removed in favor of direct dependency injection
    
    #if DEBUG
    func resetOnboarding() {
        isOnboardingCompleted = false
        user = nil
        marketingOptIn = true
        generatedPlan = nil
        currentStep = .welcome
    }
    #endif
}

// MARK: - Onboarding Steps

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case signIn
    case nameSetup      // Re-added step for name collection
    case usernameSetup
    case marketingOptIn
    case planIntro
    case planBuilder
    case completion
    
    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .signIn: return "Sign In"
        case .nameSetup: return "Your Profile"
        case .usernameSetup: return "Create Username"
        case .marketingOptIn: return "Preferences"
        case .planIntro: return "Training Plan"
        case .planBuilder: return "Create Your Plan"
        case .completion: return "You're All Set!"
        }
    }
}
