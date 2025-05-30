import Foundation
import SwiftUI
import Combine

@MainActor
/// View model for the Stats page, handling data processing and calculations
class StatsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Weekly volume data over time
    @Published private(set) var weeklyVolumeData: [VolumeDataPoint] = []
    
    /// Muscle group volume data for the current week
    @Published private(set) var muscleGroupVolumeData: [MuscleGroupVolumeData] = []
    
    /// Sets per muscle group over time
    @Published private(set) var muscleGroupSetsOverTime: [MuscleGroup: [SetOverTimeDataPoint]] = [:]
    
    /// Weekly sets per muscle group
    @Published private(set) var weeklyMuscleGroupSets: [MuscleGroup: [WeeklySetDataPoint]] = [:]
    
    /// Currently expanded muscle group (for detail view)
    @Published var expandedMuscleGroup: MuscleGroup?
    
    /// Estimated 1RM data for tracked exercises
    @Published private(set) var oneRepMaxData: [OneRepMaxData] = []
    
    /// Strength trend data for major movement categories
    @Published private(set) var strengthTrendData: [StrengthTrendCategory] = []
    
    // No longer using time range selector
    
    // MARK: - Private Properties
    
    /// Reference to the app state
    private let appState: AppState
    
    /// Cancellables for subscription management
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(appState: AppState) {
        self.appState = appState
        
        // Set up listeners for app state changes
        setupListeners()
        
        // Initial data load
        refreshAllData()
    }
    
    // MARK: - Public Methods
    
    /// Refreshes all stats data
    func refreshAllData() {
        refreshWeeklyMuscleGroupSets()
        refreshOneRepMaxData()
    }
    
    /// Calculate volume (sets × reps × weight) for a set
    func calculateSetVolume(_ set: ExerciseSetEntity) -> Double {
        return Double(set.isComplete ? set.completedReps : 0) * set.weight
    }
    
    /// Calculate estimated 1RM using the Epley formula: weight * (1 + reps/30)
    func calculateEstimatedOneRepMax(weight: Double, reps: Int) -> Double {
        if reps < 1 { return 0 }
        return weight * (1.0 + Double(reps) / 30.0)
    }
    
    // MARK: - Private Methods
    
    private func setupListeners() {
        // Listen for changes in current plan
        appState.$currentPlan
            .sink { [weak self] _ in
                self?.refreshAllData()
            }
            .store(in: &cancellables)
        
        // Listen for changes in past plans
        appState.$pastPlans
            .sink { [weak self] _ in
                self?.refreshAllData()
            }
            .store(in: &cancellables)
    }
    
    private func refreshWeeklyVolumeData() {
        // Get all workouts from past plans and current plan
        let allWorkouts = getAllWorkouts()
        
        // Group workouts by week
        let calendar = Calendar.current
        var volumeByWeek: [Date: Double] = [:]
        
        for workout in allWorkouts where workout.isComplete {
            // Get week start date for the workout (safely)
            guard let workoutDate = workout.scheduledDate else { continue }
            let weekStart = calendar.startOfWeekWithFallback(for: workoutDate)
            
            // Calculate total volume for workout
            let workoutVolume = calculateWorkoutVolume(workout)
            
            // Add to volume for this week
            volumeByWeek[weekStart, default: 0] += workoutVolume
        }
        
        // Convert to ordered array of data points
        let sortedWeeks = volumeByWeek.keys.sorted()
        
        // Limit to the last 12 weeks
        let weeks = sortedWeeks.suffix(12)
        
        weeklyVolumeData = weeks.map { weekStart in
            VolumeDataPoint(date: weekStart, volume: volumeByWeek[weekStart] ?? 0)
        }
    }
    
    private func refreshMuscleGroupVolumeData() {
        // Get all workouts from the current week
        let today = Date()
        let calendar = Calendar.current
        let weekStart = calendar.startOfWeekWithFallback(for: today)
        guard let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else {
            // Handle the error case with empty data
            muscleGroupVolumeData = []
            return
        }
        
        let currentWeekWorkouts = getAllWorkouts().filter { workout in
            guard let date = workout.scheduledDate else { return false }
            return workout.isComplete && date >= weekStart && date < nextWeekStart
        }
        
        // Calculate volume for each muscle group
        var volumeByMuscleGroup: [MuscleGroup: Double] = [:]
        var setCountByMuscleGroup: [MuscleGroup: Int] = [:]
        
        for workout in currentWeekWorkouts {
            for exercise in workout.exercises {
                // Calculate volume for this exercise
                let exerciseVolume = calculateExerciseVolume(exercise)
                let exerciseSets = exercise.sets.count
                
                // Primary muscles count as 1 set
                for muscle in exercise.movement.primaryMuscles {
                    volumeByMuscleGroup[muscle, default: 0] += exerciseVolume
                    setCountByMuscleGroup[muscle, default: 0] += exerciseSets
                }
                
                // Secondary muscles count as 0.5 sets
                for muscle in exercise.movement.secondaryMuscles {
                    volumeByMuscleGroup[muscle, default: 0] += exerciseVolume * 0.5
                    setCountByMuscleGroup[muscle, default: 0] += Int(Double(exerciseSets) * 0.5)
                }
            }
        }
        
        // Create muscle group volume data
        muscleGroupVolumeData = MuscleGroup.allCases.map { muscle in
            let volume = volumeByMuscleGroup[muscle] ?? 0
            let setCount = setCountByMuscleGroup[muscle] ?? 0
            let isWithinOptimalRange = isVolumeWithinOptimalRangeForHypertrophy(muscle: muscle, volume: volume)
            let optimalMinSets = optimalMinSetsForHypertrophy(muscle: muscle)
            let optimalMaxSets = optimalMaxSetsForHypertrophy(muscle: muscle)
            return MuscleGroupVolumeData(muscle: muscle, volume: volume, setCount: setCount, isWithinOptimalRange: isWithinOptimalRange, optimalMinSets: optimalMinSets, optimalMaxSets: optimalMaxSets)
        }.sorted { $0.setCount > $1.setCount } // Sort by set count, highest first
    }
    
    private func refreshOneRepMaxData() {
        // Get all workouts
        let allWorkouts = getAllWorkouts()
        
        // Track the best estimated 1RM for each unique exercise
        var maxByExercise: [String: OneRepMaxData] = [:]
        
        for workout in allWorkouts where workout.isComplete {
            for exercise in workout.exercises {
                let exerciseName = exercise.movement.movementType.rawValue
                
                // Find the set with the best possible 1RM
                var bestOneRM = 0.0
                var bestSet: ExerciseSetEntity?
                
                for set in exercise.sets where set.isComplete {
                    let oneRM = calculateEstimatedOneRepMax(weight: set.weight, reps: set.completedReps)
                    if oneRM > bestOneRM {
                        bestOneRM = oneRM
                        bestSet = set
                    }
                }
                
                // If we found a valid set
                if let set = bestSet, bestOneRM > 0 {
                    // If this is a new best or the first time seeing this exercise
                    if maxByExercise[exerciseName] == nil || bestOneRM > (maxByExercise[exerciseName]?.estimatedOneRM ?? 0) {
                        maxByExercise[exerciseName] = OneRepMaxData(
                            exercise: exercise.movement,
                            weight: set.weight,
                            reps: set.completedReps,
                            estimatedOneRM: bestOneRM,
                            date: workout.scheduledDate ?? Date()
                        )
                    }
                }
            }
        }
        
        // Convert to array and sort by estimated 1RM
        oneRepMaxData = Array(maxByExercise.values).sorted { $0.estimatedOneRM > $1.estimatedOneRM }
    }
    
    private func isVolumeWithinOptimalRangeForHypertrophy(muscle: MuscleGroup, volume: Double) -> Bool {
        // Optimal weekly training volume for hypertrophy (rough approximation)
        // This would ideally be calibrated based on research and user experience
        switch muscle {
        case .chest, .back, .quads, .hamstrings, .glutes:
            // Larger muscle groups
            return volume >= 10000 && volume <= 20000
        case .shoulders, .biceps, .triceps, .traps:
            // Medium muscle groups
            return volume >= 7000 && volume <= 15000
        case .calves, .forearms, .abs, .obliques, .lowerBack, .neck:
            // Smaller muscle groups
            return volume >= 5000 && volume <= 10000
        case .unknown:
            return volume >= 5000 && volume <= 10000
        }
    }
    
    private func optimalMinSetsForMaintenance(muscle: MuscleGroup) -> Int {
        return muscle.trainingGuidelines.minMaintenanceSets
    }
    
    private func optimalMaxSetsForMaintenance(muscle: MuscleGroup) -> Int {
        return muscle.trainingGuidelines.maxMaintenanceSets
    }
    
    private func optimalMinSetsForHypertrophy(muscle: MuscleGroup) -> Int {
        return muscle.trainingGuidelines.minHypertrophySets
    }
    
    private func optimalMaxSetsForHypertrophy(muscle: MuscleGroup) -> Int {
        return muscle.trainingGuidelines.maxHypertrophySets
    }
    
    private func getAllWorkouts() -> [WorkoutEntity] {
        var allWorkouts = [WorkoutEntity]()
        
        // Add workouts from current plan if available
        if let currentPlan = appState.currentPlan {
            allWorkouts.append(contentsOf: currentPlan.weeklyWorkouts.flatMap {$0})
        }
        
        // Add workouts from past plans
        for plan in appState.pastPlans {
            allWorkouts.append(contentsOf: plan.weeklyWorkouts.flatMap {$0})
        }
        
        return allWorkouts
    }
    
    private func calculateWorkoutVolume(_ workout: WorkoutEntity) -> Double {
        var totalVolume = 0.0
        
        for exercise in workout.exercises {
            totalVolume += calculateExerciseVolume(exercise)
        }
        
        return totalVolume
    }
    
    private func calculateExerciseVolume(_ exercise: ExerciseInstanceEntity) -> Double {
        var totalVolume = 0.0
        
        for set in exercise.sets where set.isComplete {
            totalVolume += calculateSetVolume(set)
        }
        
        return totalVolume
    }
    
    private func monthsForTimeRange(_ range: TimeRange) -> Int {
        switch range {
        case .threeMonths: return 3
        case .sixMonths: return 6
        case .twelveMonths: return 12
        }
    }
    
    /// Refresh weekly sets per muscle group data (up to 10 weeks)
    private func refreshWeeklyMuscleGroupSets() {
        // Get all completed workouts
        let allWorkouts = getAllWorkouts().filter { $0.isComplete }
        
        // Create a date range for the last 10 weeks
        let calendar = Calendar.current
        let today = Date()
        
        // Get the start of the current week with fallback
        let currentWeekStart = calendar.startOfWeekWithFallback(for: today)
        
        // Calculate date from 9 weeks ago
        guard let tenWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -9, to: currentWeekStart) else {
            // If date calculation fails, initialize with empty data and return
            weeklyMuscleGroupSets = MuscleGroup.allCases.reduce(into: [:]) { result, muscle in
                result[muscle] = []
            }
            return
        }
        
        // Build array of week start dates for consistent data points
        var weekStarts: [Date] = []
        var weekIterator = tenWeeksAgo
        
        // Generate all week start dates between 10 weeks ago and now
        while weekIterator <= currentWeekStart {
            weekStarts.append(weekIterator)
            
            // Safely get the next week's start date
            if let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: weekIterator) {
                weekIterator = nextWeek
            } else {
                // If date calculation fails, break to prevent infinite loop
                break
            }
        }
        
        // Handle edge case where we couldn't generate any week dates
        if weekStarts.isEmpty {
            weeklyMuscleGroupSets = MuscleGroup.allCases.reduce(into: [:]) { result, muscle in
                result[muscle] = []
            }
            return
        }
        
        // Pre-initialize a dictionary for each week with empty muscle group data
        var setsByWeekAndMuscleGroup: [Date: [MuscleGroup: Double]] = [:]
        
        // Initialize all weeks with zero sets for all muscle groups
        for weekStart in weekStarts {
            var muscleData: [MuscleGroup: Double] = [:]
            for muscle in MuscleGroup.allCases {
                muscleData[muscle] = 0.0
            }
            setsByWeekAndMuscleGroup[weekStart] = muscleData
        }
        
        // Process workouts to collect set data
        for workout in allWorkouts {
            // Only consider workouts with valid dates
            guard let workoutDate = workout.scheduledDate else { continue }
            
            // Find the week this workout belongs to
            let weekStart = calendar.startOfWeekWithFallback(for: workoutDate)
            
            // Skip workouts outside our timeframe
            if weekStart < tenWeeksAgo { continue }
            
            // Only process weeks that are in our pre-built array (handles edge cases)
            guard let _ = setsByWeekAndMuscleGroup[weekStart] else { continue }
            
            // Process each exercise in the workout
            for exercise in workout.exercises {
                // Skip incomplete exercises
                guard exercise.isComplete else { continue }
                
                // Count completed sets
                let completedSets = Double(exercise.sets.filter { $0.isComplete }.count)
                
                // Add full count to primary muscles
                for muscle in exercise.movement.primaryMuscles {
                    if var muscleData = setsByWeekAndMuscleGroup[weekStart] {
                        muscleData[muscle, default: 0] += completedSets
                        setsByWeekAndMuscleGroup[weekStart] = muscleData
                    }
                }
                
                // Add half count to secondary muscles
                for muscle in exercise.movement.secondaryMuscles {
                    if var muscleData = setsByWeekAndMuscleGroup[weekStart] {
                        muscleData[muscle, default: 0] += completedSets * 0.5
                        setsByWeekAndMuscleGroup[weekStart] = muscleData
                    }
                }
            }
        }
        
        // Convert to the final data structure
        weeklyMuscleGroupSets = MuscleGroup.allCases.reduce(into: [:]) { result, muscle in
            let weeklyData = weekStarts.map { weekStart in
                WeeklySetDataPoint(
                    weekStart: weekStart,
                    sets: setsByWeekAndMuscleGroup[weekStart]?[muscle] ?? 0.0
                )
            }
            result[muscle] = weeklyData
        }
    }
    
    private func refreshMuscleGroupSetsOverTime() {
        // Get all workouts from past plans and current plan
        let allWorkouts = getAllWorkouts()
        
        // Group workouts by month
        let calendar = Calendar.current
        var setsByMonthAndMuscleGroup: [Date: [MuscleGroup: Int]] = [:]
        
        for workout in allWorkouts where workout.isComplete {
            // Get month start date for the workout
            let monthStart = calendar.startOfMonth(for: workout.scheduledDate ?? Date())
            
            // Calculate total sets for each muscle group in this workout
            var setsByMuscleGroup: [MuscleGroup: Int] = [:]
            
            for exercise in workout.exercises {
                // Get all muscle groups (primary and secondary)
                let allMuscles = exercise.movement.primaryMuscles + exercise.movement.secondaryMuscles
                
                // Calculate sets for this exercise
                let exerciseSets = exercise.sets.count
                
                // Primary muscles count as 1 set, secondary as 0.5
                for muscle in exercise.movement.primaryMuscles {
                    setsByMuscleGroup[muscle, default: 0] += exerciseSets
                }
                
                // Secondary muscles get less weight (0.5 per set)
                for muscle in exercise.movement.secondaryMuscles {
                    setsByMuscleGroup[muscle, default: 0] += Int(Double(exerciseSets) * 0.5)
                }
            }
            
            // Add to sets for this month
            for (muscle, sets) in setsByMuscleGroup {
                setsByMonthAndMuscleGroup[monthStart, default: [:]][muscle, default: 0] += sets
            }
        }
        
        // Convert to ordered array of data points
        let sortedMonths = setsByMonthAndMuscleGroup.keys.sorted()
        
        // Limit to the last 12 months
        let months = sortedMonths.suffix(12)
        
        muscleGroupSetsOverTime = MuscleGroup.allCases.reduce(into: [:]) { result, muscle in
            let setsOverTime = months.map { monthStart in
                SetOverTimeDataPoint(date: monthStart, sets: setsByMonthAndMuscleGroup[monthStart]?[muscle] ?? 0)
            }
            result[muscle] = setsOverTime
        }
    }
}

