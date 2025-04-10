//
//  TrainingPlanBuilder.swift
//  Train
//
//  Created by Sean Maloney on 4/9/25.
//

import Foundation

class TrainingPlanBuilder {
    enum Goal: String, Codable, CaseIterable {
        case strength = "Strength"
        case hypertrophy = "Hypertrophy"
        case hybrid = "Hybrid"
    }

    enum SplitStyle: String, Codable, CaseIterable {
        case fullBody = "Full Body"
        case upperLower = "Upper/Lower"
        case pushPullLegs = "Push/Pull/Legs"
        case fiveDaySplit = "5-Day Split"
        case custom = "Custom"
    }

    struct PlanConfig {
        let weeks: Int
        let goal: Goal
        let daysPerWeek: Int
        let split: SplitStyle
        let emphasisMuscles: [MuscleGroup]
        let startDate: Date
        let includeDeload: Bool
    }

    func generatePlan(config: PlanConfig, from allMovements: [MovementEntity]) -> TrainingPlanEntity {
        let plan = TrainingPlanEntity(name: "Custom Plan", startDate: config.startDate)
        let schedule = generateSchedule(config: config)
        let calendar = Calendar.current

        for (weekIndex, weekSchedule) in schedule.enumerated() {
            for (dayIndex, muscleGroups) in weekSchedule.enumerated() {
                let date = calendar.date(byAdding: .day, value: weekIndex * 7 + dayIndex, to: config.startDate)!
                let exercises = createExercises(
                    for: muscleGroups,
                    allMovements: allMovements,
                    goal: config.goal,
                    week: weekIndex,
                    totalWeeks: config.weeks
                )
                let workout = WorkoutEntity(
                    title: "Day \(weekIndex * 7 + dayIndex + 1)",
                    description: "Auto-generated workout",
                    scheduledDate: date,
                    exercises: exercises
                )
                plan.workouts.append(workout)
            }
        }

        if config.includeDeload {
            let deloadWorkouts = generateDeloadWeek(
                config: config,
                allMovements: allMovements,
                startDate: calendar.date(byAdding: .day, value: config.weeks * 7, to: config.startDate)!
            )
            plan.workouts.append(contentsOf: deloadWorkouts)
        }

        return plan
    }

    private func generateSchedule(config: PlanConfig) -> [[[MuscleGroup]]] {
        // Simple round-robin allocation based on split
        let emphasis = config.emphasisMuscles
        var allMuscles = emphasis
        let all = MuscleGroup.allCases
        let nonEmphasis = all.filter { group in
            !emphasis.contains(where: { $0 == group })
        }
        allMuscles += nonEmphasis

        var schedule: [[[MuscleGroup]]] = []
        for _ in 0..<config.weeks {
            var week: [[MuscleGroup]] = []
            for day in 0..<config.daysPerWeek {
                let group = allMuscles[day % allMuscles.count]
                week.append([group])
            }
            schedule.append(week)
        }

        return schedule
    }

    private func generateDeloadWeek(config: PlanConfig, allMovements: [MovementEntity], startDate: Date) -> [WorkoutEntity] {
        let schedule = generateSchedule(config: PlanConfig(
            weeks: 1,
            goal: config.goal,
            daysPerWeek: config.daysPerWeek,
            split: config.split,
            emphasisMuscles: config.emphasisMuscles,
            startDate: startDate,
            includeDeload: false
        ))
        
        let calendar = Calendar.current
        var deloadWorkouts: [WorkoutEntity] = []
        
        for (dayIndex, muscleGroups) in schedule[0].enumerated() {
            let date = calendar.date(byAdding: .day, value: dayIndex, to: startDate)!
            var exercises: [ExerciseInstanceEntity] = []
            
            // Only pick 1-2 exercises per muscle group for deload
            for muscle in muscleGroups {
                let movements = allMovements.filter { $0.muscleGroups.contains(where: { $0 == muscle }) }
                if let movement = movements.randomElement() {
                    let sets = (0..<(Int.random(in: 1...2))).map { _ in
                        ExerciseSetEntity(weight: 100.0, completedReps: 0, targetReps: 8, isComplete: false)
                    }
                    
                    exercises.append(ExerciseInstanceEntity(
                        movement: movement,
                        exerciseType: "Deload",
                        sets: sets
                    ))
                }
            }
            
            let workout = WorkoutEntity(
                title: "Deload Day \(dayIndex + 1)",
                description: "Deload workout - reduced volume, higher RIR",
                scheduledDate: date,
                exercises: exercises
            )
            deloadWorkouts.append(workout)
        }
        
        return deloadWorkouts
    }

    private func createExercises(for muscleGroups: [MuscleGroup], allMovements: [MovementEntity], goal: Goal, week: Int, totalWeeks: Int) -> [ExerciseInstanceEntity] {
        var instances: [ExerciseInstanceEntity] = []

        for muscle in muscleGroups {
            let movements = allMovements.filter { $0.muscleGroups.contains(where: { $0 == muscle }) }
            if let movement = movements.randomElement() {
                let baseSets = 2
                let addedVolume = min(week, 3) // increase up to 2 sets
                let repsInReserve = max(3 - week, 0) // decrease RIR
                let reps = goal == .strength ? 5 : 10
                let type = goal == .strength ? "Strength" : goal == .hypertrophy ? "Hypertrophy" : "Hybrid"

                let sets = (0..<(baseSets + addedVolume)).map { _ in
                    ExerciseSetEntity(weight: 100.0, completedReps: 0, targetReps: reps, isComplete: false)
                }

                instances.append(ExerciseInstanceEntity(movement: movement, exerciseType: type, sets: sets))
            }
        }

        return instances
    }
}
