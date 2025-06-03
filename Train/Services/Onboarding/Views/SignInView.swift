import SwiftUI
import AuthenticationServices
import Firebase
import FirebaseAuth

/// Sign In view that handles Apple Sign In using the centralized AuthService
struct SignInView: View {
    // MARK: - Dependencies and State
    @EnvironmentObject var viewModel: OnboardingViewModel
    @EnvironmentObject var appState: AppState
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Sign in to Dedset")
                .font(AppStyle.Typography.title())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            Text("Your workouts will be securely saved and synced across your devices.")
                .font(AppStyle.Typography.body())
                .foregroundColor(AppStyle.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if isLoading {
                ProgressView()
                    .frame(height: 50)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
            } else {
                // Use SignInWithAppleButton with our existing UserSessionManager
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        // Let AppleAuthService handle the request configuration
                        viewModel.userSessionManager.configureAppleRequest(request)
                    },
                    onCompletion: { result in
                        Task {
                            await self.handleAppleSignIn(result)
                        }
                    }
                )
                // The button has its own presentation context handling
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
        }
        .padding()
        .alert("Sign In Failed", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Handle Apple authorization result
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        defer { isLoading = false }
        
        // Delegate to UserSessionManager to handle the sign-in with properly injected AppState
        let error = await viewModel.userSessionManager.handleAppleSignInResult(result, appState: appState)
        
        if let error = error {
            if case AuthError.signInCanceled = error {
                // User canceled, no need to show an error
                return
            }
            showError(message: error.localizedDescription)
        } else {
            // Authentication successful - get the current user from UserSessionManager
            if let currentUser = viewModel.userSessionManager.currentUser {
                // Update the OnboardingViewModel with the user
                viewModel.user = currentUser
                
                // Advance to next onboarding step
                viewModel.advanceToNextStep()
            } else {
                showError(message: "Failed to retrieve user after authentication")
            }
        }
    }
    
    /// Show an error message to the user
    private func showError(message: String) {
        self.errorMessage = message
        self.showingError = true
    }
}

#if DEBUG
struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .environmentObject(OnboardingViewModel(appState: AppState(), userSessionManager: UserSessionManager()))
    }
}
#endif
