import Foundation
import HealthKit

class WorkoutEntity: ObservableObject, Identifiable, Codable {
    let id: UUID
    @Published var title: String
    @Published var description: String
    @Published var isComplete: Bool
    @Published var scheduledDate: Date?
    @Published var exercises: [ExerciseInstanceEntity]
    weak var trainingPlan: TrainingPlanEntity?
    
    // Feedback properties
    var preWorkoutFeedback: PreWorkoutFeedback?
    var postWorkoutFeedback: PostWorkoutFeedback?
    
    init(title: String, description: String, isComplete: Bool, scheduledDate: Date? = nil, exercises: [ExerciseInstanceEntity] = [], preWorkoutFeedback: PreWorkoutFeedback? = nil, postWorkoutFeedback: PostWorkoutFeedback? = nil) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.isComplete = isComplete
        self.scheduledDate = scheduledDate
        self.exercises = exercises
        self.preWorkoutFeedback = preWorkoutFeedback
        self.postWorkoutFeedback = postWorkoutFeedback
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case isComplete
        case scheduledDate
        case exercises
        case preWorkoutFeedback
        case postWorkoutFeedback
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.isComplete = try container.decode(Bool.self, forKey: .isComplete)
        self.scheduledDate = try container.decodeIfPresent(Date.self, forKey: .scheduledDate)
        self.exercises = try container.decode([ExerciseInstanceEntity].self, forKey: .exercises)
        self.preWorkoutFeedback = try container.decodeIfPresent(PreWorkoutFeedback.self, forKey: .preWorkoutFeedback)
        self.postWorkoutFeedback = try container.decodeIfPresent(PostWorkoutFeedback.self, forKey: .postWorkoutFeedback)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(isComplete, forKey: .isComplete)
        try container.encodeIfPresent(scheduledDate, forKey: .scheduledDate)
        try container.encode(exercises, forKey: .exercises)
        try container.encodeIfPresent(preWorkoutFeedback, forKey: .preWorkoutFeedback)
        try container.encodeIfPresent(postWorkoutFeedback, forKey: .postWorkoutFeedback)
    }
    
    func copy() -> WorkoutEntity {
        let copiedExercises = exercises.map { exercise -> ExerciseInstanceEntity in
            let copiedSets = exercise.sets.map { $0.copy() as! ExerciseSetEntity }
            return ExerciseInstanceEntity(
                movement: exercise.movement,
                exerciseType: exercise.exerciseType,
                sets: copiedSets,
                feedback: exercise.feedback
            )
        }
        
        return WorkoutEntity(
            title: self.title,
            description: self.description,
            isComplete: self.isComplete,
            scheduledDate: self.scheduledDate,
            exercises: copiedExercises,
            preWorkoutFeedback: self.preWorkoutFeedback,
            postWorkoutFeedback: self.postWorkoutFeedback
        )
    }
}

/// Represents a workout from Apple Health (external to our app)
struct ExternalWorkout: Identifiable, Hashable {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let workoutType: HKWorkoutActivityType
    let sourceName: String
    let averageHeartRate: Double?
    let totalEnergyBurned: Double? // in calories
    
    init(from hkWorkout: HKWorkout) {
        self.id = UUID()
        self.startDate = hkWorkout.startDate
        self.endDate = hkWorkout.endDate
        self.duration = hkWorkout.duration
        self.workoutType = hkWorkout.workoutActivityType
        self.sourceName = hkWorkout.sourceRevision.source.name
        
        // Extract heart rate statistics
        if let heartRateStats = hkWorkout.statistics(for: HKQuantityType(.heartRate)) {
            self.averageHeartRate = heartRateStats.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        } else {
            self.averageHeartRate = nil
        }
        
        // Extract total energy burned
        self.totalEnergyBurned = hkWorkout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie())
        
        // Map HKWorkoutActivityType to readable title
        self.title = Self.getWorkoutTitle(for: hkWorkout.workoutActivityType)
    }
    
    private static func getWorkoutTitle(for activityType: HKWorkoutActivityType) -> String {
        switch activityType {
        case .running:
            return "Running"
        case .walking:
            return "Walking"
        case .cycling:
            return "Cycling"
        case .swimming:
            return "Swimming"
        case .yoga:
            return "Yoga"
        case .pilates:
            return "Pilates"
        case .functionalStrengthTraining:
            return "Strength Training"
        case .traditionalStrengthTraining:
            return "Weightlifting"
        case .crossTraining:
            return "Cross Training"
        case .highIntensityIntervalTraining:
            return "HIIT"
        case .dance:
            return "Dance"
        case .boxing:
            return "Boxing"
        case .martialArts:
            return "Martial Arts"
        case .tennis:
            return "Tennis"
        case .basketball:
            return "Basketball"
        case .soccer:
            return "Soccer"
        case .americanFootball:
            return "Football"
        case .baseball:
            return "Baseball"
        case .golf:
            return "Golf"
        case .hiking:
            return "Hiking"
        case .climbing:
            return "Climbing"
        case .rowing:
            return "Rowing"
        case .elliptical:
            return "Elliptical"
        case .stairClimbing:
            return "Stair Climbing"
        case .stepTraining:
            return "Step Training"
        case .flexibility:
            return "Stretching"
        case .cooldown:
            return "Cool Down"
        case .wheelchairWalkPace:
            return "Wheelchair"
        case .wheelchairRunPace:
            return "Wheelchair Run"
        default:
            return "Workout"
        }
    }
    
    /// Maps HKWorkoutActivityType to our TrainingType for calendar display
    var trainingType: TrainingType {
        switch workoutType {
        case .functionalStrengthTraining, .traditionalStrengthTraining, .crossTraining:
            return .strength
        case .running, .cycling, .swimming, .rowing, .elliptical:
            return .endurance
        case .yoga, .pilates, .flexibility, .cooldown:
            return .mobility
        case .highIntensityIntervalTraining:
            return .hybrid
        default:
            return .strength // Default fallback
        }
    }
    
    /// Formatted duration string
    var durationString: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Formatted time string
    var timeString: String {
        startDate.formatted(date: .omitted, time: .shortened)
    }
    
    /// Primary metric to display (heart rate or calories)
    var primaryMetric: String? {
        // Show heart rate if available (for both strength and cardio)
        if let heartRate = averageHeartRate {
            return "\(Int(heartRate)) bpm avg"
        }
        
        // Fallback to calories if heart rate isn't available
        if let calories = totalEnergyBurned, calories > 0 {
            return "\(Int(calories)) cal"
        }
        
        return nil
    }
    
    /// Whether this is a strength training workout
    private var isStrengthWorkout: Bool {
        switch workoutType {
        case .functionalStrengthTraining, .traditionalStrengthTraining, .crossTraining:
            return true
        default:
            return false
        }
    }
}
