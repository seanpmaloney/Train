import Foundation
import SwiftUI

class PlanSummaryViewModel: ObservableObject {
    @Published var planName: String
    @Published var notes: String = ""
    @Published var startDate = Date()
    
    private let weeks: [[PlanEditorViewModel.DayPlan]]
    private let template: PlanTemplate?
    
    init(weeks: [[PlanEditorViewModel.DayPlan]], template: PlanTemplate?) {
        self.weeks = weeks
        self.template = template
        self.planName = template?.title ?? "Custom Plan"
    }
    
    var totalWeeks: Int {
        weeks.count
    }
    
    var daysPerWeek: Int {
        weeks.first?.filter { !$0.movements.isEmpty }.count ?? 0
    }
    
    var primaryMuscleEmphasis: [MuscleGroup: Int] {
        var emphasis: [MuscleGroup: Int] = [:]
        
        // Count all primary muscles across all movements
        for week in weeks {
            for day in week {
                for movement in day.movements {
                    for muscle in movement.primaryMuscles {
                        emphasis[muscle, default: 0] += 1
                    }
                }
            }
        }
        
        return emphasis
    }
    
    var topMuscleGroups: [MuscleGroup] {
        primaryMuscleEmphasis
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }
    
    func createPlan() -> TrainingPlanEntity {
        let plan = TrainingPlanEntity(
            name: planName,
            notes: notes.isEmpty ? nil : notes,
            startDate: startDate
        )
        
        // Add workouts
        for (weekIndex, week) in weeks.enumerated() {
            for (dayIndex, day) in week.enumerated() where !day.movements.isEmpty {
                let workoutDate = Calendar.current.date(
                    byAdding: .day,
                    value: weekIndex * 7 + dayIndex,
                    to: startDate
                ) ?? startDate
                
                let workout = WorkoutEntity(
                    title: "\(planName) - \(day.label)",
                    description: "Week \(weekIndex + 1), \(day.label)",
                    scheduledDate: workoutDate,
                    exercises: day.movements.map { movement in
                        ExerciseInstanceEntity(
                            movement: movement,
                            exerciseType: template?.goal == .strength ? "Strength" : "Hypertrophy",
                            sets: (0..<3).map { _ in // Default to 3 sets, could be made configurable
                                ExerciseSetEntity(
                                    weight: 0,
                                    completedReps: 0,
                                    targetReps: template?.goal == .strength ? 5 : 10,
                                    isComplete: false
                                )
                            }
                        )
                    }
                )
                plan.workouts.append(workout)
            }
        }
        
        return plan
    }
}
