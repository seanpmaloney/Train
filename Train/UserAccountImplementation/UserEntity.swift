import Foundation

/// Represents a user account in the Train app
struct UserEntity: Codable, Identifiable, Equatable {
    /// Firebase UID
    let id: String
    
    /// User's email address
    var email: String
    
    /// User's display name (optional)
    var displayName: String?
    
    /// User's subscription tier
    var tier: SubscriptionTier
    
    /// Account creation date
    var createdAt: Date
    
    /// Last login date
    var lastLoginAt: Date
    
    /// User's subscription tier
    enum SubscriptionTier: String, Codable, CaseIterable {
        case free
        case pro
        case premium
        
        /// Features available for each tier
        var features: [Feature] {
            switch self {
            case .free:
                return [.basicPlans, .workoutTracking]
            case .pro:
                return [.basicPlans, .workoutTracking, .customPlans, .analytics]
            case .premium:
                return [.basicPlans, .workoutTracking, .customPlans, .analytics, .advancedProgression, .exportData]
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
        
        /// Description of the feature
        var description: String {
            switch self {
            case .basicPlans: return "Access to pre-made workout plans"
            case .workoutTracking: return "Track your workouts and progress"
            case .customPlans: return "Create and customize your own workout plans"
            case .analytics: return "Detailed analytics and insights"
            case .advancedProgression: return "Advanced progression algorithms"
            case .exportData: return "Export your data in various formats"
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
    init(
        id: String,
        email: String,
        displayName: String? = nil,
        tier: SubscriptionTier = .free,
        createdAt: Date = Date(),
        lastLoginAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.tier = tier
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
    }
}
