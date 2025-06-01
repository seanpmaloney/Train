import Foundation
import AuthenticationServices
import SwiftUI

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
}

/// Implementation of AuthService that provides Apple authentication
@MainActor
class AppleAuthService: NSObject, AuthService {
    // MARK: - Private Properties
    
    /// User defaults key for storing user ID
    private let userIdKey = "userId"
    
    /// Temporary storage for auth completion handling
    private var authContinuation: CheckedContinuation<UserEntity, Error>?
    
    // MARK: - Public Methods
    
    /// Sign in with Apple and return the authenticated user
    func signInWithApple(presentationContextProvider: ASAuthorizationControllerPresentationContextProviding) async throws -> UserEntity {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
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
    
    /// Update user profile information
    func updateUserProfile(_ user: UserEntity) async throws {
        // Store the ID for backward compatibility
        UserDefaults.standard.set(user.id, forKey: userIdKey)
        
        // Save the complete user data to UserDefaults
        saveUserToDefaults(user: user)
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
        
        // Store the user ID for backward compatibility
        UserDefaults.standard.set(userId, forKey: userIdKey)
        
        // Check if we have an existing user in UserDefaults to retrieve profile data
        // that Apple might not provide on subsequent sign-ins
        var existingUser: UserEntity? = retrieveUserFromDefaults(userId: userId)
        
        // Get the new email from Apple or fall back to existing
        let email = appleIDCredential.email ?? existingUser?.email ?? ""
        
        // Extract name if provided by Apple
        var firstName = appleIDCredential.fullName?.givenName
        var lastName = appleIDCredential.fullName?.familyName
        var username = existingUser?.username
        
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
        
        let user = UserEntity(
            id: userId,
            email: email,
            displayName: displayName,
            firstName: firstName,
            lastName: lastName,
            username: username // Include preserved username
        )
        
        // Store the user data in UserDefaults for subsequent sign-ins
        saveUserToDefaults(user: user)
        
        // UserSessionManager will handle saving the complete user entity
        
        // Resume with the user
        authContinuation?.resume(returning: user)
        authContinuation = nil
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
}
