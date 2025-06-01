import SwiftUI

/// View for marketing preferences during onboarding
struct MarketingOptInView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Stay Updated")
                .font(AppStyle.Typography.title())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            Text("We'll send occasional training insights and app updates to help you reach your goals.")
                .font(AppStyle.Typography.body())
                .foregroundColor(AppStyle.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Custom toggle with stable layout
            HStack(spacing: 12) {
                Text("I'd like to receive occasional training insights & updates")
                    .font(AppStyle.Typography.body())
                    .foregroundColor(AppStyle.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer(minLength: 8)
                
                // Toggle with fixed layout
                Toggle("", isOn: $viewModel.marketingOptIn)
                    .labelsHidden()
                    .frame(width: 51) // Fixed width for the toggle
            }
            .padding()
            .background(AppStyle.Colors.surfaceTop)
            .cornerRadius(AppStyle.Layout.innerCardCornerRadius)
            .padding(.horizontal)
            
            Spacer()
            
            Button {
                Task {
                    HapticService.shared.impact(style: .medium)
                    viewModel.advanceToNextStep()
                }
            } label: {
                Text("Continue")
                    .font(AppStyle.Typography.headline())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppStyle.Colors.primary)
                    .cornerRadius(AppStyle.Layout.innerCardCornerRadius)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .padding()
    }
}

#if DEBUG
struct MarketingOptInView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        let userSessionManager = UserSessionManager()
        
        MarketingOptInView()
            .environmentObject(OnboardingViewModel(appState: appState, userSessionManager: userSessionManager))
    }
}
#endif
