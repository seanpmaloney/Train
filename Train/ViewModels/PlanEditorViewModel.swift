import Foundation
import SwiftUI

@MainActor
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
        var selectedDay: WorkoutDay?
        var movements: [MovementConfig]
    }
    
    init(template: PlanTemplate?, appState: AppState) {
        self.template = template
        self.appState = appState
        
        // Initialize with empty days
        self.days = Calendar.current.weekdaySymbols.map { dayName in
            DayPlan(label: dayName, selectedDay: nil, movements: [])
        }
        
        // Set initial plan name if template is provided
        if let template = template {
            self.planName = template.title
            
            // Setup template-based days
            setupDaysFromTemplate(template)
        }
    }
    
    /// Sets up the days array with exercises from the template
    private func setupDaysFromTemplate(_ template: PlanTemplate) {
        // Clear existing days array
        days.removeAll()
        
        // Create days from the template's workout days
        for (index, workoutDay) in template.workoutDays.enumerated() {
            // Get the corresponding scheduled day if available
            let scheduledDay = index < template.scheduleDays.count ? template.scheduleDays[index] : nil
            
            // Create a new day with the template's label
            var newDay = DayPlan(
                label: workoutDay.label,
                selectedDay: scheduledDay,
                movements: []
            )
            
            // Add each exercise from the template to this day
            for exercise in workoutDay.exercises {
                // Use the template's exercise's movement and extract sets/reps information
                let movement = exercise.movement
                let firstSet = exercise.sets.first
                let targetSets = exercise.sets.count
                let targetReps = firstSet?.targetReps ?? 10
                
                // Create a movement config from this information
                let config = MovementConfig(
                    movement: movement,
                    targetSets: targetSets,
                    targetReps: targetReps
                )
                
                newDay.movements.append(config)
            }
            
            days.append(newDay)
        }
        
        // Sort days by their weekday values
        sortDaysByWeekday()
    }
    
    /// Updates the selected day for a given day plan and reorders days
    func updateSelectedDay(_ day: WorkoutDay?, for dayIndex: Int) {
        guard days.indices.contains(dayIndex) else { return }
        
        // If the day is already selected for another day plan, clear it
        if let day = day {
            for index in days.indices where index != dayIndex {
                if days[index].selectedDay == day {
                    days[index].selectedDay = nil
                }
            }
        }
        
        // Update the selected day
        days[dayIndex].selectedDay = day
        
        // Sort days by their weekday values
        sortDaysByWeekday()
        
        objectWillChange.send()
    }
    
    /// Sorts days by their weekday values (days without a selected day come last)
    private func sortDaysByWeekday() {
        days.sort { lhs, rhs in
            // Days without a selected day come last
            guard let lhsDay = lhs.selectedDay else { return false }
            guard let rhsDay = rhs.selectedDay else { return true }
            
            // Sort by weekday value
            return lhsDay.rawValue < rhsDay.rawValue
        }
    }
    
    /// Returns all days that are currently selected
    var selectedDays: [WorkoutDay] {
        days.compactMap { $0.selectedDay }
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
        
        // Array to collect all workouts we're creating
        var allWorkouts = [[WorkoutEntity]]()
        
        // Generate workouts for each week
        let calendar = Calendar.current
        
        // Get start of week for plan start date
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: planStartDate))!
        
        // For each week in the plan
        for weekIndex in 0..<planLength {
            // For each day that has movements
            var weekOfWorkouts = [WorkoutEntity]()
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
                
                // Calculate the date for this workout based on user-selected day or template schedule
                var workoutDate: Date?
                
                if let selectedDay = day.selectedDay {
                    // Use the user-selected day for this workout
                    // Calculate date for this workout by finding the correct weekday
                    var dateComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startOfWeek)
                    dateComponents.weekday = selectedDay.calendarWeekday
                    dateComponents.weekOfYear! += weekIndex // Advance to correct week
                    
                    workoutDate = calendar.date(from: dateComponents)
                } else if let template = template, dayIndex < template.workoutDays.count, dayIndex < template.scheduleDays.count {
                    // Fall back to template's scheduled days if no user selection
                    let workoutDay = template.scheduleDays[dayIndex]
                    
                    // Calculate date for this workout
                    var dateComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startOfWeek)
                    dateComponents.weekday = workoutDay.calendarWeekday
                    dateComponents.weekOfYear! += weekIndex // Advance to correct week
                    
                    workoutDate = calendar.date(from: dateComponents)
                } else {
                    // Fallback to original behavior if no template or index out of bounds
                    var dateComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startOfWeek)
                    dateComponents.weekday = dayIndex + 1 // weekday is 1-based
                    dateComponents.weekOfYear! += weekIndex // Advance to correct week
                    
                    workoutDate = calendar.date(from: dateComponents)
                }
                
                if let workoutDate = workoutDate {
                    // Only include workouts on or after the plan start date
                    if workoutDate >= planStartDate {
                        workout.scheduledDate = workoutDate
                        weekOfWorkouts.append(workout)
                    }
                }
            }
            allWorkouts.append(weekOfWorkouts)
        }
        
        // Use the centralized method to finalize the plan
        appState.finalizePlan(plan, workouts: allWorkouts)
    }
}
