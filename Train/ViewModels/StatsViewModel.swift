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
        refreshMuscleGroupVolumeData()
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
        
        // Filter to only include completed workouts with valid dates
        let validWorkouts = allWorkouts.filter { $0.isComplete && $0.scheduledDate != nil }
        
        for workout in validWorkouts {
            // We've already filtered for non-nil dates
            let workoutDate = workout.scheduledDate!
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
        
        // Get completed workouts for current week only
        let currentWeekWorkouts = workoutsInRange(from: weekStart, to: nextWeekStart, completed: true)
        
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
        // Get completed workouts with valid dates
        let validWorkouts = completedWorkouts()
        
        var maxByExercise: [String: OneRepMaxData] = [:]
        
        // Process workouts to find best 1RMs
        processWorkoutsForOneRepMax(validWorkouts, into: &maxByExercise)
        
        // Convert to array and sort by estimated 1RM
        oneRepMaxData = Array(maxByExercise.values).sorted { $0.estimatedOneRM > $1.estimatedOneRM }
    }
    
    /// Process workouts to find best one-rep max values
    /// - Parameters:
    ///   - workouts: List of workouts to process
    ///   - maxByExercise: Dictionary to store results in
    private func processWorkoutsForOneRepMax(_ workouts: [WorkoutEntity], into maxByExercise: inout [String: OneRepMaxData]) {
        for workout in workouts {
            // We've already filtered for valid dates in completedWorkouts()
            let workoutDate = workout.scheduledDate!
            
            for exercise in workout.exercises where isValidExerciseForCalculation(exercise) {
                let exerciseName = exercise.movement.movementType.rawValue
                
                // Cache completed sets for better performance
                let validSets = exercise.sets.filter { 
                    $0.isComplete && $0.weight > 0 && $0.completedReps > 0 
                }
                
                // Find the set with the best 1RM
                var bestSet: (set: ExerciseSetEntity, oneRM: Double)? = nil
                
                for set in validSets {
                    let oneRM = calculateEstimatedOneRepMax(weight: set.weight, reps: set.completedReps)
                    
                    if bestSet == nil || oneRM > bestSet!.oneRM {
                        bestSet = (set, oneRM)
                    }
                }
                
                // Update the maxByExercise dictionary if we found a better 1RM
                if let best = bestSet, 
                   best.oneRM > (maxByExercise[exerciseName]?.estimatedOneRM ?? 0) {
                    
                    maxByExercise[exerciseName] = OneRepMaxData(
                        exercise: exercise.movement,
                        weight: best.set.weight,
                        reps: best.set.completedReps,
                        estimatedOneRM: best.oneRM,
                        date: workoutDate
                    )
                }
            }
        }
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
    
    // MARK: - Data Validation and Safety
    
    // MARK: - Workout Filtering Helpers
    
    /// Returns filtered workouts based on provided criteria
    /// - Parameters:
    ///   - completed: Whether to include only completed workouts
    ///   - startDate: Optional start date for filtering (inclusive)
    ///   - endDate: Optional end date for filtering (inclusive)
    /// - Returns: Array of workouts matching the criteria
    private func filteredWorkouts(completed: Bool = false, from startDate: Date? = nil, to endDate: Date? = nil) -> [WorkoutEntity] {
        // Start with all workouts
        let allWorkouts = getAllWorkouts()
        
        // Apply filters
        return allWorkouts.compactMap { workout in
            // Filter out workouts without dates
            guard let workoutDate = workout.scheduledDate else {
                #if DEBUG
                print("Warning: Found workout without scheduled date: \(workout.title)")
                #endif
                return nil
            }
            
            // Filter by completion status if requested
            if completed && !workout.isComplete {
                return nil
            }
            
            // Filter by date range if provided
            if let start = startDate, workoutDate < start {
                return nil
            }
            
            if let end = endDate, workoutDate > end {
                return nil
            }
            
            return workout
        }
    }
    
    /// Returns all workouts with valid dates
    private func validWorkouts() -> [WorkoutEntity] {
        return filteredWorkouts()
    }
    
    /// Returns completed workouts with valid dates
    private func completedWorkouts() -> [WorkoutEntity] {
        return filteredWorkouts(completed: true)
    }
    
    /// Returns workouts within a specific date range
    private func workoutsInRange(from startDate: Date, to endDate: Date, completed: Bool = false) -> [WorkoutEntity] {
        return filteredWorkouts(completed: completed, from: startDate, to: endDate)
    }
    
    /// Returns all workouts from current and past plans
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
    
    /// Validates if an exercise has valid data for volume calculations
    private func isValidExerciseForCalculation(_ exercise: ExerciseInstanceEntity) -> Bool {
        // Check if exercise has any sets
        if exercise.sets.isEmpty {
            #if DEBUG
            print("Warning: Found exercise without sets: \(exercise.movement.name)")
            #endif
            return false
        }
        return true
    }
    
    private func calculateWorkoutVolume(_ workout: WorkoutEntity) -> Double {
        var totalVolume = 0.0
        
        // Only process exercises with valid data
        for exercise in workout.exercises where isValidExerciseForCalculation(exercise) {
            totalVolume += calculateExerciseVolume(exercise)
        }
        
        return totalVolume
    }
    
    private func calculateExerciseVolume(_ exercise: ExerciseInstanceEntity) -> Double {
        // Cache the complete sets to avoid repeated filtering
        let completeSets = exercise.sets.filter { $0.isComplete }
        
        // Sum up the volume for each completed set
        return completeSets.reduce(0.0) { totalVolume, set in
            totalVolume + calculateSetVolume(set)
        }
    }
    
    private func monthsForTimeRange(_ range: TimeRange) -> Int {
        switch range {
        case .threeMonths: return 3
        case .sixMonths: return 6
        case .twelveMonths: return 12
        }
    }
    
    // MARK: - Date Range Helpers
    
    /// Creates an array of dates for the past N weeks from a reference date
    /// - Parameters:
    ///   - weekCount: Number of weeks to include (including current week)
    ///   - fromDate: Reference date (defaults to today)
    /// - Returns: Array of dates representing week start dates, or nil if calculation fails
    private func weekStartDates(pastWeeks weekCount: Int, from fromDate: Date = Date()) -> [Date]? {
        let calendar = Calendar.current
        
        // Get the start of the reference week
        let currentWeekStart = calendar.startOfWeekWithFallback(for: fromDate)
        
        // Calculate the earliest date to include (weekCount-1 weeks ago)
        guard let earliestDate = calendar.date(byAdding: .weekOfYear, value: -(weekCount-1), to: currentWeekStart) else {
            return nil
        }
        
        var weekStarts: [Date] = []
        var weekIterator = earliestDate
        
        // Build array of week start dates
        while weekIterator <= currentWeekStart {
            weekStarts.append(weekIterator)
            
            // Safely get the next week's start date
            if let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: weekIterator) {
                weekIterator = nextWeek
            } else {
                break
            }
        }
        
        return weekStarts.isEmpty ? nil : weekStarts
    }
    
    /// Creates a dictionary of initialized buckets for each week and muscle group
    /// - Parameter weekStarts: Array of week start dates
    /// - Returns: Dictionary mapping weeks to muscle groups to initial values
    private func initializeWeeklyMuscleGroupBuckets(for weekStarts: [Date]) -> [Date: [MuscleGroup: Double]] {
        var buckets: [Date: [MuscleGroup: Double]] = [:]
        
        // Initialize all weeks with zero sets for all muscle groups
        for weekStart in weekStarts {
            var muscleData: [MuscleGroup: Double] = [:]
            for muscle in MuscleGroup.allCases {
                muscleData[muscle] = 0.0
            }
            buckets[weekStart] = muscleData
        }
        
        return buckets
    }
    
    /// Update muscle group set counts from a completed exercise
    /// - Parameters:
    ///   - exercise: The exercise to process
    ///   - weekStart: The week start date for this exercise
    ///   - buckets: The dictionary to update
    private func updateSetCounts(from exercise: ExerciseInstanceEntity, forWeek weekStart: Date, in buckets: inout [Date: [MuscleGroup: Double]]) {
        // Skip incomplete exercises
        guard exercise.isComplete else { return }
        
        // Cache completed sets count for performance
        let completedSets = Double(exercise.sets.filter { $0.isComplete }.count)
        
        // Add full count to primary muscles
        for muscle in exercise.movement.primaryMuscles {
            if var muscleData = buckets[weekStart] {
                muscleData[muscle, default: 0] += completedSets
                buckets[weekStart] = muscleData
            }
        }
        
        // Add half count to secondary muscles
        for muscle in exercise.movement.secondaryMuscles {
            if var muscleData = buckets[weekStart] {
                muscleData[muscle, default: 0] += completedSets * 0.5
                buckets[weekStart] = muscleData
            }
        }
    }
    
    /// Refresh weekly sets per muscle group data (up to 10 weeks)
    private func refreshWeeklyMuscleGroupSets() {
        // Get week start dates for the last 10 weeks
        guard let weekStarts = weekStartDates(pastWeeks: 10) else {
            // If date calculation fails, initialize with empty data
            weeklyMuscleGroupSets = MuscleGroup.allCases.reduce(into: [:]) { result, muscle in 
                result[muscle] = [] 
            }
            return
        }
        
        // Create initialized buckets for each week and muscle group
        var setsByWeekAndMuscleGroup = initializeWeeklyMuscleGroupBuckets(for: weekStarts)
        
        // Get all completed workouts with valid dates
        let validWorkouts = completedWorkouts()
        
        // Calculate earliest date to consider
        let earliestDate = weekStarts.first!
        
        // Process workouts to collect set data
        for workout in validWorkouts {
            // We already filtered for valid dates in completedWorkouts()
            let workoutDate = workout.scheduledDate!
            
            // Skip workouts outside our timeframe
            if workoutDate < earliestDate { continue }
            
            // Find the week this workout belongs to
            let weekStart = Calendar.current.startOfWeekWithFallback(for: workoutDate)
            
            // Only process weeks that are in our pre-built array
            guard setsByWeekAndMuscleGroup[weekStart] != nil else { continue }
            
            // Process each exercise in the workout
            for exercise in workout.exercises where isValidExerciseForCalculation(exercise) {
                updateSetCounts(from: exercise, forWeek: weekStart, in: &setsByWeekAndMuscleGroup)
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
