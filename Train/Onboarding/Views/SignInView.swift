import SwiftUI
import AuthenticationServices

/// Sign In view that handles Apple Sign In
struct SignInView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Sign in to Train")
                .font(AppStyle.Typography.title())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            Text("Your workouts will be securely saved and synced across your devices.")
                .font(AppStyle.Typography.body())
                .foregroundColor(AppStyle.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            SignInWithAppleButton(
                .signIn,
                onRequest: configureRequest,
                onCompletion: handleSignInCompletion
            )
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
        .padding()
        .alert("Sign In Failed", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.email]
    }
    
    private func handleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential {
                let userId = appleIDCredential.user
                let email = appleIDCredential.email ?? ""
                
                // Extract name if provided
                var displayName: String? = nil
                if let firstName = appleIDCredential.fullName?.givenName,
                   let lastName = appleIDCredential.fullName?.familyName {
                    displayName = "\(firstName) \(lastName)"
                }
                
                // Create user entity
                let user = UserEntity(
                    id: userId,
                    email: email,
                    displayName: displayName
                )
                
                // Update view model and proceed
                viewModel.user = user
                
                Task {
                    await HapticService.shared.impact(style: .medium)
                    viewModel.advanceToNextStep()
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingError = true
            
            Task {
                await HapticService.shared.error()
            }
        }
    }
}

#if DEBUG
struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .environmentObject(OnboardingViewModel())
    }
}
#endif
