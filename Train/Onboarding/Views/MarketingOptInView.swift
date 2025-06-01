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
            
            Toggle(isOn: $viewModel.marketingOptIn) {
                Text("I'd like to receive occasional training insights & updates")
                    .font(AppStyle.Typography.body())
                    .foregroundColor(AppStyle.Colors.textPrimary)
            }
            .padding()
            .background(AppStyle.Colors.surface)
            .cornerRadius(8)
            .padding(.horizontal)
            
            Spacer()
            
            Button {
                Task {
                    await HapticService.shared.impact(style: .medium)
                    viewModel.advanceToNextStep()
                }
            } label: {
                Text("Continue")
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
        .padding()
    }
}

#if DEBUG
struct MarketingOptInView_Previews: PreviewProvider {
    static var previews: some View {
        MarketingOptInView()
            .environmentObject(OnboardingViewModel())
    }
}
#endif
