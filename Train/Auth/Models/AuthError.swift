import Foundation

/// Represents errors that can occur during authentication
enum AuthError: Error, Equatable {
    /// User is not authenticated
    case notAuthenticated
    
    /// Authentication failed with a specific message
    case authenticationFailed(message: String)
    
    /// Apple sign in was canceled by the user
    case signInCanceled
    
    /// Account deletion failed
    case accountDeletionFailed
    
    /// Network error occurred during authentication
    case networkError
    
    /// Unknown error occurred
    case unknown(message: String)
    
    /// User-friendly error message
    var localizedDescription: String {
        switch self {
        case .notAuthenticated:
            return "You are not signed in. Please sign in to continue."
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .signInCanceled:
            return "Sign in was canceled."
        case .accountDeletionFailed:
            return "Failed to delete your account. Please try again later."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .unknown(let message):
            return "An unknown error occurred: \(message)"
        }
    }
}
