import Foundation

/// Represents errors that can occur during authentication
enum AuthError: Error, Equatable {
    /// User is not authenticated
    case notAuthenticated
    
    /// Invalid user credentials
    case invalidCredentials
    
    /// Authentication failed with a specific message
    case authenticationFailed(message: String)
    
    /// User account is disabled
    case accountDisabled
    
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
        case .invalidCredentials:
            return "Invalid credentials. Please check your username and password."
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .accountDisabled:
            return "This account has been disabled. Please contact support for assistance."
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
    
    /// Custom equality implementation
    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthenticated, .notAuthenticated),
             (.invalidCredentials, .invalidCredentials),
             (.accountDisabled, .accountDisabled),
             (.signInCanceled, .signInCanceled),
             (.accountDeletionFailed, .accountDeletionFailed),
             (.networkError, .networkError):
            return true
        case (.authenticationFailed(let lhsMessage), .authenticationFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.unknown(let lhsMessage), .unknown(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}
