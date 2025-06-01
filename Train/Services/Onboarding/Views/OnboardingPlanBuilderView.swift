import SwiftUI

/// Integrates with the existing plan builder during onboarding
struct OnboardingPlanBuilderView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @EnvironmentObject var appState: AppState
    @StateObject private var planMonitor = PlanMonitor()
    
    var body: some View {
        ZStack {
            // AdaptivePlanSetupView is the core plan creation view
            AdaptivePlanSetupView()
                // Use onAppear to setup monitoring for plan creation
                .onAppear {
                    // Store the initial plan ID or nil if no plan exists
                    planMonitor.initialPlanId = appState.currentPlan?.id
                    planMonitor.appState = appState
                    planMonitor.onPlanCreated = { plan in
                        viewModel.generatedPlan = plan
                        Task {
                            await HapticService.shared.success()
                            viewModel.advanceToNextStep()
                        }
                    }
                }
        }
        // Add a regular timer to check if plan has been created
        .onReceive(planMonitor.timer) { _ in
            planMonitor.checkForNewPlan()
        }
    }
}

/// Helper class to monitor AppState for plan creation
@MainActor
class PlanMonitor: ObservableObject {
    // State tracking
    var initialPlanId: UUID?
    weak var appState: AppState?
    
    // Callback when plan is created
    var onPlanCreated: ((TrainingPlanEntity) -> Void)?
    
    // Timer to check for plan creation without overriding navigation
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    /// Check if a new plan has been created
    @MainActor
    func checkForNewPlan() {
        guard let appState = appState,
              let currentPlan = appState.currentPlan else { return }
        
        // If plan ID has changed or new plan created when none existed before
        if let initialId = initialPlanId {
            if initialId != currentPlan.id {
                handleNewPlan(currentPlan)
            }
        } else if initialPlanId == nil {
            // First plan created
            handleNewPlan(currentPlan)
        }
    }
    
    /// Handle the new plan creation event
    @MainActor
    private func handleNewPlan(_ plan: TrainingPlanEntity) {
        // Only trigger once by setting initialPlanId to current
        initialPlanId = plan.id
        onPlanCreated?(plan)
    }
}

#if DEBUG
struct OnboardingPlanBuilderView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        let userSessionManager = UserSessionManager()
        
        OnboardingPlanBuilderView()
            .environmentObject(OnboardingViewModel(appState: appState, userSessionManager: userSessionManager))
            .environmentObject(appState)
    }
}
#endif
