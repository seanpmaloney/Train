import SwiftUI
import Combine
import AuthenticationServices

@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Dependencies
    
    /// User session manager for authentication operations
    let userSessionManager: UserSessionManager
    // MARK: - Published Properties
    
    @Published private(set) var currentStep: OnboardingStep = .welcome
    @Published var user: UserEntity?
    @Published var marketingOptIn: Bool = true
    @Published var generatedPlan: TrainingPlanEntity?
    
    // MARK: - Private Properties
    
    @AppStorage("isOnboardingCompleted") private var isOnboardingCompleted: Bool = false
    
    // MARK: - Initialization
    
    init(userSessionManager: UserSessionManager = UserSessionManager()) {
        self.userSessionManager = userSessionManager
    }
    
    // MARK: - Navigation Methods
    
    func advanceToNextStep() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex + 1 < OnboardingStep.allCases.count else {
            completeOnboarding()
            return
        }
        
        // Determine the next step
        let nextStep: OnboardingStep
        
        // If we're at sign-in and moving to name setup, check if we already have names from Apple
        if currentStep == .signIn && 
           OnboardingStep.allCases[currentIndex + 1] == .usernameSetup && 
           user?.firstName != nil && 
           !(user?.firstName?.isEmpty ?? true) {
            // Skip name setup since we already have first name from Apple Sign-In
            nextStep = OnboardingStep.allCases[currentIndex + 2]
        } else {
            // Normal progression
            nextStep = OnboardingStep.allCases[currentIndex + 1]
        }
        
        withAnimation {
            currentStep = nextStep
        }
        
        Task {
            await HapticService.shared.impact(style: .medium)
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
    
    func completeOnboarding() {
        guard let user = user else { return }
        
        // Update marketing preferences
        user.marketingOptIn = marketingOptIn
        
        // Set completion flag
        isOnboardingCompleted = true
        
        // Notify AppState
        Task {
            do {
                try await AppState.shared.finalizeOnboarding(
                    user: user,
                    plan: generatedPlan,
                    marketingOptIn: marketingOptIn,
                    userSessionManager: userSessionManager
                )
                
                await HapticService.shared.success()
            } catch {
                // Handle error if needed
                print("Error finalizing onboarding: \(error)")
            }
        }
    }
    
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
    case usernameSetup
    case marketingOptIn
    case planBuilder
    case completion
    
    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .signIn: return "Sign In"
        case .usernameSetup: return "Create Username"
        case .marketingOptIn: return "Preferences"
        case .planBuilder: return "Create Your Plan"
        case .completion: return "You're All Set!"
        }
    }
}
