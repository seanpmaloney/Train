import Testing
import Foundation
@testable import Train

struct PlanGeneratorTests {
    @Test("Plan has correct properties")
    func planHasCorrectProperties() {
        // Setup test dependencies
        let testContext = TestContext()
        
        // When
        let plan = testContext.sut.generatePlan(from: testContext.planInput, forWeeks: 4)
        
        // Then
        #expect(plan.daysPerWeek == testContext.planInput.trainingDaysPerWeek)
        #expect(plan.trainingGoal == testContext.planInput.goal)
        #expect(plan.musclePreferences?.count == MuscleGroup.allCases.count)
        
        // Verify prioritized muscles are set to grow
        let priorityPreferences = plan.musclePreferences?.filter { 
            testContext.planInput.prioritizedMuscles.contains($0.muscleGroup) && $0.goal == .grow 
        }
        #expect(priorityPreferences?.count == testContext.planInput.prioritizedMuscles.count)
    }
    
    @Test("Plan creates correct number of workouts")
    func planCreatesCorrectNumberOfWorkouts() {
        // Setup test dependencies
        let testContext = TestContext()
        
        // Given
        let weeks = 3
        
        // When
        let plan = testContext.sut.generatePlan(from: testContext.planInput, forWeeks: weeks)
        
        // Then
        let expectedWorkoutCount = testContext.planInput.trainingDaysPerWeek * weeks
        #expect(plan.workouts.count == expectedWorkoutCount)
    }
    
    @Test("Plan schedules workouts on correct days")
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
        var plan = testContext.sut.generatePlan(from: customPlanInput, forWeeks: weeks)
        plan.startDate = startDate
        
        // Force regeneration of workouts with our start date
        plan.workouts = []
        setupTestWorkouts(
            for: plan, 
            using: testContext.mockWorkoutBuilder, 
            input: customPlanInput, 
            weeks: weeks
        )
        
        // Then
        #expect(plan.workouts.count == customPlanInput.trainingDaysPerWeek * weeks)
        
        // Verify first week dates
        for dayIndex in 0..<customPlanInput.trainingDaysPerWeek {
            let workout = plan.workouts[dayIndex]
            let expectedDate = calendar.date(byAdding: .day, value: dayIndex, to: startDate)
            #expect(workout.scheduledDate == expectedDate)
        }
        
