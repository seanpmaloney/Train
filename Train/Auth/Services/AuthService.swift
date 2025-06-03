import Foundation
import AuthenticationServices
import SwiftUI
import Firebase
import FirebaseAuth
import CryptoKit

/// Protocol for authentication services
@MainActor
protocol AuthService {
    /// Sign in with Apple
    func signInWithApple(presentationContextProvider: ASAuthorizationControllerPresentationContextProviding) async throws -> UserEntity
    
    /// Sign out the current user
    func signOut() async throws
    
    /// Get the current authenticated user
    func getCurrentUser() -> UserEntity?
    
    /// Delete the current user's account
    func deleteAccount() async throws
    
    /// Update user profile information
    func updateUserProfile(_ user: UserEntity) async throws
    
    /// Process a credential directly (for use when you already have an authorization)
    func processCredential(_ credential: ASAuthorizationAppleIDCredential) async throws -> UserEntity
}

/// Implementation of AuthService that provides Apple authentication
@MainActor
class AppleAuthService: NSObject, AuthService {
    // MARK: - Private Properties
    
    /// User defaults key for storing user ID
    private let userIdKey = "userId"
    
    /// Temporary storage for auth completion handling
    private var authContinuation: CheckedContinuation<UserEntity, Error>?
    
    /// Current nonce for Apple Sign In security
    /// This needs to be accessed across multiple methods to ensure consistency
    private var currentNonce: String?
    
    // MARK: - Public Methods
    
    /// Configure an Apple authorization request with the required parameters
    func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        // Generate a new nonce and store it for later verification
        let nonce = randomNonceString()
        currentNonce = nonce
        
