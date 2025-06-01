import SwiftUI
import Combine
import AuthenticationServices

@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var currentStep: OnboardingStep = .welcome
    @Published var user: UserEntity?
    @Published var marketingOptIn: Bool = true
    @Published var generatedPlan: TrainingPlanEntity?
    
    // MARK: - Private Properties
    
    @AppStorage("isOnboardingCompleted") private var isOnboardingCompleted: Bool = false
    
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
                    marketingOptIn: marketingOptIn
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