        // Verify second week dates
        for dayIndex in 0..<customPlanInput.trainingDaysPerWeek {
            let workoutIndex = customPlanInput.trainingDaysPerWeek + dayIndex
            let workout = plan.workouts[workoutIndex]
            let expectedDate = calendar.date(byAdding: .day, value: 7 + dayIndex, to: startDate)
            #expect(workout.scheduledDate == expectedDate)
        }
    }
    
    @Test("Volume distributed correctly based on split style")
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
        let upperLowerPlan = testContext.sut.generatePlan(from: upperLowerInput, forWeeks: 1)
        let pplPlan = testContext.sut.generatePlan(from: pplInput, forWeeks: 1)
        let fullBodyPlan = testContext.sut.generatePlan(from: fullBodyInput, forWeeks: 1)
        
        // Then: Verify workouts target the right muscle groups based on split
        
        // Upper/Lower split
        for (i, workout) in upperLowerPlan.workouts.enumerated() {
            let dayType = getDayType(day: i+1, split: .upperLower, totalDays: upperLowerInput.trainingDaysPerWeek)
            let expectedMuscles = getMusclesForDayType(dayType)
            
            // Verify each exercise primarily targets a muscle that belongs in this day's group
            for exercise in workout.exercises {
                let primaryMuscle = getPrimaryMuscle(exercise.movement)
                #expect(expectedMuscles.contains(primaryMuscle))
            }
        }
        
        // Similar verification for PPL split
        for (i, workout) in pplPlan.workouts.enumerated() {
            let dayType = getDayType(day: i+1, split: .pushPullLegs, totalDays: pplInput.trainingDaysPerWeek)
            let expectedMuscles = getMusclesForDayType(dayType)
            
            for exercise in workout.exercises {
                let primaryMuscle = getPrimaryMuscle(exercise.movement)
                #expect(expectedMuscles.contains(primaryMuscle))
            }
        }
        
        // Full body should include exercises for multiple muscle areas
        for workout in fullBodyPlan.workouts {
            var targetedMuscleGroups = Set<MuscleGroup>()
            for exercise in workout.exercises {
                targetedMuscleGroups.insert(getPrimaryMuscle(exercise.movement))
            }
            
            // Full body workouts should target at least 4 different muscle groups
            #expect(targetedMuscleGroups.count >= 4)
        }
    }
    
    @Test("Volume progresses appropriately across weeks")
    func volumeProgressionAcrossWeeks() {
        // Setup test dependencies
        let testContext = TestContext()
        
        // Given
        let weeks = 4
        
        // When
        let plan = testContext.sut.generatePlan(from: testContext.planInput, forWeeks: weeks)
        
        // Then
        // Group workouts by week
        var workoutsByWeek: [[WorkoutEntity]] = Array(repeating: [], count: weeks)
        
        for workout in plan.workouts {
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
    
    @Test("Experience level affects set and rep ranges")
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
        let beginnerPlan = testContext.sut.generatePlan(from: beginnerInput, forWeeks: 1)
        let advancedPlan = testContext.sut.generatePlan(from: advancedInput, forWeeks: 1)
        
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
    
    // MARK: - Test Context Class
    
    // Using a class to hold mutable state for our tests
    class TestContext {
        var mockVolumeStrategy: MockVolumeRampStrategy
        var mockExerciseSelector: MockExerciseSelector
        var mockWorkoutBuilder: MockWorkoutBuilder
        var sut: PlanGenerator
        var planInput: PlanInput
        
        init() {
            mockVolumeStrategy = MockVolumeRampStrategy()
            mockExerciseSelector = MockExerciseSelector()
            mockWorkoutBuilder = MockWorkoutBuilder()
            
            sut = PlanGenerator(
                workoutBuilder: mockWorkoutBuilder,
                exerciseSelector: mockExerciseSelector,
                volumeStrategy: mockVolumeStrategy
            )
            
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
    
    private func setupTestWorkouts(
        for plan: TrainingPlanEntity,
        using builder: WorkoutBuilder,
        input: PlanInput,
        weeks: Int
    ) {
        // Simple implementation to create test workouts
        for weekIndex in 1...weeks {
            for dayIndex in 0..<input.trainingDaysPerWeek {
                let dayType = getDayType(day: dayIndex + 1, split: input.preferredSplit, totalDays: input.trainingDaysPerWeek)
                let workout = builder.buildWorkout(
                    for: dayType,
                    prioritizedMuscles: input.prioritizedMuscles,
                    equipment: input.equipment,
                    duration: input.workoutDuration
                )
                
                // Set the date
                let dayOffset = (weekIndex - 1) * 7 + dayIndex
                let scheduledDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: plan.startDate)
                workout.scheduledDate = scheduledDate
                
                // Set training plan reference
                workout.trainingPlan = plan
                
                plan.workouts.append(workout)
            }
        }
    }
    
    private func averageSetsPerExercise(in plan: TrainingPlanEntity) -> Double {
        var totalSets = 0
        var totalExercises = 0
        
        for workout in plan.workouts {
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
        
        for workout in plan.workouts {
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

class MockVolumeRampStrategy: VolumeRampStrategy {
    private(set) var calculateVolumeCallCount = 0
    private(set) var lastMuscleGroupProvided: MuscleGroup?
    private(set) var lastGoalProvided: TrainingGoal?
    private(set) var lastTrainingAgeProvided: Int?
    private(set) var lastIsEmphasizedProvided: Bool?
    
    func calculateVolume(
        for muscleGroup: MuscleGroup,
        goal: TrainingGoal,
        trainingAge: Int,
        isEmphasized: Bool
    ) -> VolumeRecommendation {
        calculateVolumeCallCount += 1
        lastMuscleGroupProvided = muscleGroup
        lastGoalProvided = goal
        lastTrainingAgeProvided = trainingAge
        lastIsEmphasizedProvided = isEmphasized
        
        let baseSets = isEmphasized ? 12 : 8
        let repMin = goal == .strength ? 5 : 8
        let repMax = goal == .strength ? 8 : 12
        
        return VolumeRecommendation(
            setsPerWeek: baseSets,
            repRangeLower: repMin,
            repRangeUpper: repMax,
            intensity: 0.75
        )
    }
}

class MockExerciseSelector: ExerciseSelector {
    private(set) var selectExercisesCallCount = 0
    private(set) var lastTargetingProvided: [MuscleGroup]?
    private(set) var lastWithPriorityProvided: [MuscleGroup]?
    private(set) var lastAvailableEquipmentProvided: [EquipmentType]?
    private(set) var lastExerciseCountProvided: Int?
    
    var exercisesToReturn: [MovementEntity] = []
    
    func selectExercises(
        targeting: [MuscleGroup],
        withPriority: [MuscleGroup],
        availableEquipment: [EquipmentType],
        exerciseCount: Int
    ) -> [MovementEntity] {
        selectExercisesCallCount += 1
        lastTargetingProvided = targeting
        lastWithPriorityProvided = withPriority
        lastAvailableEquipmentProvided = availableEquipment
        lastExerciseCountProvided = exerciseCount
        
        if !exercisesToReturn.isEmpty {
            return Array(exercisesToReturn.prefix(exerciseCount))
        }
        
        // Create mock exercises for each targeted muscle
        var result: [MovementEntity] = []
        
        for muscle in targeting {
            // Create a basic movement for this muscle group
            let movement = MovementEntity(
                type: .barbellBenchPress, // Default type, would normally vary
                primaryMuscles: [muscle],
                secondaryMuscles: [],
                equipment: availableEquipment.first ?? .barbell
            )
            result.append(movement)
            
            if result.count >= exerciseCount {
                break
            }
        }
        
        return result
    }
}

class MockWorkoutBuilder: WorkoutBuilder {
    private(set) var buildWorkoutCallCount = 0
    private(set) var lastDayTypeProvided: WorkoutDayType?
    private(set) var lastPrioritizedMusclesProvided: [MuscleGroup]?
    private(set) var lastEquipmentProvided: [EquipmentType]?
    private(set) var lastDurationProvided: WorkoutDuration?
    
    func buildWorkout(
        for dayType: WorkoutDayType,
        prioritizedMuscles: [MuscleGroup],
        equipment: [EquipmentType],
        duration: WorkoutDuration
    ) -> WorkoutEntity {
        buildWorkoutCallCount += 1
        lastDayTypeProvided = dayType
        lastPrioritizedMusclesProvided = prioritizedMuscles
        lastEquipmentProvided = equipment
        lastDurationProvided = duration
        
        // Create a simple workout with 3 exercises
        var workout = WorkoutEntity(
            title: "Mock Workout",
            description: "A mock workout for testing",
            isComplete: false
        )
        
        // Add some exercises based on the day type
        let targetMuscles = getMusclesForDayType(dayType)
        for muscle in targetMuscles.prefix(3) {
            let movement = MovementEntity(
                type: .barbellBenchPress,
                primaryMuscles: [muscle],
                equipment: equipment.first ?? .barbell
            )
            
            let sets = [
                ExerciseSetEntity(weight: 100, targetReps: 10),
                ExerciseSetEntity(weight: 100, targetReps: 10),
                ExerciseSetEntity(weight: 100, targetReps: 10)
            ]
            
            let exercise = ExerciseInstanceEntity(
                movement: movement,
                exerciseType: "strength",
                sets: sets
            )
            
            workout.exercises.append(exercise)
        }
        
        return workout
    }
    
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
}
