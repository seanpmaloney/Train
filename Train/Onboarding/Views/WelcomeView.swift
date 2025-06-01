import SwiftUI

/// Welcome screen that introduces the app to new users
struct WelcomeView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App logo
            Image("AppLogo") // Replace with your actual logo
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
            
            VStack(spacing: 16) {
                Text("Welcome to Train")
                    .font(AppStyle.Typography.largeTitle())
                    .foregroundColor(AppStyle.Colors.textPrimary)
                
                Text("Build smarter workouts. Track real progress.")
                    .font(AppStyle.Typography.title3())
                    .foregroundColor(AppStyle.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button {
                viewModel.advanceToNextStep()
            } label: {
                Text("Get Started")
                    .font(AppStyle.Typography.button())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppStyle.Colors.primary)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

#if DEBUG
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .environmentObject(OnboardingViewModel())
    }
}
#endif
