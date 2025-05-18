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
            plan.weeklyWorkouts.append([])
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
                    isComplete: false,
                    scheduledDate: date,
                    exercises: exercises
                )
                plan.weeklyWorkouts[weekIndex].append(workout)
            }
        }

        if config.includeDeload {
            let deloadWorkouts = generateDeloadWeek(
                config: config,
                allMovements: allMovements,
                startDate: calendar.date(byAdding: .day, value: config.weeks * 7, to: config.startDate)!
            )
            plan.weeklyWorkouts.append(deloadWorkouts)
        }

        return plan
    }

    private struct VolumeTargets {
        static let emphasisMinSets = 10
        static let emphasisMaxSets = 20
        static let maintenanceMinSets = 4
        static let maintenanceMaxSets = 6
    }
    
    private struct MuscleVolumeInfo {
        var currentSets: Int = 0
        let targetSets: Int
        let isEmphasis: Bool
        
        var hasMetMinimumVolume: Bool {
            if isEmphasis {
                return currentSets >= VolumeTargets.emphasisMinSets
            }
            return currentSets >= VolumeTargets.maintenanceMinSets
        }
        
        var hasMetMaximumVolume: Bool {
            if isEmphasis {
                return currentSets >= VolumeTargets.emphasisMaxSets
            }
            return currentSets >= VolumeTargets.maintenanceMaxSets
        }
    }
    
    private func calculateWeeklyVolumeDistribution(for muscleGroups: [[MuscleGroup]], isEmphasis: (MuscleGroup) -> Bool) -> [MuscleGroup: Int] {
        // Initialize volume tracking for all muscle groups
        var volumeInfo = Dictionary(uniqueKeysWithValues: MuscleGroup.allCases.map { muscle in
            let emphasis = isEmphasis(muscle)
            let targetSets = emphasis ? VolumeTargets.emphasisMaxSets : VolumeTargets.maintenanceMaxSets
            return (muscle, MuscleVolumeInfo(targetSets: targetSets, isEmphasis: emphasis))
        })
        
        // Count frequency of each muscle group's appearance in the week
        let appearances = Dictionary(grouping: muscleGroups.flatMap { $0 }) { $0 }
            .mapValues { $0.count }
        
        // Calculate sets per appearance to distribute volume evenly
        var distribution: [MuscleGroup: Int] = [:]
        
        for muscle in MuscleGroup.allCases {
            let info = volumeInfo[muscle]!
            let daysScheduled = appearances[muscle] ?? 0
            
            if daysScheduled > 0 {
                // Calculate base sets per day to meet minimum volume
                let minSets = info.isEmphasis ? VolumeTargets.emphasisMinSets : VolumeTargets.maintenanceMinSets
                let maxSets = info.isEmphasis ? VolumeTargets.emphasisMaxSets : VolumeTargets.maintenanceMaxSets
                
                // Distribute sets evenly across available days
                let setsPerDay = min(
                    maxSets / daysScheduled, // Don't exceed max volume
                    max(2, minSets / daysScheduled) // At least 2 sets per day when scheduled
                )
                
                distribution[muscle] = setsPerDay
            } else {
                distribution[muscle] = 0
            }
        }
        
        return distribution
    }

    private func generateSchedule(config: PlanConfig) -> [[[MuscleGroup]]] {
        let splitDays = splitMuscleGroupMapping(for: config.split)
        var schedule: [[[MuscleGroup]]] = []
        
        // Handle custom split differently
        if config.split == .custom {
            // Use existing round-robin logic for custom splits
            let emphasis = config.emphasisMuscles
            var allMuscles = emphasis
            let all = MuscleGroup.allCases
            let nonEmphasis = all.filter { group in
                !emphasis.contains(where: { $0 == group })
            }
            allMuscles += nonEmphasis

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
        
        // For predefined splits, use the mapping
        for _ in 0..<config.weeks {
            var week: [[MuscleGroup]] = []
            for dayIndex in 0..<config.daysPerWeek {
                // For 5-day split, use all 5 days if daysPerWeek allows
                if config.split == .fiveDaySplit && dayIndex < splitDays.count {
                    week.append(splitDays[dayIndex])
                } else {
                    // For other splits, rotate through the available days
                    week.append(splitDays[dayIndex % splitDays.count])
                }
            }
            schedule.append(week)
        }
        
        return schedule
    }
    
    private func splitMuscleGroupMapping(for split: SplitStyle) -> [[MuscleGroup]] {
        switch split {
        case .pushPullLegs:
            return [
                [.chest, .shoulders, .triceps],     // Push
                [.back, .biceps],                   // Pull
                [.quads, .hamstrings, .glutes]      // Legs
            ]
            
        case .upperLower:
            return [
                [.chest, .back, .shoulders, .biceps, .triceps],  // Upper
                [.quads, .hamstrings, .calves, .glutes]         // Lower
            ]
            
        case .fiveDaySplit:
            return [
                [.chest, .shoulders, .triceps],     // Push
                [.back, .biceps],                   // Pull
                [.quads, .hamstrings, .glutes],     // Legs
                [.chest, .back, .shoulders],        // Upper
                [.quads, .hamstrings, .calves]     // Lower
            ]
            
        case .fullBody:
            return [MuscleGroup.allCases.filter { $0 != .abs }]  // Full body, abs excluded as they can be added to any day
            
        case .custom:
            return []  // Empty array for custom splits - will be handled separately in generateSchedule
        }
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
                        ExerciseSetEntity(weight: 100.0, targetReps: 8, isComplete: false)
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
                isComplete: false,
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
                    ExerciseSetEntity(weight: 100.0, targetReps: reps, isComplete: false)
                }

                instances.append(ExerciseInstanceEntity(movement: movement, exerciseType: type, sets: sets))
            }
        }

        return instances
    }
}