// MARK: - Supporting Models

extension StatsViewModel {
    /// Time range for data visualization
    enum TimeRange: String, CaseIterable, Identifiable {
        case threeMonths = "3M"
        case sixMonths = "6M"
        case twelveMonths = "12M"
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .threeMonths: return "3 Months"
            case .sixMonths: return "6 Months"
            case .twelveMonths: return "12 Months"
            }
        }
    }
    
    /// Data point for volume over time
    struct VolumeDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let volume: Double
        
        var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    /// Data for muscle group volume
    struct MuscleGroupVolumeData: Identifiable {
        let id = UUID()
        let muscle: MuscleGroup
        let volume: Double
        let setCount: Int
        let isWithinOptimalRange: Bool
        let optimalMinSets: Int
        let optimalMaxSets: Int
    }
    
    /// Data for one-rep max estimates
    struct OneRepMaxData: Identifiable {
        let id = UUID()
        let exercise: MovementEntity
        let weight: Double
        let reps: Int
        let estimatedOneRM: Double
        let date: Date
        
        var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
    
    /// Strength category definition
    struct StrengthCategory {
        let name: String
        let movements: [MovementType]
    }
    
    /// Data for strength trends by category
    struct StrengthTrendCategory: Identifiable {
        let id = UUID()
        let name: String
        let dataPoints: [StrengthDataPoint]
        
        var hasData: Bool {
            return !dataPoints.isEmpty
        }
    }
    
    /// Data point for strength over time
    struct StrengthDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
        
        var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            return formatter.string(from: date)
        }
    }
    
    /// Data point for sets over time
    struct SetOverTimeDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let sets: Int
        
        var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            return formatter.string(from: date)
        }
    }
    
    /// Data point for weekly sets
    struct WeeklySetDataPoint: Identifiable {
        let id = UUID()
        let weekStart: Date
        let sets: Double // Using double to support partial sets (0.5 for secondary muscles)
        
        var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: weekStart)
        }
    }
}

// MARK: - Helper Extensions

extension Calendar {
    
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
