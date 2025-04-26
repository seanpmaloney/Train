import Foundation
import SwiftUI
import Combine

/// Tracks and manages the user's authentication session
class UserSession: ObservableObject {
    // MARK: - Published Properties
    
    /// The authenticated user's Apple ID, if available
    @Published private(set) var userId: String?
    
    /// Whether the user is currently signed in
    @Published private(set) var isSignedIn: Bool = false
    
    // MARK: - Private Properties
    
    /// The key used to store the user ID in UserDefaults
    private let userIdKey = "userId"
    
    // MARK: - Initialization
    
    init() {
        // Load the session when initialized
        loadSession()
    }
    
    // MARK: - Public Methods
    
    /// Loads the user session from persistent storage
    func loadSession() {
        // Retrieve userId from UserDefaults
        if let storedUserId = UserDefaults.standard.string(forKey: userIdKey) {
            self.userId = storedUserId
            self.isSignedIn = true
        } else {
            clearSession()
        }
    }
    
    /// Updates the session with a new user ID
    /// - Parameter userId: The user ID to set for the session
    func updateSession(userId: String) {
        self.userId = userId
        self.isSignedIn = true
        
        // Store in UserDefaults for persistence
        UserDefaults.standard.set(userId, forKey: userIdKey)
    }
    
    /// Clears the current session
    func clearSession() {
        // Clear memory state
        self.userId = nil
        self.isSignedIn = false
        
        // Clear persistent storage
        UserDefaults.standard.removeObject(forKey: userIdKey)
    }
}
