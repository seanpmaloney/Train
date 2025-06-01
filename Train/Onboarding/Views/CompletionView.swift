import SwiftUI

/// Final screen of the onboarding flow
struct CompletionView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(AppStyle.Colors.success)
            
            VStack(spacing: 16) {
                Text("You're All Set!")
                    .font(AppStyle.Typography.title())
                    .foregroundColor(AppStyle.Colors.textPrimary)
                
                Text("Your plan is ready. Time to start your first workout!")
                    .font(AppStyle.Typography.body())
                    .foregroundColor(AppStyle.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button {
                    Task {
                        await HapticService.shared.success()
                        viewModel.completeOnboarding()
                        
                        // Navigate to first workout if available
                        if let firstWorkout = appState.currentPlan?.workouts.first {
                            appState.selectedWorkout = firstWorkout
                            appState.currentTab = .workout
                        }
                    }
                } label: {
                    Text("Start Your First Workout")
                        .font(AppStyle.Typography.button())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppStyle.Colors.primary)
                        .cornerRadius(8)
                }
                
                Button {
                    Task {
                        await HapticService.shared.impact(style: .light)
                        viewModel.completeOnboarding()
                        appState.currentTab = .dashboard
                    }
                } label: {
                    Text("Explore Dashboard")
                        .font(AppStyle.Typography.button())
                        .foregroundColor(AppStyle.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppStyle.Colors.surface)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

#if DEBUG
struct CompletionView_Previews: PreviewProvider {
    static var previews: some View {
        CompletionView()
            .environmentObject(OnboardingViewModel())
            .environmentObject(AppState.shared)
    }
}
#endif
