import SwiftUI
import AuthenticationServices

/// Sign In view that handles Apple Sign In
struct SignInView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Let's get you signed up")
                .font(AppStyle.Typography.title())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            Text("Your workouts will be securely saved and synced across your devices.")
                .font(AppStyle.Typography.body())
                .foregroundColor(AppStyle.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            SignInWithAppleButton(
                .signUp,
                onRequest: handleAuthorizationAppleIDButtonPress,
                onCompletion: handleAppleIdCredential
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
    
    /// Handles Apple ID authorization button press action
    private func handleAuthorizationAppleIDButtonPress(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }
    
    private func handleAppleIdCredential(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userId = appleIDCredential.user
                let email = appleIDCredential.email ?? ""
                
                // Extract name information if provided
                let firstName = appleIDCredential.fullName?.givenName
                let lastName = appleIDCredential.fullName?.familyName
                
                var displayName: String? = nil
                if let firstName = firstName, let lastName = lastName {
                    displayName = "\(firstName) \(lastName)"
                } else if let firstName = firstName {
                    displayName = firstName
                } else if let lastName = lastName {
                    displayName = lastName
                } else {
                    displayName = nil
                }
                
                print("Apple credential received - User ID: \(userId), Name: \(displayName ?? "Not provided"), Email: \(email.isEmpty ? "Not provided" : email)")
                
                // Create user entity
                let user = UserEntity(
                    id: userId,
                    email: email,
                    displayName: displayName,
                    firstName: firstName,
                    lastName: lastName
                )
                
                // Set the user in view model
                viewModel.user = user
                
                // Immediately save to AppState for persistence
                viewModel.appState.updateUser(user)
                viewModel.appState.savePlans()
                print("Saved Apple Sign In user to AppState during onboarding")
                
                // Update session manager
                viewModel.userSessionManager.signInWithUser(user, appState: viewModel.appState)
                
                // Provide haptic feedback
                Task {
                    HapticService.shared.impact(style: .medium)
                    
                    if displayName == nil || displayName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
                        print("No name provided by Apple, going to nameSetup step")
                        viewModel.navigateToStep(.nameSetup)
                    } else {
                        print("Name provided by Apple: \(displayName ?? "None"), skipping nameSetup")
                        viewModel.navigateToStep(.usernameSetup)
                    }
                }
            }

        case .failure(let error):
            print("Apple Sign In failed: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            self.showingError = true
        }
    }
}

#if DEBUG
struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        let userSessionManager = UserSessionManager()
        
        SignInView()
            .environmentObject(OnboardingViewModel(appState: appState, userSessionManager: userSessionManager))
    }
}
#endif
