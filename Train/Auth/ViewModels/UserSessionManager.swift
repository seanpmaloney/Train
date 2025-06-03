import Foundation
import SwiftUI
import Combine
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore

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
    
    /// Firebase Auth state listener handle
    /// Stored as weak to avoid reference cycles
    private weak var _authStateListener: AnyObject?
    
    /// Flag to prevent multiple handler calls
    private var isHandlingAuthState = false
    
    /// Initialize with dependencies
    /// - Parameter authService: Service for authentication operations
    init(authService: AuthService = AppleAuthService()) {
        self.authService = authService
        self.authState = .unauthenticated
        
        // Setup Firebase Auth state listener
        setupAuthStateListener()
    }
    
    // Deinit now safely avoids accessing non-Sendable types
    deinit {
        // Nothing to do here - Auth.auth() maintains its own references
        // and we're not storing the listener directly anymore
    }
    
    /// Safely removes the Firebase Auth state listener - only needed for explicit cleanup before deinit
    @MainActor
    private func removeAuthStateListener() {
        // We no longer directly store the listener handle, so this method is a no-op
        // Firebase maintains its own references, and we're using weak references
        // This is left in place for potential future enhancements
    }
    
    /// Setup Firebase Auth state change listener
    @MainActor
    private func setupAuthStateListener() {
        // Ensure this runs on the main thread where Auth listeners are expected
        // We store the listener handle as an opaque AnyObject to avoid Sendable issues
        let listener = Auth.auth().addStateDidChangeListener { [weak self] (_, firebaseUser) in
            guard let self = self, !self.isHandlingAuthState else { return }
            
            // Set flag to prevent recursive or duplicate handling
            self.isHandlingAuthState = true
            
            // Use Task to handle async operations
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    // User is signed in with Firebase
                    await self.handleFirebaseUserSignIn(firebaseUser)
                } else {
                    // User is signed out from Firebase
                    // Only update state if we're currently authenticated
                    if case .authenticated = self.authState {
                        self.authState = .unauthenticated
                        self.currentUser = nil
                    }
                }
                
                // Reset handling flag
                self.isHandlingAuthState = false
            }
        }
        
        // Store as AnyObject to avoid Sendable issues with the NSObjectProtocol type
        _authStateListener = listener as AnyObject
    }
    
    /// Handle Firebase user sign-in state
    @MainActor
    private func handleFirebaseUserSignIn(_ firebaseUser: FirebaseAuth.User) async {
        do {
            // Try to fetch user data from Firestore
            // Since FirestoreService is an actor, this properly awaits access
            if let firestoreUser = try await FirestoreService.shared.getUser(id: firebaseUser.uid) {
                // We have the user in Firestore
                // Update auth state and current user (already on MainActor)
                self.currentUser = firestoreUser
                self.authState = .authenticated
                
                // Update last login time in a non-blocking way
                Task {
                    try? await FirestoreService.shared.updateLastLogin(userId: firebaseUser.uid)
                }
            } else if self.currentUser == nil {
                // User exists in Firebase Auth but not in Firestore
                // This should trigger onboarding flow
                self.authState = .unauthenticated
            }
            // If self.currentUser is not nil, we keep the existing user data
        } catch {
            print("Error handling Firebase user: \(error.localizedDescription)")
        }
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
            // First, authenticate with the Apple Auth Service as before
            let user = try await authService.signInWithApple(presentationContextProvider: presentationContextProvider)
            
            // Temporarily set as authenticated to show progress
            self.currentUser = user
            self.authState = .authenticated
            
            // IMPORTANT: Wait for Firebase Auth to be ready before proceeding with Firestore operations
            // Check if we have a valid Firebase Auth user
            guard let firebaseUser = Auth.auth().currentUser else {
                print("⚠️ No authenticated Firebase user available after sign-in")
                // Still update local app state since we authenticated with Apple
                saveUserData(user, appState: appState)
                return
            }
            
            print("✅ Firebase Auth user is ready: \(firebaseUser.uid)")
            
            // Check if we have existing data in Firestore for this user
            var completeUser = user
            
            do {
                // Try to get existing user data from Firestore using the Firebase UID
                if let firestoreUser = try await FirestoreService.shared.getUserByFirebaseUID(firebaseUser.uid) {
                    // Merge data from Firestore with current user data
                    // Keep Apple-provided data but use other fields from Firestore
                    completeUser = UserEntity(
                        id: user.id, // Keep Apple user ID for backward compatibility
                        email: user.email.isEmpty ? firestoreUser.email : user.email,
                        displayName: user.displayName ?? firestoreUser.displayName,
                        firstName: user.firstName ?? firestoreUser.firstName,
                        lastName: user.lastName ?? firestoreUser.lastName,
                        tier: firestoreUser.tier,
                        createdAt: firestoreUser.createdAt,
                        lastLoginAt: Date(),
                        username: firestoreUser.username,
                    )
                    
                    // Update last login time in a non-blocking way
                    Task {
                        try? await FirestoreService.shared.updateLastLogin()
                    }
                } else {
                    // New user - save initial data to Firestore
                    // FirestoreService will use the Firebase Auth UID for the document ID
                    try await FirestoreService.shared.saveUser(user)
                }
            } catch {
                print("Firestore error during sign-in: \(error.localizedDescription)")
                // Continue with local auth even if Firestore fails
            }
            
            // Update with complete user data
            self.currentUser = completeUser
            
            // Save to AppState which handles local persistence
            saveUserData(completeUser, appState: appState)
            
            // Update the auth service as well
            try? await authService.updateUserProfile(completeUser)
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
            // Sign out from Firebase Auth first
            try Auth.auth().signOut()
            print("✅ Signed out from Firebase Auth")
            
            // Then sign out from Apple Auth Service
            try await authService.signOut()
            print("✅ Signed out from Apple Auth Service")
            
            // Update local state
            self.currentUser = nil
            self.authState = .unauthenticated
            
            // Clear persisted user data from AppState
            clearUserData(appState: appState)
        } catch let firebaseError as NSError where firebaseError.domain == "FIRAuthErrorDomain" {
            // Handle Firebase Auth specific errors
            print("Firebase Auth sign out error: \(firebaseError.localizedDescription)")
            
            // Continue with Apple sign out even if Firebase fails
            do {
                try await authService.signOut()
                self.currentUser = nil
                self.authState = .unauthenticated
                clearUserData(appState: appState)
            } catch {
                self.authState = .error(.unknown(message: error.localizedDescription))
            }
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
    
    /// Configure an Apple authorization request with necessary parameters
    /// Delegates to AuthService to set up the request properly
    /// - Parameter request: The ASAuthorizationAppleIDRequest to configure
    func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        if let appleAuthService = authService as? AppleAuthService {
            appleAuthService.configureRequest(request)
        } else {
            // Fallback for non-AppleAuthService implementations
            request.requestedScopes = [.fullName, .email]
        }
    }
    
    /// Handle Apple Sign-In authorization result
    /// - Parameters:
    ///   - result: The authorization result from Apple
    ///   - appState: The AppState to update
    /// - Returns: AuthError if any occurred, nil if successful
    func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>, appState: AppState) async -> AuthError? {
        do {
            switch result {
            case .success(let authorization):
                // Forward to Apple Sign-In method
                try await signInWithApple(presentationContextProvider: DummyPresentationProvider(), appState: appState, authorization: authorization)
                return nil
                
            case .failure(let error):
                if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                    return AuthError.signInCanceled
                } else {
                    return AuthError.unknown(message: error.localizedDescription)
                }
            }
        } catch let error as AuthError {
            return error
        } catch {
            return AuthError.unknown(message: error.localizedDescription)
        }
    }
    
    /// Internal Apple Sign-In helper that accepts an existing authorization
    private func signInWithApple(presentationContextProvider: ASAuthorizationControllerPresentationContextProviding, appState: AppState, authorization: ASAuthorization) async throws {
        // This method directly uses an existing authorization rather than requesting a new one
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredentials
        }
        
        // Get the user entity from our auth service
        let user = try await (authService as? AppleAuthService)?.processCredential(appleIDCredential) ?? 
                  UserEntity(id: appleIDCredential.user, email: appleIDCredential.email ?? "")
        
        // Set temporary authenticated state
        self.currentUser = user
        self.authState = .authenticated
        
        // Verify Firebase Auth user is ready
        guard let firebaseUser = Auth.auth().currentUser else {
            print("⚠️ No authenticated Firebase user available after sign-in")
            throw AuthError.unknown(message: "Firebase Auth failed")
        }
        
        print("✅ Firebase Auth user is ready: \(firebaseUser.uid)")
        
        // Sync with Firestore
        var completeUser = user
        
        do {
            // Try to get existing user data from Firestore using Firebase UID
            if let firestoreUser = try await FirestoreService.shared.getUserByFirebaseUID(firebaseUser.uid) {
                // Merge with existing Firestore data
                completeUser = UserEntity(
                    id: firestoreUser.id,
                    email: user.email, // Keep latest email
                    displayName: user.displayName ?? firestoreUser.displayName,
                    firstName: user.firstName ?? firestoreUser.firstName,
                    lastName: user.lastName ?? firestoreUser.lastName,
                    tier: firestoreUser.tier,
                    createdAt: firestoreUser.createdAt,
                    lastLoginAt: Date(),
                    username: firestoreUser.username
                )
                
                // Update last login time non-blocking
                Task {
                    try? await FirestoreService.shared.updateLastLogin()
                }
            } else {
                // New user - save to Firestore
                try await FirestoreService.shared.saveUser(user)
            }
        } catch {
            print("Firestore error during sign-in: \(error.localizedDescription)")
            // Continue with local auth
        }
        
        // Update local state
        self.currentUser = completeUser
        self.authState = .authenticated
        
        // Save to AppState
        saveUserData(completeUser, appState: appState)
        
        // Update auth service
        try? await authService.updateUserProfile(completeUser)
    }
}

/// Dummy presentation provider for direct auth processing
class DummyPresentationProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // This is not actually used when processing an existing authorization
        // but required by the protocol
        return ASPresentationAnchor()
    }
}