        // Set the SHA256 hash of the nonce in the request
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        print("Configured Apple request with nonce: \(nonce)")
    }
    
    /// Sign in with Apple and return the authenticated user
    func signInWithApple(presentationContextProvider: ASAuthorizationControllerPresentationContextProviding) async throws -> UserEntity {
        // Generate a random nonce for PKCE verification
        let nonce = randomNonceString()
        currentNonce = nonce
        
        // Create the Apple Sign In request
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        // Set the SHA256 hash of the nonce in the request
        // This is critical for Firebase Auth verification
        request.nonce = sha256(nonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = presentationContextProvider
        
        return try await withCheckedThrowingContinuation { continuation in
            self.authContinuation = continuation
            controller.performRequests()
        }
    }
    
    /// Sign out the current user
    func signOut() async throws {
        // Remove the user ID from UserDefaults
        // UserSessionManager will handle clearing the complete user data
        UserDefaults.standard.removeObject(forKey: userIdKey)
    }
    
    /// Get the current user from persistent storage
    func getCurrentUser() -> UserEntity? {
        // Get the user ID from UserDefaults
        guard let userId = UserDefaults.standard.string(forKey: userIdKey) else {
            return nil
        }
        
        // Create a minimal user with just the ID
        // UserSessionManager will handle storing and retrieving the full user data
        return UserEntity(id: userId, email: "")
    }
    
    /// Delete the current user's account
    func deleteAccount() async throws {
        // In a real app, you would call your backend to delete the user's account
        // For now, just clear all local data
        try await signOut()
    }
    
    /// Process an Apple ID credential directly (for use when you already have an authorization)
    /// - Parameter credential: The Apple ID credential to process
    /// - Returns: A UserEntity representing the authenticated user
    func processCredential(_ credential: ASAuthorizationAppleIDCredential) async throws -> UserEntity {
        // Extract required fields from the credential
        guard let identityToken = credential.identityToken,
              let idTokenString = String(data: identityToken, encoding: .utf8),
              let userId = credential.user as? String,
              let nonce = currentNonce else {
            print("⚠️ Missing required credential fields or nonce")
            throw AuthError.invalidCredentials
        }
        
        print("Processing Apple credential with nonce: \(nonce)")
        
        // Create Firebase credential with the same nonce used in the request
        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )
        
        // Sign in to Firebase
        try await signInWithFirebase(credential: firebaseCredential)
        
        // Extract user information
        let email = credential.email ?? ""
        let firstName = credential.fullName?.givenName
        let lastName = credential.fullName?.familyName
        
        // Retrieve existing user if available
        let existingUser = retrieveUserFromDefaults(userId: userId)
        
        // Determine display name based on available info
        var displayName: String?
        if let firstName = firstName, let lastName = lastName {
            displayName = "\(firstName) \(lastName)"
        } else if let firstName = firstName {
            displayName = firstName
        } else if let lastName = lastName {
            displayName = lastName
        } else {
            displayName = existingUser?.displayName
        }
        
        // Create the user entity
        let user = UserEntity(
            id: userId,
            email: email,
            displayName: displayName,
            firstName: firstName,
            lastName: lastName
        )
        
        // Store the user ID for later retrieval
        UserDefaults.standard.set(userId, forKey: userIdKey)
        
        // Save the user profile
        saveUserToDefaults(user: user)
        
        return user
    }
    
    /// Update user profile information
    func updateUserProfile(_ user: UserEntity) async throws {
        // Store the ID for backward compatibility
        UserDefaults.standard.set(user.id, forKey: userIdKey)
        
        // Save the complete user data to UserDefaults
        saveUserToDefaults(user: user)
    }
    
    /// Sign in to Firebase Auth with a credential
    /// This method handles the non-sendable AuthDataResult type
    /// - Parameter credential: The OAuthCredential to authenticate with
    private func signInWithFirebase(credential: OAuthCredential) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result {
                    print("✅ Firebase Auth successful with UID: \(result.user.uid)")
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: AuthError.unknown(message: "Unknown Firebase error"))
                }
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Store user information in UserDefaults
    private func saveUserToDefaults(user: UserEntity) {
        let encoder = JSONEncoder()
        if let userData = try? encoder.encode(user) {
            UserDefaults.standard.set(userData, forKey: "user_\(user.id)")
            print("Saved user profile to UserDefaults: \(user.displayName ?? user.id)")
        }
    }
    
    /// Retrieve user information from UserDefaults
    private func retrieveUserFromDefaults(userId: String) -> UserEntity? {
        guard let userData = UserDefaults.standard.data(forKey: "user_\(userId)") else {
            return nil
        }
        
        let decoder = JSONDecoder()
        if let user = try? decoder.decode(UserEntity.self, from: userData) {
            print("Retrieved user profile from UserDefaults: \(user.displayName ?? user.id)")
            return user
        }
        return nil
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleAuthService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let userId = appleIDCredential.user as? String else {
            authContinuation?.resume(throwing: AuthError.invalidCredentials)
            authContinuation = nil
            return
        }
        
        // Get existing user if available
        let existingUser = retrieveUserFromDefaults(userId: userId)
        
        // Get the new email from Apple or fall back to existing
        let email = appleIDCredential.email ?? existingUser?.email ?? ""
        
        // Extract name if provided by Apple
        var firstName = appleIDCredential.fullName?.givenName
        var lastName = appleIDCredential.fullName?.familyName
        let username = existingUser?.username
        
        // If Apple didn't provide name data but we have it stored, use that
        if firstName == nil {
            firstName = existingUser?.firstName
        }
        
        if lastName == nil {
            lastName = existingUser?.lastName
        }
        
        // Generate display name
        var displayName: String? = nil
        if let firstName = firstName, let lastName = lastName {
            displayName = "\(firstName) \(lastName)"
        } else if let firstName = firstName {
            displayName = firstName
        } else if let lastName = lastName {
            displayName = lastName
        } else {
            // Fall back to existing display name
            displayName = existingUser?.displayName
        }
        
        // CRITICAL: Sign in to Firebase Auth with the Apple credential
        // Use the existing nonce we stored when creating the request
        guard let nonce = currentNonce else {
            print("❌ Fatal error: No nonce found for Apple Sign In")
            authContinuation?.resume(throwing: AuthError.invalidCredentials)
            authContinuation = nil
            return
        }
        
        // Get the ASAuthorizationAppleIDCredential and identityToken
        guard let appleIDToken = appleIDCredential.identityToken else {
            authContinuation?.resume(throwing: AuthError.invalidCredentials)
            authContinuation = nil
            return
        }
        
        // Convert token to string
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            authContinuation?.resume(throwing: AuthError.invalidCredentials)
            authContinuation = nil
            return
        }
        
        // Create Firebase Auth credential with proper Apple provider method
        // This includes the user's full name for new user creation
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )
        
        // Create the UserEntity with our app's user info
        let user = UserEntity(
            id: userId, // Keep the original Apple user ID for backward compatibility
            email: email,
            displayName: displayName,
            firstName: firstName,
            lastName: lastName,
            username: username ?? "" // Unwrap optional username with default empty string
        )
        
        // Store the user data in UserDefaults for subsequent sign-ins
        UserDefaults.standard.set(userId, forKey: userIdKey)
        saveUserToDefaults(user: user)
        
        // Authenticate with Firebase - this is already on the main actor because of the class annotation
        Task {
            do {
                // Call the method that handles Firebase Auth
                try await signInWithFirebase(credential: credential)
                print("✅ Successfully authenticated with Firebase")
                
                // Resume with the user
                authContinuation?.resume(returning: user)
            } catch {
                print("❌ Firebase authentication failed: \(error.localizedDescription)")
                authContinuation?.resume(throwing: AuthError.unknown(message: error.localizedDescription))
            }
            // Clear continuation reference
            authContinuation = nil
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle auth errors
        if let authError = error as? ASAuthorizationError {
            if authError.code == .canceled {
                authContinuation?.resume(throwing: AuthError.signInCanceled)
            } else {
                authContinuation?.resume(throwing: AuthError.unknown(message: authError.localizedDescription))
            }
        } else {
            authContinuation?.resume(throwing: AuthError.unknown(message: error.localizedDescription))
        }
        
        authContinuation = nil
    }
}

