import Foundation
import SwiftUI

@MainActor
class GeneratedPlanEditorViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var planName: String
    @Published var planLength: Int
    @Published var workouts: [WorkoutModel]
    
    // Plan start date with proper getter/setter
    var planStartDate: Date {
        get { _planStartDate }
        set { _planStartDate = Calendar.current.startOfDay(for: newValue) }
    }
    @Published private var _planStartDate: Date
    
    // MARK: - Dependencies & State
    
    private let appState: AppState
    private var trainingPlan: TrainingPlanEntity
    
    // MARK: - Constants
    
    let minWeeks = 3
    let maxWeeks = 8
    
    // MARK: - Nested Types
    
    struct WorkoutModel: Identifiable {
        let id = UUID()
        var title: String
        var dayOfWeek: WorkoutDay?
        var exercises: [ExerciseModel]
    }
    
    struct ExerciseModel: Identifiable {
        let id = UUID()
        let movement: MovementEntity
        var targetSets: Int
        var targetReps: Int
    }
    
    // MARK: - Initialization
    
    init(generatedPlan: TrainingPlanEntity, appState: AppState) {
        self.appState = appState
        self.trainingPlan = generatedPlan
        
        // Initialize with plan data
        self.planName = generatedPlan.name
        self._planStartDate = generatedPlan.startDate ?? Date()
        
        // Start with a default plan length of 4 weeks
        self.planLength = 4
        
        // Initialize workouts collection
        self.workouts = []
        
        // Load workouts from plan
        loadWorkoutsFromPlan()
    }
    
    // MARK: - Data Loading
    
    private func loadWorkoutsFromPlan() {
        // Clear workouts array
        workouts.removeAll()
        
        // First, group workouts by day of week (using only the first week's workouts)
        let calendar = Calendar.current
        
        // Get the first week's worth of workouts, sorted by date
        let sortedWorkouts = trainingPlan.weeklyWorkouts.flatMap {$0}.sorted { workout1, workout2 in
            guard let date1 = workout1.scheduledDate, let date2 = workout2.scheduledDate else {
                return false
            }
            return date1 < date2
        }
        
        // Group by weekday
        var workoutsByDay: [Int: [WorkoutEntity]] = [:]
        
        for workout in sortedWorkouts {
            guard let date = workout.scheduledDate else { continue }
            
            // Get weekday component (1-7, where 1 is Sunday)
            let weekday = calendar.component(.weekday, from: date)
            
            // Check if this date is within first week
            if let firstDate = sortedWorkouts.first?.scheduledDate,
               let daysSinceStart = calendar.dateComponents([.day], from: firstDate, to: date).day,
               daysSinceStart < 7 {
                
                // Add to appropriate day collection
                if workoutsByDay[weekday] == nil {
                    workoutsByDay[weekday] = []
                }
                workoutsByDay[weekday]?.append(workout)
            }
        }
        
        // Create WorkoutModel for each day's workouts
        for (weekday, dayWorkouts) in workoutsByDay {
            guard let firstWorkout = dayWorkouts.first else { continue }
            
            // Convert workout to our model
            var exercises: [ExerciseModel] = []
            
            for exercise in firstWorkout.exercises {
                let exerciseModel = ExerciseModel(
                    movement: exercise.movement,
                    targetSets: exercise.sets.count,
                    targetReps: exercise.sets.first?.targetReps ?? 10
                )
                exercises.append(exerciseModel)
            }
            
            // Create workout model with day mapping
            let workoutModel = WorkoutModel(
                title: firstWorkout.title,
                dayOfWeek: WorkoutDay.fromWeekday(weekday),
                exercises: exercises
            )
            
            workouts.append(workoutModel)
        }
        
        // Sort workouts by weekday
        workouts.sort { first, second in
            let firstDay = first.dayOfWeek?.rawValue ?? 0
            let secondDay = second.dayOfWeek?.rawValue ?? 0
            return firstDay < secondDay
        }
    }
    
    // MARK: - Plan Modification
    
    /// Updates the workout day for a specific workout
    func updateSelectedDay(_ day: WorkoutDay?, for workoutIndex: Int) {
        guard workouts.indices.contains(workoutIndex) else { return }
        
        // If the day is already selected for another workout, clear it
        if let day = day {
            for index in workouts.indices where index != workoutIndex {
                if workouts[index].dayOfWeek == day {
                    workouts[index].dayOfWeek = nil
                }
            }
        }
        
        // Set the new day
        workouts[workoutIndex].dayOfWeek = day
        
        // Resort the workouts by weekday
        sortWorkoutsByDay()
    }
    
    /// Returns all currently selected days
    var selectedDays: [WorkoutDay] {
        workouts.compactMap { $0.dayOfWeek }
    }
    
    /// Sorts workouts by their weekday values for display
    private func sortWorkoutsByDay() {
        workouts.sort { first, second in
            let firstDay = first.dayOfWeek?.rawValue ?? 0
            let secondDay = second.dayOfWeek?.rawValue ?? 0
            return firstDay < secondDay
        }
    }
    
    /// Adds a movement to a specific workout
    func addMovement(_ movement: MovementEntity, to workoutIndex: Int) {
        guard workouts.indices.contains(workoutIndex) else { return }
        
        // Create a new exercise model
        let exercise = ExerciseModel(
            movement: movement,
            targetSets: 3, // Default values
            targetReps: 10
        )
        
        // Add to workout
        workouts[workoutIndex].exercises.append(exercise)
        
        objectWillChange.send()
    }
    
    /// Removes a movement from a workout
    func removeMovement(at exerciseIndex: Int, from workoutIndex: Int) {
        guard workouts.indices.contains(workoutIndex),
              workouts[workoutIndex].exercises.indices.contains(exerciseIndex) else { return }
        
        workouts[workoutIndex].exercises.remove(at: exerciseIndex)
        objectWillChange.send()
    }
    
    /// Removes a movement from a workout
    func replaceMovement(at exerciseIndex: Int, from workoutIndex: Int, newMovement: MovementEntity) {
        guard workouts.indices.contains(workoutIndex),
              workouts[workoutIndex].exercises.indices.contains(exerciseIndex) else {
            return
        }
        
        // Create a new exercise model, preserving the original sets/reps if possible
        let originalExercise = workouts[workoutIndex].exercises[exerciseIndex]
        let replacement = ExerciseModel(
            movement: newMovement,
            targetSets: originalExercise.targetSets,
            targetReps: originalExercise.targetReps
        )
        
        // Replace at the same index to maintain order
        workouts[workoutIndex].exercises[exerciseIndex] = replacement
        objectWillChange.send()
    }
    
    /// Updates the number of sets for an exercise
    func updateSets(_ sets: Int, for exerciseId: UUID, in workoutIndex: Int) {
        guard workouts.indices.contains(workoutIndex) else { return }
        
        if let exerciseIndex = workouts[workoutIndex].exercises.firstIndex(where: { $0.id == exerciseId }) {
            workouts[workoutIndex].exercises[exerciseIndex].targetSets = min(sets, 20) // Max 20 sets
        }
        
        objectWillChange.send()
    }
    
    /// Updates the number of reps for an exercise
    func updateReps(_ reps: Int, for exerciseId: UUID, in workoutIndex: Int) {
        guard workouts.indices.contains(workoutIndex) else { return }
        
        if let exerciseIndex = workouts[workoutIndex].exercises.firstIndex(where: { $0.id == exerciseId }) {
            workouts[workoutIndex].exercises[exerciseIndex].targetReps = min(reps, 50) // Max 50 reps
        }
        
        objectWillChange.send()
    }
    
    /// Returns the number of weeks in the plan
    var planWeeks: Int {
        max(minWeeks, min(maxWeeks, planLength))
    }
    
    // MARK: - Plan Finalization
    
    /// Saves the plan with all modifications
    func finalizePlan() {
        // Update basic plan details
        trainingPlan.name = planName
        
        // Create array to collect all generated workouts
        var workoutPlan = [[WorkoutEntity]]()
        
        // Get calendar for date calculations
        let calendar = Calendar.current
        
        // Get start of week for plan start date
        let startOfWeek = calendar.startOfWeek(for: planStartDate)
        
        // Create workouts for each week
        for weekIndex in 0..<planLength {
            // For each workout in our model
            var weekOfWorkouts = [WorkoutEntity]()
            for (_, workoutModel) in workouts.enumerated() {
                // Skip if no day selected
                guard let selectedDay = workoutModel.dayOfWeek else { continue }
                
                // Create workout entity for this day
                let workout = WorkoutEntity(
                    title: workoutModel.title,
                    description: "Week \(weekIndex + 1) - \(selectedDay.rawValue)",
                    isComplete: false
                )
                
                // Add exercise instances
                for exerciseModel in workoutModel.exercises {
                    // Create sets for this exercise
                    var exerciseSets = [ExerciseSetEntity]()
                    
                    // Create the sets
                    for _ in 0..<exerciseModel.targetSets {
                        let set = ExerciseSetEntity(targetReps: exerciseModel.targetReps)
                        exerciseSets.append(set)
                    }
                    
                    // Create the exercise instance
                    let exercise = ExerciseInstanceEntity(
                        movement: exerciseModel.movement,
                        exerciseType: "strength", // Default to strength type
                        sets: exerciseSets,
                        note: nil
                    )
                    
                    // Add to workout
                    workout.exercises.append(exercise)
                }
                
                // Calculate date for this workout
                var dateComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startOfWeek)
                dateComponents.weekday = selectedDay.calendarWeekday
                dateComponents.weekOfYear! += weekIndex // Advance to correct week
                
                if let workoutDate = calendar.date(from: dateComponents) {
                    workout.scheduledDate = workoutDate
                    weekOfWorkouts.append(workout)
                }
            }
            workoutPlan.append(weekOfWorkouts)
        }
        
        // Use the centralized method to finalize the plan
        appState.finalizePlan(trainingPlan, workouts: workoutPlan, clear: true)
    }
}
