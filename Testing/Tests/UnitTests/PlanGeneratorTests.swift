import Testing
import Foundation
@testable import Train

struct PlanGeneratorTests {
    @MainActor @Test("Plan has correct properties")
    func planHasCorrectProperties() {
        // Setup test dependencies
        let testContext = TestContext()
        
        // When
        let plan = testContext.sut.generatePlan(input: testContext.planInput, forWeeks: 4)
        
        // Then
        #expect(plan.daysPerWeek == testContext.planInput.trainingDaysPerWeek)
        #expect(plan.trainingGoal == testContext.planInput.goal)
        #expect(plan.prioritizedMuscles == testContext.planInput.prioritizedMuscles)
        
        // Verify prioritized muscles are set to grow
        let priorityPreferences = plan.musclePreferences?.filter {
            testContext.planInput.prioritizedMuscles.contains($0.muscleGroup) && $0.goal == .grow
        }
        #expect(priorityPreferences?.count == testContext.planInput.prioritizedMuscles.count)
    }
    
    @MainActor @Test("Plan creates correct number of workouts")
    func planCreatesCorrectNumberOfWorkouts() {
        // Setup test dependencies
        let testContext = TestContext()
        
        // Given
        let weeks = 3
        
        // When
        let plan = testContext.sut.generatePlan(input: testContext.planInput, forWeeks: weeks)
        
        // Then
        let expectedWorkoutCount = testContext.planInput.trainingDaysPerWeek * weeks
        #expect(plan.weeklyWorkouts.flatMap { $0 }.count == expectedWorkoutCount)
    }
    
    @MainActor @Test("Plan schedules workouts on correct days")
    func planSchedulesWorkoutsCorrectly() {
        // Setup test dependencies
        let testContext = TestContext()
        
        // Given
        let weeks = 2
        let startDate = Date()
        let calendar = Calendar.current
        
        // Create a plan with a specific start date for predictable testing
        let customPlanInput = PlanInput(
            goal: .hypertrophy,
            prioritizedMuscles: [.chest],
            trainingDaysPerWeek: 3,
            workoutDuration: .medium,
            equipment: [.barbell],
            preferredSplit: .fullBody,
            trainingExperience: .beginner
        )
        
        // When
        let plan = testContext.sut.generatePlan(input: customPlanInput, forWeeks: weeks)
        plan.startDate = startDate
        
        // Then
        #expect(plan.weeklyWorkouts.flatMap { $0 }.count == customPlanInput.trainingDaysPerWeek * weeks)
        
        // Verify first week dates
        for dayIndex in 0..<customPlanInput.trainingDaysPerWeek {
            let workout = plan.weeklyWorkouts[0][dayIndex]
            let expectedDate = calendar.date(byAdding: .day, value: dayIndex, to: startDate)
            #expect(workout.scheduledDate?.description == expectedDate?.description)
        }
        
        // Verify second week dates
        for dayIndex in 0..<customPlanInput.trainingDaysPerWeek {
            let workout = plan.weeklyWorkouts[1][dayIndex]
            let expectedDate = calendar.date(byAdding: .day, value: 7 + dayIndex, to: startDate)
            #expect(workout.scheduledDate?.description == expectedDate?.description)
        }
    }
    
