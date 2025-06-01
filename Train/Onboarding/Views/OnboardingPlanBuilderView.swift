import SwiftUI

/// Integrates with the existing plan builder during onboarding
struct OnboardingPlanBuilderView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    
    var body: some View {
        // Reuse existing AdaptivePlanSetupView
        AdaptivePlanSetupView(
            isOnboarding: true,
            onComplete: { generatedPlan in
                viewModel.generatedPlan = generatedPlan
                
                Task {
                    await HapticService.shared.success()
                    viewModel.advanceToNextStep()
                }
            }
        )
    }
}

#if DEBUG
struct OnboardingPlanBuilderView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingPlanBuilderView()
            .environmentObject(OnboardingViewModel())
    }
}
#endif