// MARK: - Firebase Auth Helpers

extension AppleAuthService {
    /// Hash a string using SHA256
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        
        return hashString
    }
    
    /// Generate a random nonce for secure token exchange
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    /// Implementation of AuthService for testing
    @MainActor
    class MockAuthService: AuthService {
        var shouldSucceed = true
        var mockUser: UserEntity? = UserEntity(
            id: "mock-user-id",
            email: "mock@example.com",
            displayName: "Mock User",
            firstName: "Mock",
            lastName: "User"
        )
        
        func signInWithApple(presentationContextProvider: ASAuthorizationControllerPresentationContextProviding) async throws -> UserEntity {
            if shouldSucceed, let user = mockUser {
                // UserSessionManager will handle saving the user data
                return user
            } else {
                throw AuthError.invalidCredentials
            }
        }
        
        func signOut() async throws {
            if !shouldSucceed {
                throw AuthError.unknown(message: "Failed to sign out")
            }
            // UserSessionManager will handle clearing user data
        }
        
        func getCurrentUser() -> UserEntity? {
            if !shouldSucceed {
                return nil
            }
            
            // Just return the mock user
            // UserSessionManager handles full user data persistence
            return mockUser
        }
        
        func deleteAccount() async throws {
            if !shouldSucceed {
                throw AuthError.unknown(message: "Failed to delete account")
            }
            // UserSessionManager will handle clearing user data
        }
        
        func updateUserProfile(_ user: UserEntity) async throws {
            if shouldSucceed {
                mockUser = user
                // UserSessionManager will handle saving user data
            } else {
                throw AuthError.unknown(message: "Failed to update profile")
            }
        }
        
        /// Process an Apple ID credential directly (mocked implementation)
        /// - Parameter credential: The Apple ID credential to process
        /// - Returns: A UserEntity representing the authenticated user
        func processCredential(_ credential: ASAuthorizationAppleIDCredential) async throws -> UserEntity {
            if shouldSucceed, let user = mockUser {
                return user
            } else {
                throw AuthError.invalidCredentials
            }
        }
    }
}
