import Foundation

/// Intensity rating for exercise feedback
enum ExerciseIntensity: String, Codable, CaseIterable {
    case tooEasy
    case moderate
    case challenging
    case failed
    
    var description: String {
        switch self {
        case .tooEasy: return "Too Easy"
        case .moderate: return "Moderate"
        case .challenging: return "Challenging"
        case .failed: return "Failed/Too Hard"
        }
    }
}

/// Set volume rating for exercise feedback
enum SetVolumeRating: String, Codable, CaseIterable {
    case tooEasy
    case moderate
    case challenging
    case tooMuch
    
    var description: String {
        switch self {
        case .tooEasy: return "Too Few Sets"
        case .moderate: return "Good Amount"
        case .challenging: return "Challenging"
        case .tooMuch: return "Too Many Sets"
        }
    }
}

/// Available joint areas that could experience pain
enum JointArea: String, Codable, CaseIterable {
    case knee
    case elbow
    case shoulder
    
    var description: String {
        switch self {
        case .knee: return "Knee"
        case .elbow: return "Elbow"
        case .shoulder: return "Shoulder"
        }
    }
}

/// Fatigue levels for post-workout feedback
enum FatigueLevel: String, Codable, CaseIterable {
    case fresh
    case normal
    case wiped
    case completelyDrained
    
    var description: String {
        switch self {
        case .fresh: return "Still Fresh"
        case .normal: return "Normal Fatigue"
        case .wiped: return "Wiped Out"
        case .completelyDrained: return "Completely Drained"
        }
    }
}

// Base class for all workout feedback
class WorkoutFeedback: Identifiable, Codable {
    let id: UUID
    let workoutId: UUID
    let date: Date
    let feedbackType: FeedbackType
    
    enum FeedbackType: String, Codable {
        case pre
        case exercise
        case post
    }
    
    enum CodingKeys: String, CodingKey {
        case id, workoutId, date, feedbackType
    }
    
    init(workoutId: UUID, feedbackType: FeedbackType) {
        self.id = UUID()
        self.workoutId = workoutId
        self.date = Date()
        self.feedbackType = feedbackType
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        workoutId = try container.decode(UUID.self, forKey: .workoutId)
        date = try container.decode(Date.self, forKey: .date)
        feedbackType = try container.decode(FeedbackType.self, forKey: .feedbackType)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(workoutId, forKey: .workoutId)
        try container.encode(date, forKey: .date)
        try container.encode(feedbackType, forKey: .feedbackType)
    }
}

// Pre-workout feedback
final class PreWorkoutFeedback: WorkoutFeedback {
    var soreMuscles: [MuscleGroup]
    var jointPainAreas: [JointArea]
    
    enum CodingKeys: String, CodingKey {
        case soreMuscles, jointPainAreas
    }
    
    init(workoutId: UUID, soreMuscles: [MuscleGroup] = [], jointPainAreas: [JointArea] = []) {
        self.soreMuscles = soreMuscles
        self.jointPainAreas = jointPainAreas
        super.init(workoutId: workoutId, feedbackType: .pre)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        soreMuscles = try container.decode([MuscleGroup].self, forKey: .soreMuscles)
        jointPainAreas = try container.decode([JointArea].self, forKey: .jointPainAreas)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(soreMuscles, forKey: .soreMuscles)
        try container.encode(jointPainAreas, forKey: .jointPainAreas)
    }
}

// Exercise-specific feedback
final class ExerciseFeedback: WorkoutFeedback {
    let exerciseId: UUID
    var intensity: ExerciseIntensity
    var setVolume: SetVolumeRating
    
    enum CodingKeys: String, CodingKey {
        case exerciseId, intensity, setVolume
    }
    
    init(exerciseId: UUID, workoutId: UUID, intensity: ExerciseIntensity, setVolume: SetVolumeRating) {
        self.exerciseId = exerciseId
        self.intensity = intensity
        self.setVolume = setVolume
        super.init(workoutId: workoutId, feedbackType: .exercise)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        exerciseId = try container.decode(UUID.self, forKey: .exerciseId)
        intensity = try container.decode(ExerciseIntensity.self, forKey: .intensity)
        setVolume = try container.decode(SetVolumeRating.self, forKey: .setVolume)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(exerciseId, forKey: .exerciseId)
        try container.encode(intensity, forKey: .intensity)
        try container.encode(setVolume, forKey: .setVolume)
    }
}

// Post-workout feedback
final class PostWorkoutFeedback: WorkoutFeedback {
    var sessionFatigue: FatigueLevel
    
    enum CodingKeys: String, CodingKey {
        case sessionFatigue
    }
    
    init(workoutId: UUID, sessionFatigue: FatigueLevel) {
        self.sessionFatigue = sessionFatigue
        super.init(workoutId: workoutId, feedbackType: .post)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionFatigue = try container.decode(FatigueLevel.self, forKey: .sessionFatigue)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sessionFatigue, forKey: .sessionFatigue)
    }
}
