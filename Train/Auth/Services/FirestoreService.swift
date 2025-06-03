import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI
import OSLog

/// Error types for Firestore operations
enum FirestoreError: Error, LocalizedError {
    case invalidData(String)
    case networkError(Error)
    case documentNotFound(String)
    case serializationError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .documentNotFound(let id):
            return "Document not found: \(id)"
        case .serializationError(let message):
            return "Serialization error: \(message)"
        }
    }
}

/// Service for handling Firestore database operations related to user data
actor FirestoreService {
    // MARK: - Singleton
    
    /// Shared instance for app-wide access
    static let shared = FirestoreService()
    
    // MARK: - Properties
    
    /// Collection names
    private let usersCollection = "users"
    
    // MARK: - Initialization
    
    private init() {
        // Configure Firestore with modern persistent cache settings
        let settings = FirestoreSettings()
        // Use PersistentCacheSettings instead of the deprecated isPersistenceEnabled
        settings.cacheSettings = PersistentCacheSettings()
        Firestore.firestore().settings = settings
    }
    
    // MARK: - User Operations
    
    /// Save a user entity to Firestore
    /// - Parameter user: The user entity to save
    /// - Throws: FirestoreError if the operation fails
    func saveUser(_ user: UserEntity) async throws {
        // Validate critical data before saving
        guard !user.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FirestoreError.invalidData("Email cannot be empty")
        }
        
        let username = user.username
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FirestoreError.invalidData("Username cannot be empty")
        }
        
        // Get the Firebase Auth UID - this is critical for security rules to work
        guard let firebaseUid = Auth.auth().currentUser?.uid else {
            throw FirestoreError.invalidData("No authenticated Firebase user")
        }
        
        // Manual conversion with meaningful fallbacks
        let userData: [String: Any] = [
            "email": user.email,
            "displayName": user.displayName ?? generateDisplayName(firstName: user.firstName, lastName: user.lastName, username: user.username),
            "firstName": user.firstName as Any,
            "lastName": user.lastName as Any,
            "tier": user.tier.rawValue,
            "createdAt": Timestamp(date: user.createdAt),
            "lastLoginAt": Timestamp(date: user.lastLoginAt),
            "lastPostDate": user.lastPostDate.map { Timestamp(date: $0) } as Any,
            "username": username,
            "marketingOptIn": user.marketingOptIn,
            "followerCount": user.followerCount,
            "following": user.following,
            "localUserId": user.id, // Store the app's internal user ID for reference
        ]
        
        // Log before saving
        print("📝 Saving user to Firestore with Firebase UID: \(firebaseUid), username: \(username)")
        
        // Use merge: true to avoid overwriting fields that aren't included
        // IMPORTANT: Using Firebase UID as the document ID to satisfy security rules
        try await Firestore.firestore().collection(usersCollection).document(firebaseUid).setData(userData, merge: true)
    }
    
    /// Generate a display name from available user data
    private func generateDisplayName(firstName: String?, lastName: String?, username: String?) -> String {
        // First try to combine first and last name
        if let first = firstName, !first.isEmpty, let last = lastName, !last.isEmpty {
            return "\(first) \(last)"
        }
        
        // Then try just first name
        if let first = firstName, !first.isEmpty {
            return first
        }
        
        // Then try username
        if let username = username, !username.isEmpty {
            return username
        }
        
        // Fall back to generic name
        return "Train User"
    }
    
    // Logger for FirestoreService
    private let logger = Logger(subsystem: "com.train.app", category: "FirestoreService")
    
    /// Retrieve a user entity from Firestore using the current Firebase Auth UID
    /// - Returns: UserEntity if found, nil otherwise
    /// - Throws: FirestoreError if the operation fails
    func getCurrentFirestoreUser() async throws -> UserEntity? {
        // Get current Firebase Auth UID
        guard let firebaseUid = Auth.auth().currentUser?.uid else {
            throw FirestoreError.invalidData("No authenticated Firebase user")
        }
        
        logger.debug("Retrieving user data with Firebase UID: \(firebaseUid)")
        return try await getUserByFirebaseUID(firebaseUid)
    }
    
    /// Retrieve a user entity from Firestore by Firebase UID
    /// - Parameter firebaseUid: The Firebase Auth UID to fetch
    /// - Returns: UserEntity if found, nil otherwise
    /// - Throws: FirestoreError if the operation fails
    func getUserByFirebaseUID(_ firebaseUid: String) async throws -> UserEntity? {
        guard !firebaseUid.isEmpty else {
            throw FirestoreError.invalidData("Firebase UID cannot be empty")
        }
        
        do {
            let document = try await Firestore.firestore().collection(usersCollection).document(firebaseUid).getDocument()
            
            guard document.exists else {
                logger.debug("No document found for Firebase UID: \(firebaseUid)")
                return nil
            }
            
            guard let data = document.data() else {
                throw FirestoreError.serializationError("Document exists but data is nil for Firebase UID: \(firebaseUid)")
            }
            
            // Extract and validate email (required field)
            let email = data["email"] as? String ?? ""
            if email.isEmpty {
                logger.warning("User document \(firebaseUid) has no valid email")
                // Continue with empty email as fallback
            }
            
            // Extract tier with validation
            let tierString = data["tier"] as? String ?? ""
            let tier = UserEntity.SubscriptionTier(rawValue: tierString) ?? .free
            if tierString.isEmpty {
                logger.debug("Using default tier .free for user \(firebaseUid)")
            }
            
            // Extract timestamps with proper conversion
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            let lastLoginAt = (data["lastLoginAt"] as? Timestamp)?.dateValue() ?? Date()
            let lastPostDate = (data["lastPostDate"] as? Timestamp)?.dateValue()
            
            // Extract username with validation
            let username = data["username"] as? String ?? ""
            if username.isEmpty {
                logger.warning("User \(firebaseUid) has empty username")
            }
            
            // Get the local user ID if available, or use Firebase UID as fallback
            let localUserId = data["localUserId"] as? String ?? document.documentID
            
            // Manual conversion from Firestore document to UserEntity
            let user = UserEntity(
                id: localUserId,  // Use the app's local user ID
                email: email,
                displayName: data["displayName"] as? String,
                firstName: data["firstName"] as? String,
                lastName: data["lastName"] as? String,
                tier: tier,
                createdAt: createdAt,
                lastLoginAt: lastLoginAt,
                lastPostDate: lastPostDate,
                following: data["following"] as? [String] ?? [],
                followerCount: data["followerCount"] as? Int ?? 0,
                username: username,
                marketingOptIn: data["marketingOptIn"] as? Bool ?? false
            )
            
            logger.debug("Successfully retrieved user: Firebase UID \(firebaseUid), app ID: \(localUserId)")
            return user
        } catch let firestoreError as FirestoreError {
            // Re-throw our custom errors
            throw firestoreError
        } catch {
            // Wrap other errors
            logger.error("Firestore error retrieving user \(firebaseUid): \(error.localizedDescription)")
            throw FirestoreError.networkError(error)
        }
    }
    
    /// Retrieve a user entity from Firestore by local app ID (deprecated, use Firebase UID methods instead)
    /// - Parameter id: The local app user ID to fetch
    /// - Returns: UserEntity if found, nil otherwise
    /// - Throws: FirestoreError if the operation fails
    @available(*, deprecated, message: "Use getCurrentFirestoreUser or getUserByFirebaseUID instead")
    func getUser(id: String) async throws -> UserEntity? {
        // Check if we have a logged in Firebase user
        guard let firebaseUid = Auth.auth().currentUser?.uid else {
            throw FirestoreError.invalidData("No authenticated Firebase user")
        }
        
        // Just use the Firebase UID directly for security rule compliance
        return try await getUserByFirebaseUID(firebaseUid)
    }
    
    /// Update just the lastLoginAt field for the current user
    /// - Throws: FirestoreError if the operation fails
    func updateLastLogin() async throws {
        // Get current Firebase Auth UID
        guard let firebaseUid = Auth.auth().currentUser?.uid else {
            throw FirestoreError.invalidData("No authenticated Firebase user")
        }
        
        do {
            try await Firestore.firestore().collection(usersCollection).document(firebaseUid).updateData([
                "lastLoginAt": Timestamp(date: Date())
            ])
            logger.debug("Updated last login time for user with Firebase UID: \(firebaseUid)")
        } catch {
            logger.error("Failed to update last login time: \(error.localizedDescription)")
            throw FirestoreError.networkError(error)
        }
    }
    
    /// Update just the lastLoginAt field for a user (deprecated, use the no-parameter version instead)
    /// - Parameter userId: The user ID to update (ignored, using Firebase UID instead)
    /// - Throws: FirestoreError if the operation fails
    @available(*, deprecated, message: "Use updateLastLogin() without parameters instead")
    func updateLastLogin(userId: String) async throws {
        try await updateLastLogin()
    }
    
    /// Delete the current user document from Firestore
    /// - Throws: FirestoreError if the operation fails
    func deleteCurrentUser() async throws {
        // Get current Firebase Auth UID
        guard let firebaseUid = Auth.auth().currentUser?.uid else {
            throw FirestoreError.invalidData("No authenticated Firebase user")
        }
        
        do {
            try await Firestore.firestore().collection(usersCollection).document(firebaseUid).delete()
            logger.debug("Deleted user document with Firebase UID: \(firebaseUid)")
        } catch {
            logger.error("Failed to delete user document: \(error.localizedDescription)")
            throw FirestoreError.networkError(error)
        }
    }
    
    /// Delete a user document from Firestore (deprecated, use deleteCurrentUser instead)
    /// - Parameter userId: The user ID to delete (ignored, using Firebase UID instead)
    /// - Throws: FirestoreError if the operation fails
    @available(*, deprecated, message: "Use deleteCurrentUser() instead")
    func deleteUser(userId: String) async throws {
        try await deleteCurrentUser()
    }
    
    /// Synchronize local user data with Firestore
    /// Uses the local user as the source of truth but doesn't override critical Firestore fields
    /// - Parameter user: The local user entity to synchronize
    /// - Returns: Boolean indicating success or failure
    func synchronizeUser(_ user: UserEntity) async -> Bool {
        // Get current Firebase Auth UID
        guard let firebaseUid = Auth.auth().currentUser?.uid else {
            logger.error("Cannot synchronize user - no authenticated Firebase user")
            return false
        }
        
        do {
            // First check if a Firestore record exists
            let existingUser = try await getUserByFirebaseUID(firebaseUid)
            
            // Decide what to synchronize based on existing data
            var userData: [String: Any] = [
                "email": user.email,
                "displayName": user.displayName ?? generateDisplayName(firstName: user.firstName, lastName: user.lastName, username: user.username),
                "firstName": user.firstName as Any,
                "lastName": user.lastName as Any,
                "tier": user.tier.rawValue,
                "lastLoginAt": Timestamp(date: user.lastLoginAt),
                "username": user.username as Any,
                "marketingOptIn": user.marketingOptIn,
                "localUserId": user.id  // Always store the local app user ID for reference
            ]
            
            // Preserve creation timestamp if it exists in Firestore
            if existingUser != nil {
                // Update mode - only update fields that should be synced from local
                logger.debug("Updating existing Firestore user with Firebase UID: \(firebaseUid)")
            } else {
                // Create mode - include creation timestamp
                userData["createdAt"] = Timestamp(date: user.createdAt)
                logger.debug("Creating new Firestore user with Firebase UID: \(firebaseUid)")
            }
            
            // Use merge: true to avoid overwriting fields like followerCount that may be updated elsewhere
            try await Firestore.firestore().collection(usersCollection).document(firebaseUid).setData(userData, merge: true)
            return true
        } catch {
            logger.error("Failed to synchronize user data: \(error.localizedDescription)")
            return false
        }
    }
}
