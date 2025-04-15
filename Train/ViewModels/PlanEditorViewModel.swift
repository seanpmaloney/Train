import Foundation
import SwiftUI

class PlanEditorViewModel: ObservableObject {
    @Published var days: [DayPlan]
    @Published var planLength: Int = 4
    @Published var planName: String = ""
    @Published var useProgressiveOverload: Bool = false
    
    var planStartDate: Date {
        get { _planStartDate }
        set { _planStartDate = Calendar.current.startOfDay(for: newValue) }
    }

    @Published private var _planStartDate: Date = Calendar.current.startOfDay(for: Date())
    
    let template: PlanTemplate?
    let appState: AppState
    
    let minWeeks = 3
    let maxWeeks = 8
    let dayNames = Calendar.current.weekdaySymbols
    
    struct MovementConfig: Identifiable {
        let id = UUID()
        let movement: MovementEntity
        var targetSets: Int
        var targetReps: Int
        
        init(movement: MovementEntity, targetSets: Int = 3, targetReps: Int = 10) {
            self.movement = movement
            self.targetSets = targetSets
            self.targetReps = targetReps
        }
    }
    
    struct DayPlan: Identifiable {
        let id = UUID()
        let label: String
        var movements: [MovementConfig]
    }
    
    init(template: PlanTemplate?, appState: AppState) {
        self.template = template
        self.appState = appState
        self.days = Calendar.current.weekdaySymbols.map { dayName in
            DayPlan(label: dayName, movements: [])
        }
        
        // If template provided, set initial name
        if let template = template {
            self.planName = template.title
        }
    }
    
    func addMovement(_ movement: [MovementEntity], to dayIndex: Int) {
        guard days.indices.contains(dayIndex) else { return }
        for movement in movement {
            let config = MovementConfig(movement: movement)
            days[dayIndex].movements.append(config)
        }
        objectWillChange.send()
    }
    
    func removeMovement(at indexSet: IndexSet, from dayIndex: Int) {
        guard days.indices.contains(dayIndex) else { return }
        days[dayIndex].movements.remove(atOffsets: indexSet)
        objectWillChange.send()
    }
    
    func moveMovement(from source: IndexSet, to destination: Int, in dayIndex: Int) {
        guard days.indices.contains(dayIndex) else { return }
        days[dayIndex].movements.move(fromOffsets: source, toOffset: destination)
        objectWillChange.send()
    }
    
    func updateSets(_ sets: Int, for movementId: UUID, in dayIndex: Int) {
        guard days.indices.contains(dayIndex),
              let movementIndex = days[dayIndex].movements.firstIndex(where: { $0.id == movementId }) else { return }
        days[dayIndex].movements[movementIndex].targetSets = min(sets, 20)
        objectWillChange.send()
    }
    
    func updateReps(_ reps: Int, for movementId: UUID, in dayIndex: Int) {
        guard days.indices.contains(dayIndex),
              let movementIndex = days[dayIndex].movements.firstIndex(where: { $0.id == movementId }) else { return }
        days[dayIndex].movements[movementIndex].targetReps = min(reps, 100)
        objectWillChange.send()
    }
    
    var generatedWeeks: [[DayPlan]] {
        let weeks = Array(repeating: days, count: planLength)
        return weeks
    }
    
    var totalMovementCount: Int {
        days.reduce(0) { count, day in
            count + day.movements.count
        }
    }
    
    // MARK: - Plan Finalization
    
    func finalizePlan() {
        // Count active days (days with movements)
        let activeDays = days.filter { !$0.movements.isEmpty }.count
        
        // Create the training plan
        let plan = TrainingPlanEntity(
            name: planName,
            notes: nil,
            startDate: planStartDate,
            daysPerWeek: activeDays,
            isCompleted: false
        )
        
        // Generate workouts for each week
        let calendar = Calendar.current
        
        // Get start of week for plan start date
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: planStartDate))!
        
        // For each week in the plan
        for weekIndex in 0..<planLength {
            // For each day that has movements
            for (dayIndex, day) in days.enumerated() where !day.movements.isEmpty {
                // Create workout for this day
                let workout = WorkoutEntity(
                    title: "\(planName) - \(day.label)",
                    description: "Week \(weekIndex + 1) - \(day.label)",
                    isComplete: false
                )
                
                // Add exercises to workout
                for movement in day.movements {
                    // Calculate progressive overload reps if enabled
                    let targetReps = useProgressiveOverload ? 
                        movement.targetReps + weekIndex : movement.targetReps
                    
                    var exerciseSets = [ExerciseSetEntity]()
                    for _ in 0..<movement.targetSets {
                        let setEntity = ExerciseSetEntity(targetReps: targetReps)
                        exerciseSets.append(setEntity)
                    }
                    
                    let exercise = ExerciseInstanceEntity(
                        movement: movement.movement,
                        exerciseType: "strength", // Default to strength type
                        sets: exerciseSets,
                        note: nil
                    )
                    workout.exercises.append(exercise)
                }
                
                // Calculate the date for this workout
                var dateComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startOfWeek)
                dateComponents.weekday = dayIndex + 1 // weekday is 1-based
                dateComponents.weekOfYear! += weekIndex // Advance to correct week
                
                if let workoutDate = calendar.date(from: dateComponents) {
                    // Only include workouts on or after the plan start date
                    if workoutDate >= planStartDate {
                        workout.scheduledDate = workoutDate
                        
                        // Add workout to plan
                        plan.workouts.append(workout)
                        
                        // Schedule workout in calendar
                        appState.scheduleWorkout(workout)
                    }
                }
            }
        }
        
        appState.savePlans()
        
        // Update plan's end date based on last workout
        plan.endDate = plan.calculatedEndDate
        
        // Set as current plan
        appState.setCurrentPlan(plan)
    }
}
