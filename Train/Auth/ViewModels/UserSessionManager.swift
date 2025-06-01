import Foundation
import SwiftUI
import Combine
import AuthenticationServices

/// Central coordinator for authentication state and user profile management
/// Acts as the single source of truth for user information across the app
@MainActor
class UserSessionManager: ObservableObject {
    // MARK: - Published Properties
    
    /// Current authenticated user
    @Published private(set) var currentUser: UserEntity?
    
    /// Current authentication state
    @Published private(set) var authState: AuthState = .unknown
    
    // MARK: - Computed Properties
    
    /// Returns the display name for the user, prioritizing username over displayName
    var userDisplayName: String {
        if let username = currentUser?.username, !username.isEmpty {
            return username
        } else if let displayName = currentUser?.displayName, !displayName.isEmpty {
            return displayName
        } else if let firstName = currentUser?.firstName, !firstName.isEmpty {
            return firstName
        } else {
            return "User"
        }
    }
    
    /// Check if the user is authenticated
    var isAuthenticated: Bool {
        if case .authenticated = authState {
            return true
        }
        return false
    }
    
    // MARK: - Authentication State
    
    /// Authentication state enum
    enum AuthState: Equatable {
        /// Authentication state is unknown or initializing
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
    
    // MARK: - Dependencies
    
    /// Authentication service for handling sign-in/out operations
    private let authService: AuthService
    
    /// Storage for subscription cancellation
    private var cancellables = Set<AnyCancellable>()
    
    /// UserDefaults key for storing serialized user data
    private let userDataKey = "com.train.userProfileData"
    
    /// Initialize with dependencies
    /// - Parameter authService: Service for authentication operations
    init(authService: AuthService = AppleAuthService()) {
        self.authService = authService
        self.authState = .unauthenticated
    }
    
    // MARK: - User Persistence
    
    /// Forward user data to AppState for persistence
    /// - Parameters:
    ///   - user: The user entity to save
    ///   - appState: The AppState to update
    private func saveUserData(_ user: UserEntity, appState: AppState) {
        appState.updateUser(user)
    }
    
    /// Clear user data from AppState
    /// - Parameter appState: The AppState to update
    private func clearUserData(appState: AppState) {
        appState.updateUser(nil)
    }
    
    // MARK: - Authentication Methods
    
    /// Sign in with Apple
    /// - Parameters:
    ///   - presentationContextProvider: The context to present the sign-in UI from
    ///   - appState: The AppState to update with the user data
    func signInWithApple(presentationContextProvider: ASAuthorizationControllerPresentationContextProviding, appState: AppState) async {
        do {
            let user = try await authService.signInWithApple(presentationContextProvider: presentationContextProvider)
            self.currentUser = user
            self.authState = .authenticated
            
            // Save the user data to AppState which handles persistence
            saveUserData(user, appState: appState)
            
            // Update the auth service as well
            try? await authService.updateUserProfile(user)
        } catch AuthError.signInCanceled {
            // User canceled the sign-in flow, remain in current state
            print("Sign in canceled by user")
        } catch let error as AuthError {
            self.authState = .error(error)
        } catch {
            self.authState = .error(.unknown(message: error.localizedDescription))
        }
    }
    
    /// Sign out the current user
    /// - Parameter appState: The AppState to update when signing out
    func signOut(appState: AppState) async {
        do {
            try await authService.signOut()
            self.currentUser = nil
            self.authState = .unauthenticated
            
            // Clear persisted user data from AppState
            clearUserData(appState: appState)
        } catch {
            self.authState = .error(.unknown(message: error.localizedDescription))
        }
    }
    
    // No longer needed - UserSessionManager now fully relies on AppState for user persistence
    // Authentication state is set during sign-in/sign-out and AppState sync
    
    /// Delete the current user's account
    /// - Parameter appState: The AppState to update when deleting the account
    func deleteAccount(appState: AppState) async {
        do {
            try await authService.deleteAccount()
            self.currentUser = nil
            self.authState = .unauthenticated
            
            // Clear persisted user data from AppState
            clearUserData(appState: appState)
        } catch let error as AuthError {
            self.authState = .error(error)
        } catch {
            self.authState = .error(.unknown(message: error.localizedDescription))
        }
    }
    
    // MARK: - User Profile Methods
    
    /// Sign in with an existing user entity (used during onboarding)
    /// - Parameters:
    ///   - user: The user entity to sign in with
    ///   - appState: The AppState to update with user data
    func signInWithUser(_ user: UserEntity, appState: AppState) {
        // Set the current user
        self.currentUser = user
        
        // Update authentication state
        self.authState = .authenticated
        
        // Save user data to AppState
        saveUserData(user, appState: appState)
        
        // Update auth service in background
        Task {
            try? await authService.updateUserProfile(user)
        }
    }
    
    /// Update the current user profile with new information
    /// - Parameters:
    ///   - updatedUser: The updated user entity
    ///   - appState: The AppState to update with user data
    func updateUserProfile(with updatedUser: UserEntity, appState: AppState) {
        guard updatedUser.id == currentUser?.id else { return }
        self.currentUser = updatedUser
        
        // Save to AppState
        saveUserData(updatedUser, appState: appState)
        
        // Update the auth service
        Task {
            try? await authService.updateUserProfile(updatedUser)
        }
    }
    
    /// Sync with AppState to ensure consistent user data across the app
    /// Call this when the app starts to ensure UserSessionManager has the latest user data
    /// - Parameter appState: The app state to sync with
    func syncWithAppState(_ appState: AppState) {
        if let appStateUser = appState.currentUser {
            print("Syncing UserSessionManager with AppState user: \(appStateUser.displayName ?? appStateUser.id)")
            self.currentUser = appStateUser
            self.authState = .authenticated
        }
    }
}
