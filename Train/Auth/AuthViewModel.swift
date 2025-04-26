import Foundation
import SwiftUI
import AuthenticationServices

/// ViewModel for handling authentication-related UI logic
class AuthViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    /// Error message to display to the user
    @Published var errorMessage: String?
    
    /// Loading state during authentication
    @Published var isAuthenticating: Bool = false
    
    // MARK: - Dependencies
    
    /// User session to update after successful authentication
    private let userSession: UserSession
    
    /// Authentication manager for handling sign-in operations
    private lazy var authManager: AuthenticationManager = {
        let manager = AuthenticationManager(presentationContextProvider: self)
        
        // Configure callbacks
        manager.onAuthSuccess = { [weak self] userId in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.userSession.updateSession(userId: userId)
                self.isAuthenticating = false
                self.errorMessage = nil
            }
        }
        
        manager.onAuthError = { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.errorMessage = "Sign in failed: \(error.localizedDescription)"
                self.isAuthenticating = false
            }
        }
        
        manager.onAuthCanceled = { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Just reset the loading state, no error needed for cancellation
                self.isAuthenticating = false
            }
        }
        
        return manager
    }()
    
    // MARK: - Initialization
    
    /// Creates a new Auth view model
    /// - Parameter userSession: The user session to update
    init(userSession: UserSession) {
        self.userSession = userSession
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Initiates Apple Sign In process
    @MainActor
    func signInWithApple() async {
        isAuthenticating = true
        errorMessage = nil
        
        await authManager.signInWithApple()
    }
    
    /// Signs the user out
    func signOut() {
        authManager.signOut()
        userSession.clearSession()
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Find the active window to present from
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            // If we can't find a window, use the key window as fallback
            return UIApplication.shared.windows.first { $0.isKeyWindow } ?? UIWindow()
        }
        
        return window
    }
}
