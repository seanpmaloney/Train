import SwiftUI
import AuthenticationServices

/// View for handling user authentication
struct AuthView: View {
    // MARK: - Properties
    
    @ObservedObject var viewModel: AuthViewModel
    @ObservedObject var userSession: UserSession
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 24) {
            // Only show sign-in UI if not already signed in
            if !userSession.isSignedIn {
                welcomeSection
                
                Spacer()
                
                signInButton
                
                // Error message if present
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(AppStyle.Colors.danger)
                        .font(AppStyle.Typography.body())
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            } else {
                // Show signed-in state
                VStack(spacing: 24) {
                    Text("You're signed in")
                        .font(AppStyle.Typography.title())
                        .foregroundColor(AppStyle.Colors.textPrimary)
                    
                    Button(action: {
                        viewModel.signOut()
                    }) {
                        Text("Sign Out")
                            .font(AppStyle.Typography.headline())
                            .foregroundColor(AppStyle.Colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppStyle.Colors.danger)
                            .cornerRadius(AppStyle.Layout.innerCardCornerRadius)
                    }
                    .padding(.horizontal, 32)
                }
                .padding(32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppStyle.Colors.background.ignoresSafeArea())
    }
    
    // MARK: - Components
    
    /// Welcome section with title and subtitle
    private var welcomeSection: some View {
        VStack(spacing: 16) {
            Text("Welcome to Train")
                .font(AppStyle.Typography.title())
                .foregroundColor(AppStyle.Colors.textPrimary)
            
            Text("Sign in to track your workout progress and access your training plans from anywhere.")
                .font(AppStyle.Typography.body())
                .foregroundColor(AppStyle.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 48)
    }
    
    /// Sign in with Apple button
    private var signInButton: some View {
        SignInWithAppleButton(
            .signIn,
            onRequest: { request in
                // Configure the request
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                Task {
                    await handleSignInCompletion(result)
                }
            }
        )
        .signInWithAppleButtonStyle(.white)
        .frame(height: 56)
        .padding(.horizontal, 32)
        .disabled(viewModel.isAuthenticating)
        .overlay(
            Group {
                if viewModel.isAuthenticating {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                }
            }
        )
    }
    
    // MARK: - Helper Methods
    
    /// Handles the completion of the Sign in with Apple process
    /// - Parameter result: The result of the sign-in attempt
    @MainActor
    private func handleSignInCompletion(_ result: Result<ASAuthorization, Error>) async {
        // Forward to view model
        await viewModel.signInWithApple()
    }
}

#Preview {
    let userSession = UserSession()
    let viewModel = AuthViewModel(userSession: userSession)
    
    return AuthView(viewModel: viewModel, userSession: userSession)
}