    @MainActor @Test("Volume distributed correctly based on split style")
    func volumeDistributionBasedOnSplitStyle() {
        // Setup test dependencies
        let testContext = TestContext()
        let baseInput = testContext.planInput
        
        // Given: Different split styles
        let upperLowerInput = PlanInput(
            goal: baseInput.goal,
            prioritizedMuscles: baseInput.prioritizedMuscles,
            trainingDaysPerWeek: baseInput.trainingDaysPerWeek,
            workoutDuration: baseInput.workoutDuration,
            equipment: baseInput.equipment,
            preferredSplit: .upperLower,
            trainingExperience: baseInput.trainingExperience
        )
        
        let pplInput = PlanInput(
            goal: baseInput.goal,
            prioritizedMuscles: baseInput.prioritizedMuscles,
            trainingDaysPerWeek: baseInput.trainingDaysPerWeek,
            workoutDuration: baseInput.workoutDuration,
            equipment: baseInput.equipment,
            preferredSplit: .pushPullLegs,
            trainingExperience: baseInput.trainingExperience
        )
        
        let fullBodyInput = PlanInput(
            goal: baseInput.goal,
            prioritizedMuscles: baseInput.prioritizedMuscles,
            trainingDaysPerWeek: baseInput.trainingDaysPerWeek,
            workoutDuration: baseInput.workoutDuration,
            equipment: baseInput.equipment,
            preferredSplit: .fullBody,
            trainingExperience: baseInput.trainingExperience
        )
        
        // When: Generate plans for each split
        let upperLowerPlan = testContext.sut.generatePlan(input: upperLowerInput, forWeeks: 1)
        let pplPlan = testContext.sut.generatePlan(input: pplInput, forWeeks: 1)
        let fullBodyPlan = testContext.sut.generatePlan(input: fullBodyInput, forWeeks: 1)
        
        // Then: Verify workouts target the right muscle groups based on split
        
        // Upper/Lower split
        for (i, workout) in upperLowerPlan.weeklyWorkouts.flatMap({ $0 }).enumerated() {
            let dayType = getDayType(day: i, split: .upperLower, totalDays: upperLowerInput.trainingDaysPerWeek)
            let expectedMuscles = getMusclesForDayType(dayType)
            
            // Verify each exercise primarily targets a muscle that belongs in this day's group
            for exercise in workout.exercises {
                let primaryMuscle = getPrimaryMuscle(exercise.movement)
                #expect(expectedMuscles.contains(primaryMuscle))
            }
        }
        
        // Similar verification for PPL split
        for (i, workout) in pplPlan.weeklyWorkouts.flatMap({ $0 }).enumerated() {
            let dayType = getDayType(day: i+1, split: .pushPullLegs, totalDays: pplInput.trainingDaysPerWeek)
            let expectedMuscles = getMusclesForDayType(dayType)
            
            for exercise in workout.exercises {
                let primaryMuscle = getPrimaryMuscle(exercise.movement)
                #expect(expectedMuscles.contains(primaryMuscle))
            }
        }
        
        // Full body should include exercises for multiple muscle areas
        for workout in fullBodyPlan.weeklyWorkouts.flatMap({ $0 }) {
            var targetedMuscleGroups = Set<MuscleGroup>()
            for exercise in workout.exercises {
                targetedMuscleGroups.insert(getPrimaryMuscle(exercise.movement))
            }
            
            // Full body workouts should target at least 4 different muscle groups
            #expect(targetedMuscleGroups.count >= 4)
        }
    }
    
