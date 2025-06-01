import SwiftUI

/// Welcome screen that introduces the app to new users
struct WelcomeView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var logoVisible = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App logo with animation
            Image("WelcomeScreenLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .opacity(logoVisible ? 1 : 0)
                .offset(y: logoVisible ? 0 : -40)
                .animation(.easeOut(duration: 0.6), value: logoVisible)
            
            VStack(spacing: 16) {
                Text("Welcome to Dedset")
                    .font(AppStyle.Typography.title())
                    .foregroundColor(AppStyle.Colors.textPrimary)
                    .opacity(logoVisible ? 1 : 0)
                    .offset(y: logoVisible ? 0 : -40)
                    .animation(.easeOut(duration: 0.6), value: logoVisible)
                
                Text("Build smarter workouts. Track real progress.")
                    .font(AppStyle.Typography.body())
                    .foregroundColor(AppStyle.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .opacity(logoVisible ? 1 : 0)
                    .offset(y: logoVisible ? 0 : -40)
                    .animation(.easeOut(duration: 0.6), value: logoVisible)
            }
            
            Spacer()
            
            Button {
                viewModel.advanceToNextStep()
            } label: {
                Text("Get Started")
                    .font(AppStyle.Typography.body())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppStyle.Colors.primary)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .task {
            logoVisible = true
        }
    }
}

#if DEBUG
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        let userSessionManager = UserSessionManager()
        
        WelcomeView()
            .environmentObject(OnboardingViewModel(appState: appState, userSessionManager: userSessionManager))
    }
}
#endif
