import Foundation

/// Protocol defining authentication operations
@MainActor
protocol AuthService {
    /// Sign in with Apple
    /// - Returns: User entity representing the authenticated user
    func signInWithApple() async throws -> UserEntity
    
    /// Sign out the current user
    func signOut() async throws
    
    /// Get the current authenticated user
    /// - Returns: User entity if authenticated, nil otherwise
    nonisolated func getCurrentUser() -> UserEntity?
    
    /// Delete the current user's account
    func deleteAccount() async throws
}
