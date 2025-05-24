import SwiftUI
import AuthenticationServices

/// A button that initiates Sign in with Apple
struct AppleSignInButton: View {
    /// Action to perform when sign in is successful
    var action: () async -> Void
    
    var body: some View {
        SignInWithAppleButton(
            .signIn,
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                switch result {
                case .success:
                    Task {
                        await action()
                    }
                case .failure(let error):
                    print("Apple sign in failed: \(error.localizedDescription)")
                }
            }
        )
        .frame(height: 50)
        .cornerRadius(8)
    }
}

#Preview {
    AppleSignInButton {
        print("Sign in completed")
    }
    .padding()
    .previewLayout(.sizeThatFits)
}
