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
                .foregroundColor(.green)
            
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
                        HapticService.shared.success()
                        
                        // Complete onboarding - now the ViewModel already has direct access to AppState
                        viewModel.completeOnboarding()
                        
                        // Navigate to first workout if available
                        if let firstWorkout = appState.currentPlan?.weeklyWorkouts.first?.first {
                            appState.activeWorkout = firstWorkout
                            appState.activeWorkoutId = firstWorkout.id
                        }
                    }
                } label: {
                    Text("Start Your First Workout")
                        .font(AppStyle.Typography.headline())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppStyle.Colors.primary)
                        .cornerRadius(AppStyle.Layout.innerCardCornerRadius)
                }
                .simultaneousGesture(TapGesture().onEnded { _ in
                    HapticService.shared.impact(style: .medium)
                })
                
                Button {
                    Task {
                        HapticService.shared.impact(style: .light)
                        
                        // Complete onboarding - ViewModel now has direct access to AppState
                        viewModel.completeOnboarding()
                    }
                } label: {
                    Text("Explore Dashboard")
                        .font(AppStyle.Typography.headline())
                        .foregroundColor(AppStyle.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppStyle.Colors.surfaceTop)
                        .cornerRadius(AppStyle.Layout.innerCardCornerRadius)
                }
                .simultaneousGesture(TapGesture().onEnded { _ in
                    HapticService.shared.impact(style: .light)
                })
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

#if DEBUG
struct CompletionView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        let userSessionManager = UserSessionManager()
        
        CompletionView()
            .environmentObject(OnboardingViewModel(appState: appState, userSessionManager: userSessionManager))
            .environmentObject(appState)
    }
}
#endif