    @MainActor @Test("Volume progresses appropriately across weeks")
    func volumeProgressionAcrossWeeks() {
        // Setup test dependencies
        let testContext = TestContext()
        
        // Given
        let weeks = 4
        
        // When
        let plan = testContext.sut.generatePlan(input: testContext.planInput, forWeeks: weeks)
        
        // Then
        // Group workouts by week
        var workoutsByWeek: [[WorkoutEntity]] = Array(repeating: [], count: weeks)
        
        for workout in plan.weeklyWorkouts.flatMap({ $0 }) {
            guard let date = workout.scheduledDate else {
                #expect(false, "All workouts should have a scheduled date")
                continue
            }
            
            let startDate = plan.startDate
            let days = Calendar.current.dateComponents([.day], from: startDate, to: date).day ?? 0
            let week = days / 7
            
            // Skip if somehow outside our range
            guard week < weeks else { continue }
            
            workoutsByWeek[week].append(workout)
        }
        
        // Verify that volume (total sets) increases each week for prioritized muscles
        var setsByWeekForPrioritizedMuscles: [Int] = Array(repeating: 0, count: weeks)
        
        for (weekIndex, weekWorkouts) in workoutsByWeek.enumerated() {
            for workout in weekWorkouts {
                for exercise in workout.exercises {
                    let primaryMuscle = getPrimaryMuscle(exercise.movement)
                    
                    if testContext.planInput.prioritizedMuscles.contains(primaryMuscle) {
                        setsByWeekForPrioritizedMuscles[weekIndex] += exercise.sets.count
                    }
                }
            }
        }
        
        // Check that each week has more volume than the previous
        for i in 1..<weeks {
            #expect(
                setsByWeekForPrioritizedMuscles[i] >= setsByWeekForPrioritizedMuscles[i-1],
                "Week \(i+1) should have at least as much volume as week \(i) for prioritized muscles"
            )
        }
    }
    
    @MainActor @Test("Experience level affects set and rep ranges")
    func experienceLevelAffectsSetAndRepRanges() {
        // Setup test dependencies
        let testContext = TestContext()
        let baseInput = testContext.planInput
        
        // Given
        let beginnerInput = PlanInput(
            goal: baseInput.goal,
            prioritizedMuscles: baseInput.prioritizedMuscles,
            trainingDaysPerWeek: baseInput.trainingDaysPerWeek,
            workoutDuration: baseInput.workoutDuration,
            equipment: baseInput.equipment,
            preferredSplit: baseInput.preferredSplit,
            trainingExperience: .beginner
        )
        
        let advancedInput = PlanInput(
            goal: baseInput.goal,
            prioritizedMuscles: baseInput.prioritizedMuscles,
            trainingDaysPerWeek: baseInput.trainingDaysPerWeek,
            workoutDuration: baseInput.workoutDuration,
            equipment: baseInput.equipment,
            preferredSplit: baseInput.preferredSplit,
            trainingExperience: .advanced
        )
        
        // When
        let beginnerPlan = testContext.sut.generatePlan(input: beginnerInput, forWeeks: 1)
        let advancedPlan = testContext.sut.generatePlan(input: advancedInput, forWeeks: 1)
        
        // Then
        // Beginners should have fewer sets per exercise
        let beginnerAverageSets = averageSetsPerExercise(in: beginnerPlan)
        let advancedAverageSets = averageSetsPerExercise(in: advancedPlan)
        
        #expect(beginnerAverageSets <= advancedAverageSets)
        
        // Beginners should generally have higher rep targets for compounds
        let beginnerAverageCompoundReps = averageRepsForCompoundExercises(in: beginnerPlan)
        let advancedAverageCompoundReps = averageRepsForCompoundExercises(in: advancedPlan)
        
        #expect(beginnerAverageCompoundReps >= advancedAverageCompoundReps)
    }
    
    @MainActor @Test("Volume increases are distributed across workouts within a week")
    func volumeIncreasesDistributedAcrossWorkouts() {
//        // Setup test dependencies
//        let testContext = TestContext()
//
//        // Given - Create a plan that has two workouts per week
//        let customPlanInput = PlanInput(
//            goal: .hypertrophy,
//            prioritizedMuscles: [.quads, .chest, .biceps],
//            trainingDaysPerWeek: 2,
//            workoutDuration: .medium,
//            equipment: [.barbell, .machine],
//            preferredSplit: .fullBody,
//            trainingExperience: .intermediate
//        )
//
//        let weeks = 2
//        let plan = testContext.sut.generatePlan(input: customPlanInput, forWeeks: weeks)
//
//        // Separate workouts by week
//        var workoutsByWeek: [[WorkoutEntity]] = Array(repeating: [], count: weeks)
//        for workout in plan.workouts {
//            guard let date = workout.scheduledDate else { continue }
//            let daysOffset = Calendar.current.dateComponents([.day], from: plan.startDate, to: date).day ?? 0
//            let weekIndex = daysOffset / 7
//            guard weekIndex < weeks else { continue }
//            workoutsByWeek[weekIndex].append(workout)
//        }
//
//        // Find a prioritized muscle present in week 1
//        let prioritizedMuscles = customPlanInput.prioritizedMuscles
//        var targetMuscle: MuscleGroup? = nil
//        for workout in workoutsByWeek[0] {
//            for exercise in workout.exercises {
//                if let muscle = exercise.movement.primaryMuscles.first, prioritizedMuscles.contains(muscle) {
//                    targetMuscle = muscle
//                    break
//                }
//            }
//            if targetMuscle != nil { break }
//        }
//
//        #expect(targetMuscle != nil, "Expected at least one prioritized muscle to be present in week 1")
//        guard let muscleToTrack = targetMuscle else { return }
//
//        // Count sets for the selected muscle in each week
//        func setsForMuscle(in workouts: [WorkoutEntity]) -> [Int] {
//            return workouts.map { workout in
//                workout.exercises
//                    .filter { $0.movement.primaryMuscles.contains(muscleToTrack) }
//                    .reduce(0) { $0 + $1.sets.count }
//            }
//        }
//
//        let week1SetCounts = setsForMuscle(in: workoutsByWeek[0])
//        let week2SetCounts = setsForMuscle(in: workoutsByWeek[1])
//
//        // Check that total sets increased in week 2
//        let totalIncrease = week2SetCounts.reduce(0, +) - week1SetCounts.reduce(0, +)
//        #expect(totalIncrease > 0, "Total \(muscleToTrack.displayName) set volume should increase in week 2")
//
//        // Check that increase is reasonably distributed
//        let maxDelta = abs(week2SetCounts[0] - week2SetCounts[1])
//        #expect(maxDelta <= 1, "Set increase should be evenly distributed across workouts")
    }
    
    @MainActor @Test("Transition from high reps to higher weight when near upper rep limit")
    func transitionFromHighRepsToHigherWeight() {
        //TODO
    }
    
    // MARK: - Test Context Class
    
    // Using a class to hold mutable state for our tests
    @MainActor class TestContext {
        var sut: PlanGenerator
        var planInput: PlanInput
        
        init() {
            sut = PlanGenerator()
            
            // Setup default test input
            planInput = PlanInput(
                goal: .hypertrophy,
                prioritizedMuscles: [.chest, .biceps],
                trainingDaysPerWeek: 4,
                workoutDuration: .medium,
                equipment: [.barbell, .dumbbell, .cable],
                preferredSplit: .upperLower,
                trainingExperience: .intermediate
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func averageSetsPerExercise(in plan: TrainingPlanEntity) -> Double {
        var totalSets = 0
        var totalExercises = 0
        
        for workout in plan.weeklyWorkouts.flatMap({ $0 }) {
            for exercise in workout.exercises {
                totalSets += exercise.sets.count
                totalExercises += 1
            }
        }
        
        guard totalExercises > 0 else { return 0 }
        return Double(totalSets) / Double(totalExercises)
    }
    
    private func averageRepsForCompoundExercises(in plan: TrainingPlanEntity) -> Double {
        var totalReps = 0
        var totalCompoundSets = 0
        
        for workout in plan.weeklyWorkouts.flatMap({ $0 }) {
            for exercise in workout.exercises {
                // We'll define compounds based on common exercise types
                let isCompound = isCompoundMovement(exercise.movement)
                if isCompound {
                    for set in exercise.sets {
                        totalReps += set.targetReps
                        totalCompoundSets += 1
                    }
                }
            }
        }
        
        guard totalCompoundSets > 0 else { return 0 }
        return Double(totalReps) / Double(totalCompoundSets)
    }
    
    // Test helper to determine compound movements
    private func isCompoundMovement(_ movement: MovementEntity) -> Bool {
        let compoundTypes: [MovementType] = [
            .barbellBenchPress, .barbellDeadlift, .barbellBackSquat, .barbellFrontSquat,
            .overheadPress, .pullUps, .chinUps, .dips, .bentOverRow, .romanianDeadlift
        ]
        return compoundTypes.contains(movement.movementType) || movement.secondaryMuscles.count >= 2
    }
    
    // Test helper to get primary muscle
    private func getPrimaryMuscle(_ movement: MovementEntity) -> MuscleGroup {
        return movement.primaryMuscles.first ?? .unknown
    }
    
    // Test helper to get expected muscles for a day type
    private func getMusclesForDayType(_ dayType: WorkoutDayType) -> [MuscleGroup] {
        switch dayType {
        case .fullBody:
            return MuscleGroup.allCases
        case .upper:
            return [.chest, .back, .shoulders, .biceps, .triceps, .forearms, .traps]
        case .lower:
            return [.quads, .hamstrings, .glutes, .calves, .abs, .obliques, .lowerBack]
        case .push:
            return [.chest, .shoulders, .triceps]
        case .pull:
            return [.back, .biceps, .forearms, .traps]
        case .legs:
            return [.quads, .hamstrings, .glutes, .calves, .lowerBack]
        }
    }
    
    // Test helper to get day type based on split
    private func getDayType(day: Int, split: SplitStyle, totalDays: Int) -> WorkoutDayType {
        switch split {
        case .fullBody:
            return .fullBody
        case .upperLower:
            return day % 2 == 0 ? .upper : .lower
        case .pushPullLegs:
            let dayMod = day % 3
            if dayMod == 1 { return .push }
            if dayMod == 2 { return .pull }
            return .legs
        }
    }
}

// MARK: - Mock Dependencies
    
    // Helper to mirror the same logic in PlanGenerator for test consistency
    private func getMusclesForDayType(_ dayType: WorkoutDayType) -> [MuscleGroup] {
        switch dayType {
        case .fullBody:
            return MuscleGroup.allCases
        case .upper:
            return [.chest, .back, .shoulders, .biceps, .triceps, .forearms, .traps]
        case .lower:
            return [.quads, .hamstrings, .glutes, .calves, .abs, .obliques, .lowerBack]
        case .push:
            return [.chest, .shoulders, .triceps]
        case .pull:
            return [.back, .biceps, .forearms, .traps]
        case .legs:
            return [.quads, .hamstrings, .glutes, .calves, .lowerBack]
        }
    }
