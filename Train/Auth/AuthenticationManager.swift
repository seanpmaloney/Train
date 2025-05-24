import Foundation
import AuthenticationServices

/// Manages authentication operations and state
@MainActor
class AuthenticationManager: NSObject {
    // MARK: - Properties
    
    /// Callback for when authentication succeeds with a user ID
    var onAuthSuccess: ((String) -> Void)?
    
    /// Callback for when authentication fails with an error
    var onAuthError: ((Error) -> Void)?
    
    /// Callback for when authentication is canceled by the user
    var onAuthCanceled: (() -> Void)?
    
    /// Current view controller for presenting the sign-in UI
    private weak var presentationContextProvider: ASAuthorizationControllerPresentationContextProviding?
    
    // MARK: - Initialization
    
    /// Creates a new authentication manager
    /// - Parameter presentationContextProvider: The provider of presentation context for auth UI
    init(presentationContextProvider: ASAuthorizationControllerPresentationContextProviding) {
        self.presentationContextProvider = presentationContextProvider
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Starts the Apple Sign In process
    func signInWithApple() async {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        
        // Present the sign in UI
        return await withCheckedContinuation { continuation in
            // Set up a one-time handler to capture the continuation
            let completionHandler = { continuation.resume() }
            
            // Capture self and controller weakly to avoid data races
            self.onceAuthenticationCompletes(perform: completionHandler)
            
            // Set delegates and perform requests on the main actor
            controller.delegate = self
            controller.presentationContextProvider = self.presentationContextProvider
            controller.performRequests()
        }
    }
    
    /// Checks if a user is currently signed in
    /// - Returns: Boolean indicating if user is signed in
    nonisolated func isUserSignedIn() -> Bool {
        return getUserId() != nil
    }
    
    /// Retrieves the stored user ID
    /// - Returns: User ID if available, nil otherwise
    nonisolated func getUserId() -> String? {
        return UserDefaults.standard.string(forKey: "userId")
    }
    
    /// Signs the user out by clearing stored credentials
    nonisolated func signOut() {
        UserDefaults.standard.removeObject(forKey: "userId")
    }
    
    // MARK: - Private Methods
    
    /// Stores the user ID securely in UserDefaults
    /// - Parameter userId: The Apple user identifier to store
    private nonisolated func storeUserId(_ userId: String) {
        UserDefaults.standard.set(userId, forKey: "userId")
    }
    
    /// Sets up a one-time execution of the given action when authentication completes
    /// - Parameter action: Action to perform when authentication completes
    private func onceAuthenticationCompletes(perform action: @escaping () -> Void) {
        let originalOnSuccess = onAuthSuccess
        let originalOnError = onAuthError
        let originalOnCanceled = onAuthCanceled
        
        // Create wrapped handlers that call the original ones and then the provided action
        onAuthSuccess = { userId in
            originalOnSuccess?(userId)
            action()
            self.onAuthSuccess = originalOnSuccess
            self.onAuthError = originalOnError
            self.onAuthCanceled = originalOnCanceled
        }
        
        onAuthError = { error in
            originalOnError?(error)
            action()
            self.onAuthSuccess = originalOnSuccess
            self.onAuthError = originalOnError
            self.onAuthCanceled = originalOnCanceled
        }
        
        onAuthCanceled = {
            originalOnCanceled?()
            action()
            self.onAuthSuccess = originalOnSuccess
            self.onAuthError = originalOnError
            self.onAuthCanceled = originalOnCanceled
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

@MainActor
extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        // Handle successful authorization
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
           let userIdentifier = appleIDCredential.user as? String {
            // Store user ID
            storeUserId(userIdentifier)
            
            // Call success callback
            onAuthSuccess?(userIdentifier)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle auth errors
        if let authError = error as? ASAuthorizationError {
            if authError.code == .canceled {
                // User canceled the authorization
                onAuthCanceled?()
                return
            }
        }
        
        // Other errors
        onAuthError?(error)
    }
}
