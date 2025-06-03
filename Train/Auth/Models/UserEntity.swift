import Foundation

/// Represents a user account in the Train app
struct UserEntity: Codable, Identifiable, Equatable {
    /// Firebase UID
    let id: String
    
    /// User's email address
    var email: String
    
    /// User's display name (optional)
    var displayName: String?
    
    /// User's first name (optional)
    var firstName: String?
    
    /// User's last name (optional)
    var lastName: String?
    
    /// User's subscription tier
    var tier: SubscriptionTier
    
    /// Account creation date
    var createdAt: Date
    
    /// Last login date
    var lastLoginAt: Date
    
    /// Date of the user's last post to the social feed
    var lastPostDate: Date?
    
    /// IDs of users this user follows
    var following: [String] = []
    
    /// Count of users following this user (we don't store the actual followers for privacy)
    var followerCount: Int = 0
    
    /// User's username for identification in the app
    var username: String
    
    /// Whether the user has opted-in to receive marketing emails
    var marketingOptIn: Bool = false
    
    /// Whether the user has unlocked the social feed today
    var hasFeedUnlockedToday: Bool {
        guard let lastPostDate = lastPostDate else { return false }
        return Calendar.current.isDateInToday(lastPostDate)
    }
    
    /// User's subscription tier
    enum SubscriptionTier: String, Codable, CaseIterable {
        case free
        case pro
        case premium
        
        /// Features available for each tier
        var features: [Feature] {
            switch self {
            case .free:
                return [.basicPlans, .workoutTracking, .socialFeed]
            case .pro:
                return [.basicPlans, .workoutTracking, .customPlans, .analytics, .socialFeed]
            case .premium:
                return [.basicPlans, .workoutTracking, .customPlans, .analytics, .advancedProgression, .exportData, .socialFeed]
            }
        }
        
        /// Display name for the tier
        var displayName: String {
            switch self {
            case .free: return "Free"
            case .pro: return "Pro"
            case .premium: return "Premium"
            }
        }
        
        /// Description of the tier
        var description: String {
            switch self {
            case .free: return "Basic workout tracking"
            case .pro: return "Custom plans and analytics"
            case .premium: return "Advanced progression and data export"
            }
        }
    }
    
    /// Features available in the app
    enum Feature: String, CaseIterable {
        case basicPlans = "Basic Plans"
        case workoutTracking = "Workout Tracking"
        case customPlans = "Custom Plans"
        case analytics = "Analytics"
        case advancedProgression = "Advanced Progression"
        case exportData = "Data Export"
        case socialFeed = "Social Feed"
        
        /// Description of the feature
        var description: String {
            switch self {
            case .basicPlans: return "Access to pre-made workout plans"
            case .workoutTracking: return "Track your workouts and progress"
            case .customPlans: return "Create and customize your own workout plans"
            case .analytics: return "Detailed analytics and insights"
            case .advancedProgression: return "Advanced progression algorithms"
            case .exportData: return "Export your data in various formats"
            case .socialFeed: return "Connect with other users and share your progress"
            }
        }
    }
    
    /// Create a new user entity
    /// - Parameters:
    ///   - id: Firebase UID
    ///   - email: User's email address
    ///   - displayName: User's display name (optional)
    ///   - tier: User's subscription tier (defaults to free)
    ///   - createdAt: Account creation date (defaults to now)
    ///   - lastLoginAt: Last login date (defaults to now)
    ///   - lastPostDate: Date of the user's last post to the social feed (optional)
    ///   - following: IDs of users this user follows (defaults to empty array)
    ///   - followerCount: Count of users following this user (defaults to 0)
    ///   - username: User's username (optional)
    ///   - marketingOptIn: Whether the user has opted-in to marketing emails (defaults to false)
    init(
        id: String,
        email: String,
        displayName: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        tier: SubscriptionTier = .free,
        createdAt: Date = Date(),
        lastLoginAt: Date = Date(),
        lastPostDate: Date? = nil,
        following: [String] = [],
        followerCount: Int = 0,
        username: String = "",
        marketingOptIn: Bool = false
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.firstName = firstName
        self.lastName = lastName
        self.tier = tier
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.lastPostDate = lastPostDate
        self.following = following
        self.followerCount = followerCount
        self.username = username
        self.marketingOptIn = marketingOptIn
    }
    
    /// Updates the last login time to now
    func updatedLoginTime() -> UserEntity {
        var updated = self
        updated.lastLoginAt = Date()
        return updated
    }
}
