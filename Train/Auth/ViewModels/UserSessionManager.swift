import Foundation
import SwiftUI
import Combine

/// Central coordinator for authentication state
@MainActor
class UserSessionManager: ObservableObject {
    /// Current authenticated user
    @Published private(set) var currentUser: UserEntity?
    
    /// Current authentication state
    @Published private(set) var authState: AuthState = .unknown
    
    /// Authentication state enum
    enum AuthState: Equatable {
        /// Authentication state is unknown
        case unknown
        
        /// User is authenticated
        case authenticated
        
        /// User is not authenticated
        case unauthenticated
        
        /// Authentication error occurred
        case error(AuthError)
        
        static func == (lhs: UserSessionManager.AuthState, rhs: UserSessionManager.AuthState) -> Bool {
            switch (lhs, rhs) {
            case (.unknown, .unknown), (.authenticated, .authenticated), (.unauthenticated, .unauthenticated):
                return true
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }
    
    // Dependencies
    private let authService: AuthService
    private var cancellables = Set<AnyCancellable>()
    
    /// Initialize with dependencies
    /// - Parameter authService: Service for authentication operations
    init(authService: AuthService = FirebaseAuthService()) {
        self.authService = authService
        
        // Check for existing user on init
        Task {
            await checkAuthState()
        }
    }
    
    /// Sign in with Apple
    func signInWithApple() async {
        do {
            // Since we're already in a MainActor context, we can safely call the authService
            let user = try await authService.signInWithApple()
            self.currentUser = user
            self.authState = .authenticated
            
            // In a real implementation, we would also check subscription status here
            // await subscriptionService.refreshSubscriptionStatus()
        } catch let error as AuthError {
            self.authState = .error(error)
        } catch {
            self.authState = .error(.unknown(message: error.localizedDescription))
        }
    }
    
    /// Sign out the current user
    func signOut() async {
        do {
            try await authService.signOut()
            self.currentUser = nil
            self.authState = .unauthenticated
        } catch let error as AuthError {
            self.authState = .error(error)
        } catch {
            self.authState = .error(.unknown(message: error.localizedDescription))
        }
    }
    
    /// Check the current authentication state
    func checkAuthState() async {
        // Since getCurrentUser() is not async, we need to ensure it's called on the main actor
        // to prevent data races with the authService
        let user = await MainActor.run { authService.getCurrentUser() }
        
        if let user = user {
            self.currentUser = user
            self.authState = .authenticated
            
            // In a real implementation, we would also check subscription status here
            // await subscriptionService.refreshSubscriptionStatus()
        } else {
            self.authState = .unauthenticated
        }
    }
    
    /// Delete the current user's account
    func deleteAccount() async {
        do {
            try await authService.deleteAccount()
            self.currentUser = nil
            self.authState = .unauthenticated
        } catch let error as AuthError {
            self.authState = .error(error)
        } catch {
            self.authState = .error(.unknown(message: error.localizedDescription))
        }
    }
    
    /// Check if the user is authenticated
    var isAuthenticated: Bool {
        if case .authenticated = authState {
            return true
        }
        return false
    }
}
