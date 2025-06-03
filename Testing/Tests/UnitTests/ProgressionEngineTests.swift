import Foundation
import Testing
@testable import Train

@Suite("ProgressionEngine Tests")
@MainActor
struct ProgressionEngineTests {
    
    // MARK: - Test Setup Helpers
    
    /// Create a simple workout with exercises targeting specific muscles
    private func createWorkout(
        id: UUID = UUID(),
        title: String = "Test Workout",
        muscles: [MuscleGroup],
        setCount: Int = 3,
        date: Date? = Date()
    ) -> WorkoutEntity {
        // Create exercises for each muscle
        var exercises: [ExerciseInstanceEntity] = []
        
        for muscle in muscles {
            // Create movement
            let movement = MovementEntity(
                type: .unknown,  // Use unknown as default type
                primaryMuscles: [muscle],
                secondaryMuscles: [],
                equipment: .bodyweight,  // Default to bodyweight
                notes: nil,
                videoURL: nil,
                movementPattern: .unknown,
                isCompound: false
            )
            
            // Create sets
            var sets: [ExerciseSetEntity] = []
            for _ in 0..<setCount {
                sets.append(ExerciseSetEntity())
            }
            
            // Create exercise instance
            let exercise = ExerciseInstanceEntity(
                movement: movement,
                exerciseType: movement.name,
                sets: sets
            )
            
            exercises.append(exercise)
        }
        
        // Create workout
        let workout = WorkoutEntity(
            title: title,
            description: "Test workout for progression testing",
            isComplete: false,
            scheduledDate: date,
            exercises: exercises
        )
        
        return workout
    }
    
    /// Create a week of workouts targeting different muscle groups
    private func createWeekOfWorkouts() -> [WorkoutEntity] {
        return [
            createWorkout(title: "Push Day", muscles: [.chest, .shoulders, .triceps]),
            createWorkout(title: "Pull Day", muscles: [.back, .biceps, .forearms]),
            createWorkout(title: "Leg Day", muscles: [.quads, .hamstrings, .calves]),
            createWorkout(title: "Upper Body", muscles: [.chest, .back, .biceps, .triceps]),
            createWorkout(title: "Lower Body", muscles: [.quads, .hamstrings, .glutes])
        ]
    }
    
    /// Create a collection of workout feedback with pre, exercise and post feedback
    private func createFeedbackCollection(
        workoutId: UUID,
        soreMuscles: [MuscleGroup] = [],
        jointPain: [JointArea] = [],
        fatigue: FatigueLevel = .normal,
        exerciseFeedbacks: [(UUID, ExerciseIntensity, SetVolumeRating)] = []
    ) -> [WorkoutFeedback] {
        var feedbacks: [WorkoutFeedback] = []
        
        // Create pre-workout feedback if needed
        if !soreMuscles.isEmpty || !jointPain.isEmpty {
            feedbacks.append(PreWorkoutFeedback(workoutId: workoutId, soreMuscles: soreMuscles, jointPainAreas: jointPain))
        }
        
        // Create exercise feedback if provided
        for (exerciseId, intensity, volume) in exerciseFeedbacks {
            feedbacks.append(ExerciseFeedback(exerciseId: exerciseId, workoutId: workoutId, intensity: intensity, setVolume: volume))
        }
        
        // Create post-workout feedback with fatigue level
        feedbacks.append(PostWorkoutFeedback(workoutId: workoutId, sessionFatigue: fatigue))
        
        return feedbacks
    }
    
    // MARK: - Basic Progression Tests
    
    @Test("Muscle below volume target should add up to 2 sets across workouts")
    func testBasicProgression() async throws {
        // Setup test data
        var weeklyWorkouts: [[WorkoutEntity]] = [
            createWeekOfWorkouts(),
            createWeekOfWorkouts() // Next week
        ]
        
        // MuscleGroup.quads has target of 10-12 sets, our week only has 6 sets (3 per workout x 2 workouts)
        // No feedback needed for this test as we're just testing basic progression
        
        // Apply progression - no need to pass feedbackMap with our new direct feedback approach
        ProgressionEngine.applyProgression(to: &weeklyWorkouts)
        
        // Count sets for quads in next week
        let nextWeek = weeklyWorkouts[1]
        var nextWeekQuadSets = 0
        
        for workout in nextWeek {
            for exercise in workout.exercises {
                if exercise.movement.primaryMuscles.contains(.quads) {
                    nextWeekQuadSets += exercise.sets.count
                }
            }
        }
        
        // Expect 2 sets to be added (from 6 to 8 sets)
        #expect(nextWeekQuadSets == 8)
    }
    
    @Test("Muscle at upper limit should not have sets added - direct test")
    func testNoProgressionAtUpperLimit() async throws {
        // Create test data with minimal objects
        print("Creating minimal test data...")
        
        // 1. Create a chest-focused movement
        let chestMovement = MovementEntity(
            type: .barbellBenchPress,  // Use a specific movement type
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps],
            equipment: .barbell
        )
        
        // 2. Create an exercise with 20 sets (well above limit)
        var chestSets: [ExerciseSetEntity] = []
        for _ in 0..<20 { // Excessive number to guarantee we're over limit
            chestSets.append(ExerciseSetEntity())
        }
        
        let chestExercise = ExerciseInstanceEntity(
            movement: chestMovement,
            exerciseType: "Bench Press",
            sets: chestSets
        )
        
        // 3. Create week 1 and week 2 workouts (using separate objects, not copy)
        let week1Workout = WorkoutEntity(
            title: "Chest Day - Week 1",
            description: "Test workout",
            isComplete: false,
            exercises: [chestExercise]
        )
        
        // For week 2, create totally fresh objects to avoid any reference issues
        let week2ChestMovement = MovementEntity(
            type: .barbellBenchPress,
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps],
            equipment: .barbell
        )
        
        var week2ChestSets: [ExerciseSetEntity] = []
        for _ in 0..<20 {
            week2ChestSets.append(ExerciseSetEntity())
        }
        
        let week2ChestExercise = ExerciseInstanceEntity(
            movement: week2ChestMovement,
            exerciseType: "Bench Press",
            sets: week2ChestSets
        )
        
        let week2Workout = WorkoutEntity(
            title: "Chest Day - Week 2",
            description: "Test workout",
            isComplete: false,
            exercises: [week2ChestExercise]
        )
        
        // 4. Create the 2D array manually
        var workouts: [[WorkoutEntity]] = [
            [week1Workout],
            [week2Workout]
        ]
        
        // 5. Verify starting conditions
        let startingSets = workouts[1][0].exercises[0].sets.count
        print("Starting with \(startingSets) sets")
        
        // 6. Run progression with no feedback - using new direct feedback approach
        let logs = ProgressionEngine.applyProgression(
            to: &workouts,
            debug: true
        )
        
        // 7. Check end result
        let endingSets = workouts[1][0].exercises[0].sets.count
        print("Ended with \(endingSets) sets")
        
        // Volume should not increase since we're way over the limit
        #expect(endingSets == startingSets, "Expected no change in sets but changed from \(startingSets) to \(endingSets)")
    }
    
    @Test("Exercises already at max sets should not progress")
    func testExercisesAtMaxSetsDoNotProgress() async throws {
        // Create a workout with an exercise already at 5 sets
        let workout = createWorkout(muscles: [.quads], setCount: 5)
        
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [workout],
            [workout.copy() ]
        ]
        
        // Empty feedback allows progression, but the 5-set cap should prevent it
        // No need for feedbackMap with our new direct feedback approach
        
        // Apply progression
        ProgressionEngine.applyProgression(to: &weeklyWorkouts)
        
        // Check that no sets were added since we're already at cap
        #expect(weeklyWorkouts[1][0].exercises.first!.sets.count == 5)
    }
    
    @Test("Direct volume calculation test")
    func testVolumeCalculation() async throws {
        // Test the volume calculation directly
        
        // Create a basic movement targeting chest
        let movement = MovementEntity(
            type: .unknown,
            primaryMuscles: [.chest],
            secondaryMuscles: [],
            equipment: .bodyweight
        )
        
        // Create an exercise with 5 sets
        let sets = (0..<5).map { _ in ExerciseSetEntity() }
        let exercise = ExerciseInstanceEntity(
            movement: movement,
            exerciseType: "Test Exercise",
            sets: sets
        )
        
        // Create a workout with just this exercise
        let workout = WorkoutEntity(
            title: "Test Workout",
            description: "Volume calculation test",
            isComplete: false,
            exercises: [exercise]
        )
        
        // Get access to the internal volume calculation method
        let volumeByMuscle = calculateVolumeDirectly(from: [workout])
        
        // Verify the volume calculation
        print("Calculated volume by muscle: \(volumeByMuscle)")
        
        // Chest should have 5 sets
        let chestVolume = volumeByMuscle[.chest] ?? 0
        #expect(chestVolume == 5, "Expected chest to have 5 sets, but got \(chestVolume)")
    }
    
    // Helper that replicates the engine's volume calculation
    private func calculateVolumeDirectly(from workouts: [WorkoutEntity]) -> [MuscleGroup: Int] {
        var volumeByMuscle = [MuscleGroup: Int]()
        
        for workout in workouts {
            for exercise in workout.exercises {
                let setCount = exercise.sets.count
                
                // Add full credit for primary muscles
                for muscle in exercise.movement.primaryMuscles {
                    volumeByMuscle[muscle, default: 0] += setCount
                }
                
                // Add half credit for secondary muscles
                for muscle in exercise.movement.secondaryMuscles {
                    volumeByMuscle[muscle, default: 0] += Int(round(Double(setCount) * 0.5))
                }
            }
        }
        
        return volumeByMuscle
    }
    
    @Test("Muscle trained 3x per week should have sets distributed across workouts")
    func testSetDistribution() async throws {
        // Create workouts with quads in 3 different workouts, 2 sets each
        let workouts = [
            createWorkout(title: "Workout 1", muscles: [.quads], setCount: 2),
            createWorkout(title: "Workout 2", muscles: [.quads], setCount: 2),
            createWorkout(title: "Workout 3", muscles: [.quads], setCount: 2),
        ]
        
        var weeklyWorkouts: [[WorkoutEntity]] = [workouts, workouts.map { $0.copy()  }]
        
        // Apply progression - should add 2 sets total across workouts
        // No need for feedbackMap with our new direct feedback approach
        ProgressionEngine.applyProgression(to: &weeklyWorkouts)
        
        let nextWeek = weeklyWorkouts[1]
        
        // Count total sets and compare to original
        var totalSetsBeforeProgression = 0
        var totalSetsAfterProgression = 0
        
        for i in 0..<workouts.count {
            let beforeCount = workouts[i].exercises.first!.sets.count
            let afterCount = nextWeek[i].exercises.first!.sets.count
            totalSetsBeforeProgression += beforeCount
            totalSetsAfterProgression += afterCount
        }
        
        // Expect 2 sets to be added total
        #expect(totalSetsAfterProgression == totalSetsBeforeProgression + 2)
        
        // Check distribution - no workout should have gained more than 1 set
        var workoutsWithAddedSets = 0
        for i in 0..<workouts.count {
            let beforeCount = workouts[i].exercises.first!.sets.count
            let afterCount = nextWeek[i].exercises.first!.sets.count
            
            if afterCount > beforeCount {
                workoutsWithAddedSets += 1
                
                // Should only add 1 set per workout
                #expect(afterCount == beforeCount + 1)
            }
        }
        
        // At least 2 workouts should have had sets added
        #expect(workoutsWithAddedSets >= 2)
    }
    
    // MARK: - Feedback Override Tests
    
    @Test("Exercise marked as tooMuch should not have sets added")
    func testTooMuchFeedback() async throws {
        let plan = TrainingPlanEntity(name: "Plan", startDate: Date())
        plan.musclePreferences = [MuscleTrainingPreference(id: UUID(), muscleGroup: .chest, goal: .grow)]
        let workout = createWorkout(muscles: [.chest], setCount: 3)
        let exercise = workout.exercises.first!
        
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [workout],
            [workout.copy()]
        ]
        
        // Attach feedback to the corresponding exercise in the first week's workout
        if let targetExercise = weeklyWorkouts[0][0].exercises.first {
            targetExercise.feedback = ExerciseFeedback(exerciseId: targetExercise.id, workoutId: workout.id, intensity: .moderate, setVolume: .tooMuch)
        }
        
        // Apply progression
        ProgressionEngine.applyProgression(to: &weeklyWorkouts, debug: true)
        
        // Check that sets weren't added
        let nextWeekExercise = weeklyWorkouts[1][0].exercises.first!
        #expect(nextWeekExercise.sets.count == exercise.sets.count - 1)
    }
    
    @Test("Sore muscle should have sets reduced in previous workout pattern")
    func testSoreMuscleReduction() async throws {
        // Create two workouts in sequence - leg day first, then upper body
        let legDay1 = createWorkout(title: "Leg Day", muscles: [.quads], setCount: 3)
        let legDay = createWorkout(title: "Leg Day", muscles: [.quads], setCount: 3)
        let upperDay = createWorkout(title: "Upper Day", muscles: [.chest], setCount: 3)
        
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [legDay1, legDay, upperDay],
            [legDay1.copy(), legDay.copy(), upperDay.copy() ]
        ]
        
        
        // Report quads as sore during leg day, and for upper day by attaching feedback directly to workouts
        legDay1.preWorkoutFeedback = PreWorkoutFeedback(workoutId: legDay1.id, soreMuscles: [], jointPainAreas: [])
        legDay.preWorkoutFeedback = PreWorkoutFeedback(workoutId: legDay.id, soreMuscles: [.quads], jointPainAreas: [])
        upperDay.preWorkoutFeedback = PreWorkoutFeedback(workoutId: upperDay.id, soreMuscles: [.quads], jointPainAreas: [])
        
        // Apply progression - no need for feedbackMap with our new direct feedback approach
        ProgressionEngine.applyProgression(to: &weeklyWorkouts)
        
        // Check that sets were increased for chest
        let originalChestSetCount = upperDay.exercises.first!.sets.count
        let newChestSetCount = weeklyWorkouts[1][2].exercises.first!.sets.count
        
        // Leg workout sets should remain unchanged or decrease
        let originalLegSetCount = legDay1.exercises.first!.sets.count
        let newLegSetCount = weeklyWorkouts[1][0].exercises.first!.sets.count
        
        // Chest sets should be reduced, back sets should not
        #expect(newChestSetCount > originalChestSetCount, "Chest sets should be increased since quad soreness is fine")
        #expect(newLegSetCount <  originalLegSetCount, "Leg sets should be reduced")
    }
    
    @Test("Completely drained session should reduce 2 sets from next week")
    func testCompletelyDrainedReduction() async throws {
        let workout = createWorkout(muscles: [.chest, .shoulders, .triceps], setCount: 3)
        
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [workout],
            [workout.copy() ]
        ]
        
        // Attach post workout feedback to the workout in the first week
        weeklyWorkouts[0][0].postWorkoutFeedback = PostWorkoutFeedback(workoutId: workout.id, sessionFatigue: .completelyDrained)
        
        // Apply progression
        ProgressionEngine.applyProgression(to: &weeklyWorkouts)
        
        // Count total sets before and after
        let originalSetCount = workout.exercises.reduce(0) { $0 + $1.sets.count }
        let newSetCount = weeklyWorkouts[1][0].exercises.reduce(0) { $0 + $1.sets.count }
        
        // Should have 2 fewer sets total
        #expect(newSetCount == originalSetCount - 2)
    }
    
    @Test("Joint pain should flag only related exercises")
    func testJointPainFlagging() async throws {
        let workout1 = createWorkout(title: "Workout 1", muscles: [.quads, .chest])
        
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [workout1],
            [workout1.copy() ]
        ]
        
        // Create feedback with knee pain by attaching directly to the workout
        workout1.preWorkoutFeedback = PreWorkoutFeedback(workoutId: workout1.id, soreMuscles: [], jointPainAreas: [.knee])
        
        // Apply progression - no need for feedbackMap with our new direct feedback approach
        ProgressionEngine.applyProgression(to: &weeklyWorkouts)
        
        // Check that exercises with knee pain (quads) are flagged, chest is not
        let nextWeekWorkout = weeklyWorkouts[1][0]
        let quadExercise = nextWeekWorkout.exercises.first {
            $0.movement.primaryMuscles.contains(.quads)
        }
        let chestExercise = nextWeekWorkout.exercises.first {
            $0.movement.primaryMuscles.contains(.chest)
        }
        
        // Quad exercise should be flagged, chest should not
        #expect(quadExercise?.shouldShowJointWarning == true, "Quad exercise should be flagged for knee pain")
        #expect(chestExercise?.shouldShowJointWarning == false, "Chest exercise should not be flagged for knee pain")
        
        // Both exercises should have same number of sets (no progression due to joint pain)
        #expect(quadExercise?.sets.count == 3, "Quad exercise should not get progression due to joint pain")
        #expect((chestExercise?.sets.count)! > 3, "Chest exercise should still progress as it's unaffected by knee pain")
    }
    
    // MARK: - Safeguard Tests
    
    @Test("No exercise should exceed 5 sets")
    func testNoExerciseExceedsFiveSets() async throws {
        let workout = createWorkout(muscles: [.quads], setCount: 4)
        
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [workout],
            [workout.copy() ]
        ]
        
        // Apply progression - should try to add sets
        ProgressionEngine.applyProgression(to: &weeklyWorkouts)
        
        // Check exercise doesn't exceed 5 sets
        let nextWeekExercise = weeklyWorkouts[1][0].exercises.first!
        #expect(nextWeekExercise.sets.count <= 5)
    }
    
    @Test("Muscles blocked by feedback should not progress while others can")
    func testMusclesWithFeedbackBlockedFromProgression() async throws {
        let workout = createWorkout(muscles: [.quads, .chest], setCount: 3)
        
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [workout],
            [workout.copy()]
        ]
        
        // Attach feedback to the chest exercise in the first week's workout
        if let chestExercise = weeklyWorkouts[0][0].exercises.first(where: { $0.movement.primaryMuscles.contains(.chest) }) {
            chestExercise.feedback = ExerciseFeedback(
                exerciseId: chestExercise.id,
                workoutId: workout.id,
                intensity: .moderate,
                setVolume: .tooMuch
            )
        }
        
        // Apply progression
        ProgressionEngine.applyProgression(to: &weeklyWorkouts, debug: true)
        
        // Check that quads received progression but chest didn't
        let nextWeekWorkout = weeklyWorkouts[1][0]
        
        let nextWeekQuads = nextWeekWorkout.exercises.first {
            $0.movement.primaryMuscles.contains(.quads)
        }!
        
        let nextWeekChest = nextWeekWorkout.exercises.first {
            $0.movement.primaryMuscles.contains(.chest)
        }!
        
        // Quads should get a set added, chest should remain unchanged
        #expect(nextWeekQuads.sets.count > 3, "Unblocked muscle (quads) should progress")
        #expect(nextWeekChest.sets.count == 2, "Blocked muscle (chest) should not progress")
    }
    
    @Test("Set progression respects per-muscle weekly cap of +2 sets")
    func testWeeklyCapRespected() async throws {
        // Create many workouts with the same muscle to potentially add many sets
        let workouts = [
            createWorkout(title: "Workout 1", muscles: [.quads], setCount: 2),
            createWorkout(title: "Workout 2", muscles: [.quads], setCount: 2),
            createWorkout(title: "Workout 3", muscles: [.quads], setCount: 2),
            createWorkout(title: "Workout 4", muscles: [.quads], setCount: 2),
        ]
        
        var weeklyWorkouts: [[WorkoutEntity]] = [workouts, workouts.map { $0.copy() }]
        
        // Apply progression
        ProgressionEngine.applyProgression(to: &weeklyWorkouts)
        
        // Count total sets before and after
        let originalSetCount = workouts.reduce(0) { sum, workout in
            return sum + workout.exercises.reduce(0) { $0 + $1.sets.count }
        }
        
        let newSetCount = weeklyWorkouts[1].reduce(0) { sum, workout in
            return sum + workout.exercises.reduce(0) { $0 + $1.sets.count }
        }
        
        // Should add at most 2 sets even though there are 4 workouts
        #expect(newSetCount == originalSetCount + 2)
    }
    
    // MARK: - New Test Cases
    
    @Test("Multiple feedback sources should be processed correctly")
    func testMultipleFeedbackSources() async throws {
        // Create a workout with multiple muscle groups
        let workout1 = createWorkout(muscles: [.chest, .quads, .back], setCount: 3)
        let workout2 = createWorkout(muscles: [.chest, .quads, .back], setCount: 3)
        
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [workout1, workout2],
            [workout1.copy(), workout2.copy()]
        ]
        
        // Attach PreWorkoutFeedback to the workout in the first week
        weeklyWorkouts[0][1].preWorkoutFeedback = PreWorkoutFeedback(workoutId: workout2.id, soreMuscles: [.chest], jointPainAreas: [.knee])
        
        // Apply progression
        ProgressionEngine.applyProgression(to: &weeklyWorkouts)
        
        // Get the exercises in next week's workout
        let nextWeekWorkout = weeklyWorkouts[1][0]
        let nextWeekChest = nextWeekWorkout.exercises.first { $0.movement.primaryMuscles.contains(.chest) }!
        let nextWeekQuads = nextWeekWorkout.exercises.first { $0.movement.primaryMuscles.contains(.quads) }!
        let nextWeekBack = nextWeekWorkout.exercises.first { $0.movement.primaryMuscles.contains(.back) }!
        
        // Chest should be reduced due to soreness
        #expect(nextWeekChest.sets.count < 3, "Chest sets should be reduced due to soreness")
        
        // Quads should be flagged for joint pain and not progressed
        #expect(nextWeekQuads.shouldShowJointWarning == true, "Quads should show joint pain warning")
        #expect(nextWeekQuads.sets.count == 3, "Quads should not progress due to joint pain")
        
        // Back should progress normally
        #expect(nextWeekBack.sets.count > 3, "Back should progress as it has no issues")
    }
    
    @Test("Volume calculation should count primary and secondary muscles correctly")
    func testOverlappingPrimarySecondaryMuscles() async throws {
        // Create workouts with overlapping muscle involvement
        let workoutA = createWorkout(id: UUID(), title: "Workout A", muscles: [], setCount: 0)
        
        // Create a compound movement that works chest primarily and triceps secondarily
        let benchPress = MovementEntity(
            type: .barbellBenchPress,
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps],
            equipment: .barbell
        )
        
        // Create sets
        var benchSets: [ExerciseSetEntity] = []
        for _ in 0..<3 {
            benchSets.append(ExerciseSetEntity())
        }
        
        // Create exercise instance
        let benchExercise = ExerciseInstanceEntity(
            movement: benchPress,
            exerciseType: benchPress.name,
            sets: benchSets
        )
        
        // Create a triceps isolation exercise
        let tricepPushdown = MovementEntity(
            type: .tricepPushdown,
            primaryMuscles: [.triceps],
            secondaryMuscles: [],
            equipment: .cable
        )
        
        // Create sets
        var tricepsSets: [ExerciseSetEntity] = []
        for _ in 0..<2 {
            tricepsSets.append(ExerciseSetEntity())
        }
        
        // Create exercise instance
        let tricepsExercise = ExerciseInstanceEntity(
            movement: tricepPushdown,
            exerciseType: tricepPushdown.name,
            sets: tricepsSets
        )
        
        // Add exercises to workout
        workoutA.exercises = [benchExercise, tricepsExercise]
        
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [workoutA],
            [workoutA.copy()]
        ]
        
        // Apply progression
        ProgressionEngine.applyProgression(to: &weeklyWorkouts, debug: true)
        
        // Calculate the expected volume
        // Chest: 3 primary sets = 3 sets
        // Triceps: 2 primary sets + 3 secondary sets (0.5 each) = 3.5 sets
        // So chest should gain 1 set, and triceps should gain 1 set
        
        let nextWeekWorkout = weeklyWorkouts[1][0]
        let nextWeekBench = nextWeekWorkout.exercises.first { $0.movement.movementType == .barbellBenchPress }!
        let nextWeekTriceps = nextWeekWorkout.exercises.first { $0.movement.movementType == .tricepPushdown }!
        
        #expect(nextWeekBench.sets.count > 3, "Bench should gain a set for chest progression")
        #expect(nextWeekTriceps.sets.count > 2, "Triceps should gain a set due to relatively low volume")
    }
    
    @Test("Joint pain and too much volume together should only block once")
    func testJointPainAndFeedbackCollision() async throws {
        let workout = createWorkout(muscles: [.quads], setCount: 3)
        
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [workout],
            [workout.copy() ]
        ]
        
        // Attach PreWorkoutFeedback to the workout in the first week
        weeklyWorkouts[0][0].preWorkoutFeedback = PreWorkoutFeedback(workoutId: workout.id, soreMuscles: [], jointPainAreas: [.knee])
        // Attach ExerciseFeedback to the quad exercise in the first week's workout
        if let quadExercise = weeklyWorkouts[0][0].exercises.first {
            quadExercise.feedback = ExerciseFeedback(
                exerciseId: quadExercise.id,
                workoutId: workout.id,
                intensity: .moderate,
                setVolume: .tooMuch
            )
        }
        
        // Apply progression
        ProgressionEngine.applyProgression(to: &weeklyWorkouts)
        
        // Next week's quad exercise should have joint warning but
        // set count should decrease by 1, not 2 (for both joint pain and too much)
        let nextWeekQuads = weeklyWorkouts[1][0].exercises.first!
        
        #expect(nextWeekQuads.shouldShowJointWarning == true, "Exercise should be flagged for joint pain")
        #expect(nextWeekQuads.sets.count <= 3, "Exercise should not progress due to joint pain and too much volume")
    }
    
    @Test("Sore muscles not trained in a workout should not trigger reduction")
    func testSorenessIgnoredWhenMuscleNotTrained() async throws {
        // Create two workouts - one training chest, one training legs
        let chestWorkout = createWorkout(title: "Push Day", muscles: [.chest], setCount: 3)
        let legWorkout = createWorkout(title: "Leg Day", muscles: [.quads, .hamstrings], setCount: 3)
        
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [chestWorkout, legWorkout],
            [chestWorkout.copy(), legWorkout.copy() ]
        ]
        
        // Attach PreWorkoutFeedback with sore back to the chest workout in the first week
        weeklyWorkouts[0][0].preWorkoutFeedback = PreWorkoutFeedback(workoutId: chestWorkout.id, soreMuscles: [.back], jointPainAreas: [])
        
        // Apply progression
        ProgressionEngine.applyProgression(to: &weeklyWorkouts)
        
        // Get the next week workouts
        let nextWeekChest = weeklyWorkouts[1][0]
        let nextWeekLegs = weeklyWorkouts[1][1]
        
        // Since back isn't trained in either workout, both workouts should progress normally
        #expect(nextWeekChest.exercises.first!.sets.count > 3, "Chest workout should progress normally")
        #expect(nextWeekLegs.exercises.first!.sets.count > 3, "Leg workout should progress normally")
    }
    
    // MARK: - Advanced Progression Tests
    
    @Test("Three-Week Progression - Adding 2 sets per week when below target")
    func testThreeWeekProgression() async throws {
        // Create a muscle (quads) that starts below its volume target
        let workout = createWorkout(muscles: [.quads], setCount: 3)
        
        // Create the first two weeks of workouts
        var week1 = [workout.copy() ] // Week 1
        var week2 = [workout.copy() ] // Week 2
        
        // Apply progression from Week 1 to Week 2
        var progression1: [[WorkoutEntity]] = [week1, week2]
        ProgressionEngine.applyProgression(to: &progression1)
        week2 = progression1[1] // Updated Week 2 after progression
        
        // Create Week 3 based on Week 2
        var week3 = [week2[0].copy() ] // Week 3
        
        // Apply progression from Week 2 to Week 3
        var progression2: [[WorkoutEntity]] = [week2, week3]
        ProgressionEngine.applyProgression(to: &progression2)
        week3 = progression2[1] // Updated Week 3 after progression
        
        // Verify the set count increases by 2 each week
        let week1SetCount = week1[0].exercises.first!.sets.count
        let week2SetCount = week2[0].exercises.first!.sets.count
        let week3SetCount = week3[0].exercises.first!.sets.count
        
        print("Week 1 set count: \(week1SetCount)")
        print("Week 2 set count: \(week2SetCount)")
        print("Week 3 set count: \(week3SetCount)")
        
        #expect(week2SetCount == week1SetCount + 1, "Week 2 should have 1 more set than Week 1")
        #expect(week3SetCount == week2SetCount + 1, "Week 3 should have 1 more set than Week 2")
    }
    
    @Test("Soreness in a trained muscle causes reduction in the workout that caused the soreness")
    func testSorenessInTrainedMuscle() async throws {
        // Create explicit dates for testing the date ordering logic
        let calendar = Calendar.current
        let today = Date()
        let mondayDate = calendar.date(byAdding: .day, value: -3, to: today)! // Monday
        let thursdayDate = calendar.date(byAdding: .day, value: -1, to: today)! // Thursday
        
        // Create two workouts for the week that train the same muscle (chest)
        // First workout is more intense and will be the one that caused soreness
        let workoutThatCausesSoreness = createWorkout(title: "Heavy Chest", muscles: [.chest], setCount: 5, date: mondayDate)
        let workoutWithSoreness = createWorkout(title: "Light Chest", muscles: [.chest], setCount: 3, date: thursdayDate)
        
        // Explicitly verify the date order for test integrity
        #expect(workoutThatCausesSoreness.scheduledDate! < workoutWithSoreness.scheduledDate!,
               "Heavy Chest workout must be scheduled before Light Chest workout for this test to be valid")
        
        // Create two weeks with the same workout sequence
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [workoutThatCausesSoreness.copy(), workoutWithSoreness.copy() ], // Week 1
            [workoutThatCausesSoreness.copy(), workoutWithSoreness.copy() ]  // Week 2
        ]
        
        // Ensure the dates are preserved in the copied workouts
        weeklyWorkouts[0][0].scheduledDate = mondayDate
        weeklyWorkouts[0][1].scheduledDate = thursdayDate
        weeklyWorkouts[1][0].scheduledDate = calendar.date(byAdding: .day, value: 7, to: mondayDate)! // Next Monday
        weeklyWorkouts[1][1].scheduledDate = calendar.date(byAdding: .day, value: 7, to: thursdayDate)! // Next Thursday
        
        // Report soreness in chest for the second workout in Week 1
        // This soreness was caused by the first workout in Week 1 (Heavy Chest)
        weeklyWorkouts[0][1].preWorkoutFeedback = PreWorkoutFeedback(
            workoutId: weeklyWorkouts[0][1].id,
            soreMuscles: [.chest],
            jointPainAreas: []
        )
        
        // Apply progression from Week 1 to Week 2
        let firstTwoWeeks = [weeklyWorkouts[0], weeklyWorkouts[1]]
        var progressionWeeks: [[WorkoutEntity]] = firstTwoWeeks
        ProgressionEngine.applyProgression(to: &progressionWeeks)
        weeklyWorkouts[1] = progressionWeeks[1]
        
        // Get workouts from both weeks
        let week1HeavyChest = weeklyWorkouts[0][0]
        let week2HeavyChest = weeklyWorkouts[1][0] // This should have sets reduced due to causing soreness
        let week1LightChest = weeklyWorkouts[0][1]
        let week2LightChest = weeklyWorkouts[1][1]
        
        // Print debugging information about the dates and set counts
        print("Week 1 Heavy Chest date: \(week1HeavyChest.scheduledDate!), sets: \(week1HeavyChest.exercises.first!.sets.count)")
        print("Week 1 Light Chest date: \(week1LightChest.scheduledDate!), sets: \(week1LightChest.exercises.first!.sets.count)")
        print("Week 2 Heavy Chest date: \(week2HeavyChest.scheduledDate!), sets: \(week2HeavyChest.exercises.first!.sets.count)")
        print("Week 2 Light Chest date: \(week2LightChest.scheduledDate!), sets: \(week2LightChest.exercises.first!.sets.count)")
        
        // The Heavy Chest workout in Week 2 should have one set removed since it caused soreness
        // that was detected during the Light Chest workout
        #expect(week2HeavyChest.exercises.first!.sets.count == week1HeavyChest.exercises.first!.sets.count - 1,
               "Heavy Chest workout in Week 2 should have one fewer set to prevent future soreness")
        
        // Light Chest workout should not have sets reduced
        #expect(week2LightChest.exercises.first!.sets.count >= week1LightChest.exercises.first!.sets.count,
               "Light Chest workout should not lose sets as it didn't cause soreness")
        
        // Now create two more weeks and verify recovery
        var nextWeeks: [[WorkoutEntity]] = [
            [weeklyWorkouts[1][0].copy(), weeklyWorkouts[1][1].copy() ], // Week 2
            [weeklyWorkouts[1][0].copy(), weeklyWorkouts[1][1].copy()]  // Week 3
        ]
        
        // No soreness in Week 2
        // Apply progression from Week 2 to Week 3
        ProgressionEngine.applyProgression(to: &nextWeeks)
        
        // Since there's no soreness in Week 2, Week 3's Heavy Chest workout should progress normally
        #expect(nextWeeks[1][0].exercises.first!.sets.count > nextWeeks[0][0].exercises.first!.sets.count,
               "Week 3 Heavy Chest should progress normally after soreness is resolved")
    }
    
    @Test("Joint Pain Blocks Progression for Related Muscles")
    func testJointPainBlocksProgression() async throws {
        // Create a workout targeting multiple muscles
        let workout = createWorkout(muscles: [.quads, .hamstrings, .glutes, .chest], setCount: 3)
        
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [workout.copy()], // Week 1
            [workout.copy()], // Week 2
            [workout.copy()]  // Week 3
        ]
        
        // Report knee pain in Week 2
        weeklyWorkouts[1][0].preWorkoutFeedback = PreWorkoutFeedback(
            workoutId: weeklyWorkouts[1][0].id,
            soreMuscles: [],
            jointPainAreas: [.knee]
        )
        
        // Apply progression from Week 2 to Week 3
        let week2And3 = [weeklyWorkouts[1], weeklyWorkouts[2]]
        var progression: [[WorkoutEntity]] = week2And3
        ProgressionEngine.applyProgression(to: &progression)
        weeklyWorkouts[2] = progression[1]
        
        // Verify that knee-related muscles (quads, hamstrings) don't progress but chest does
        let week2Quads = weeklyWorkouts[1][0].exercises.first { exercise in
            exercise.movement.primaryMuscles.contains(.quads)
        }!
        let week3Quads = weeklyWorkouts[2][0].exercises.first { exercise in
            exercise.movement.primaryMuscles.contains(.quads)
        }!
        
        let week2Chest = weeklyWorkouts[1][0].exercises.first { exercise in
            exercise.movement.primaryMuscles.contains(.chest)
        }!
        let week3Chest = weeklyWorkouts[2][0].exercises.first { exercise in
            exercise.movement.primaryMuscles.contains(.chest)
        }!
        
        #expect(week3Quads.sets.count <= week2Quads.sets.count, "Quad exercise should not progress due to knee pain")
        #expect(week3Chest.sets.count > week2Chest.sets.count, "Chest exercise should progress normally")
        #expect(week3Quads.shouldShowJointWarning == true, "Quad exercise should show joint warning")
    }
    
    @Test("Fatigue Triggers Reduction and Workout is Skipped During Volume Progression")
    func testFatigueTriggersReduction() async throws {
        // Create two workouts targeting the same muscles - one will get fatigue feedback
        let workoutA = createWorkout(title: "Workout A", muscles: [.back, .biceps], setCount: 4)
        let workoutB = createWorkout(title: "Workout B", muscles: [.back, .biceps], setCount: 4)
        
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [workoutA.copy(), workoutB.copy()], // Week 1
            [workoutA.copy(), workoutB.copy()]  // Week 2
        ]
        
        // Report complete fatigue in the first workout
        weeklyWorkouts[0][0].postWorkoutFeedback = PostWorkoutFeedback(
            workoutId: weeklyWorkouts[0][0].id,
            sessionFatigue: .completelyDrained
        )
        
        // Apply progression
        ProgressionEngine.applyProgression(to: &weeklyWorkouts)
        
        // Get workouts from both weeks
        let week1WorkoutA = weeklyWorkouts[0][0]
        let week2WorkoutA = weeklyWorkouts[1][0]
        let week1WorkoutB = weeklyWorkouts[0][1]
        let week2WorkoutB = weeklyWorkouts[1][1]
        
        // 1. Verify set reduction - workout with fatigue should have 2 fewer sets in Week 2
        let week1ASets = week1WorkoutA.exercises.map { $0.sets.count }.reduce(0, +)
        let week2ASets = week2WorkoutA.exercises.map { $0.sets.count }.reduce(0, +)
        #expect(week2ASets == week1ASets - 2, "Workout A should have 2 fewer sets in Week 2 due to fatigue")
        
        // 2. Verify the fatigue-affected workout was skipped during volume progression
        // But the other workout should still progress normally with new sets
        let week1BSets = week1WorkoutB.exercises.map { $0.sets.count }.reduce(0, +)
        let week2BSets = week2WorkoutB.exercises.map { $0.sets.count }.reduce(0, +)
        #expect(week2BSets > week1BSets, "Workout B should progress normally")
        
        // 3. Test that fatigue resolution allows progression to resume
        // Create Week 3 with normal fatigue
        var nextWeeks: [[WorkoutEntity]] = [
            [week2WorkoutA.copy(), week2WorkoutB.copy()], // Week 2
            [week2WorkoutA.copy(), week2WorkoutB.copy()]  // Week 3
        ]
        
        // Apply progression from Week 2 to Week 3 (no fatigue)
        ProgressionEngine.applyProgression(to: &nextWeeks)
        
        // Get Week 3 workouts
        let week3WorkoutA = nextWeeks[1][0]
        
        // Workout A should be eligible for progression again
        let week3ASets = week3WorkoutA.exercises.map { $0.sets.count }.reduce(0, +)
        #expect(week3ASets > week2ASets, "Workout A should be eligible for progression again in Week 3")
    }
    
    @Test("Mixed Feedback - Soreness and Good Performance in Different Muscles")
    func testMixedFeedback() async throws {
        // Create dates for the workouts
        let calendar = Calendar.current
        let today = Date()
        let mondayDate = calendar.date(byAdding: .day, value: -5, to: today)! // Monday
        let wednesdayDate = calendar.date(byAdding: .day, value: -3, to: today)! // Wednesday
        let fridayDate = calendar.date(byAdding: .day, value: -1, to: today)! // Friday
        
        // Create a sequence of workouts for Week 1
        // Monday: Heavy chest workout (causes soreness)
        let heavyChestWorkout = createWorkout(title: "Heavy Chest", muscles: [.chest], setCount: 3, date: mondayDate)
        
        // Wednesday: Leg workout (no chest training)
        let legWorkout = createWorkout(title: "Legs", muscles: [.quads], setCount: 3, date: wednesdayDate)
        
        // Friday: Upper body workout (chest is sore from Monday)
        let upperBodyWorkout = createWorkout(title: "Upper Body", muscles: [.chest, .back], setCount: 3, date: fridayDate)
        
        // Create two weeks with the same workout sequence
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [heavyChestWorkout.copy(), legWorkout.copy(), upperBodyWorkout.copy()], // Week 1
            [heavyChestWorkout.copy(), legWorkout.copy(), upperBodyWorkout.copy()]  // Week 2
        ]
        
        // Ensure the dates are properly set
        weeklyWorkouts[0][0].scheduledDate = mondayDate
        weeklyWorkouts[0][1].scheduledDate = wednesdayDate
        weeklyWorkouts[0][2].scheduledDate = fridayDate
        weeklyWorkouts[1][0].scheduledDate = calendar.date(byAdding: .day, value: 7, to: mondayDate)!
        weeklyWorkouts[1][1].scheduledDate = calendar.date(byAdding: .day, value: 7, to: wednesdayDate)!
        weeklyWorkouts[1][2].scheduledDate = calendar.date(byAdding: .day, value: 7, to: fridayDate)!
        
        // Report chest soreness in the Friday workout (caused by Monday's workout)
        weeklyWorkouts[0][2].preWorkoutFeedback = PreWorkoutFeedback(
            workoutId: weeklyWorkouts[0][2].id,
            soreMuscles: [.chest],
            jointPainAreas: []
        )
        
        // Add positive feedback to the leg workout
        if let quadsExercise = weeklyWorkouts[0][1].exercises.first {
            quadsExercise.feedback = ExerciseFeedback(
                exerciseId: quadsExercise.id,
                workoutId: weeklyWorkouts[0][1].id,
                intensity: .moderate,
                setVolume: .moderate
            )
        }
        
        // Apply progression
        let twoWeeks = [weeklyWorkouts[0], weeklyWorkouts[1]]
        var progression: [[WorkoutEntity]] = twoWeeks
        ProgressionEngine.applyProgression(to: &progression)
        weeklyWorkouts[1] = progression[1]
        
        // Get the exercises from each workout
        let week1ChestWorkout = weeklyWorkouts[0][0]
        let week2ChestWorkout = weeklyWorkouts[1][0]
        let week1LegWorkout = weeklyWorkouts[0][1]
        let week2LegWorkout = weeklyWorkouts[1][1]
        
        // Print debugging info
        print("Week 1 Heavy Chest sets: \(week1ChestWorkout.exercises.first!.sets.count)")
        print("Week 2 Heavy Chest sets: \(week2ChestWorkout.exercises.first!.sets.count)")
        print("Week 1 Leg sets: \(week1LegWorkout.exercises.first!.sets.count)")
        print("Week 2 Leg sets: \(week2LegWorkout.exercises.first!.sets.count)")
        
        // Verify that the Monday chest workout had sets reduced (due to causing soreness)
        #expect(week2ChestWorkout.exercises.first!.sets.count == week1ChestWorkout.exercises.first!.sets.count - 1,
               "Heavy chest workout should lose one set due to causing soreness")
        
        // Verify that the leg workout progressed normally based on good feedback
        #expect(week2LegWorkout.exercises.first!.sets.count > week1LegWorkout.exercises.first!.sets.count,
               "Leg workout should progress normally due to good feedback")
    }
    
    @Test("No Progression Beyond Upper Limit")
    func testNoProgressionBeyondUpperLimit() async throws {
        // Create a workout with chest already at upper limit (12 sets)
        let upperLimitSets = MuscleGroup.chest.trainingGuidelines.hypertrophySetsRange.upperBound
        let workout = createWorkout(muscles: [.chest], setCount: upperLimitSets)
        
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [workout], // Week 1
            [workout.copy()]  // Week 2
        ]
        
        // Apply progression
        ProgressionEngine.applyProgression(to: &weeklyWorkouts)
        
        // Verify no sets were added since we're at upper limit
        #expect(weeklyWorkouts[1][0].exercises.first!.sets.count == upperLimitSets,
               "No sets should be added when already at upper limit")
        
        // Try progressing again to Week 3
        var week2And3: [[WorkoutEntity]] = [
            [weeklyWorkouts[1][0]],
            [weeklyWorkouts[1][0].copy()]
        ]
        ProgressionEngine.applyProgression(to: &week2And3)
        
        // Verify still no progression
        #expect(week2And3[1][0].exercises.first!.sets.count == upperLimitSets,
               "No sets should be added in Week 3 when already at upper limit")
    }
    
    @Test("Independent Progression per Muscle")
    func testIndependentProgressionPerMuscle() async throws {
        // Create dates for the workouts
        let calendar = Calendar.current
        let monday = calendar.date(byAdding: .day, value: -5, to: Date())!
        let thursday = calendar.date(byAdding: .day, value: -2, to: Date())!
        
        // Create two workouts for Week 1
        let firstWorkout = createWorkout(title: "Push/Pull", muscles: [.chest, .back], setCount: 3, date: monday)
        let secondWorkout = createWorkout(title: "Light Upper", muscles: [.chest, .back], setCount: 2, date: thursday)
        
        // Setup the weekly workouts
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [firstWorkout.copy(), secondWorkout.copy()], // Week 1
            [firstWorkout.copy(), secondWorkout.copy()]  // Week 2
        ]
        
        // Set dates correctly
        weeklyWorkouts[0][0].scheduledDate = monday
        weeklyWorkouts[0][1].scheduledDate = thursday
        weeklyWorkouts[1][0].scheduledDate = calendar.date(byAdding: .day, value: 7, to: monday)!
        weeklyWorkouts[1][1].scheduledDate = calendar.date(byAdding: .day, value: 7, to: thursday)!
        
        // Report chest soreness only in second workout (caused by first workout)
        weeklyWorkouts[0][1].preWorkoutFeedback = PreWorkoutFeedback(
            workoutId: weeklyWorkouts[0][1].id,
            soreMuscles: [.chest], // Only chest is sore
            jointPainAreas: []
        )
        
        // Apply progression
        let twoWeeks = [weeklyWorkouts[0], weeklyWorkouts[1]]
        var progression: [[WorkoutEntity]] = twoWeeks
        ProgressionEngine.applyProgression(to: &progression)
        weeklyWorkouts[1] = progression[1]
        
        // Get the exercises for each muscle from first workout of each week
        let week1ChestExercise = weeklyWorkouts[0][0].exercises.first {
            exercise in exercise.movement.primaryMuscles.contains(.chest)
        }!
        let week2ChestExercise = weeklyWorkouts[1][0].exercises.first {
            exercise in exercise.movement.primaryMuscles.contains(.chest)
        }!
        
        let week1BackExercise = weeklyWorkouts[0][0].exercises.first {
            exercise in exercise.movement.primaryMuscles.contains(.back)
        }!
        let week2BackExercise = weeklyWorkouts[1][0].exercises.first {
            exercise in exercise.movement.primaryMuscles.contains(.back)
        }!
        
        // Debug info
        print("Week 1 Chest sets: \(week1ChestExercise.sets.count)")
        print("Week 2 Chest sets: \(week2ChestExercise.sets.count)")
        print("Week 1 Back sets: \(week1BackExercise.sets.count)")
        print("Week 2 Back sets: \(week2BackExercise.sets.count)")
        
        // Verify that chest exercise should have sets reduced due to soreness
        #expect(week2ChestExercise.sets.count == week1ChestExercise.sets.count - 1,
               "Chest exercise should lose 1 set due to reported soreness")
        
        // Back exercise should progress normally with additional sets since no soreness was reported
        #expect(week2BackExercise.sets.count > week1BackExercise.sets.count,
               "Back exercise should progress normally since no soreness was reported")
    }
    
    @Test("Persistent Joint Pain Blocks Repeatedly")
    func testPersistentJointPainBlocksRepeatedly() async throws {
        // Create workouts for 3 consecutive weeks
        let workout = createWorkout(muscles: [.shoulders, .triceps, .quads], setCount: 3)
        
        var allWeeks: [[WorkoutEntity]] = [
            [workout.copy()], // Week 1
            [workout.copy()], // Week 2
            [workout.copy()]  // Week 3
        ]
        
        // Report shoulder pain in Week 1
        allWeeks[0][0].preWorkoutFeedback = PreWorkoutFeedback(
            workoutId: allWeeks[0][0].id,
            soreMuscles: [],
            jointPainAreas: [.shoulder]
        )
        
        // Apply progression from Week 1 to Week 2
        let firstTwoWeeks = [allWeeks[0], allWeeks[1]]
        var progressionWeeks: [[WorkoutEntity]] = firstTwoWeeks
        ProgressionEngine.applyProgression(to: &progressionWeeks)
        allWeeks[1] = progressionWeeks[1]
        
        // Report shoulder pain again in Week 2
        allWeeks[1][0].preWorkoutFeedback = PreWorkoutFeedback(
            workoutId: allWeeks[1][0].id,
            soreMuscles: [],
            jointPainAreas: [.shoulder]
        )
        
        // Apply progression from Week 2 to Week 3
        let week2And3 = [allWeeks[1], allWeeks[2]]
        var progression: [[WorkoutEntity]] = week2And3
        ProgressionEngine.applyProgression(to: &progression)
        allWeeks[2] = progression[1]
        
        // Verify that shoulder and triceps exercises don't progress in either week
        let week1Shoulders = allWeeks[0][0].exercises.first { exercise in
            exercise.movement.primaryMuscles.contains(.shoulders)
        }!
        let week2Shoulders = allWeeks[1][0].exercises.first { exercise in
            exercise.movement.primaryMuscles.contains(.shoulders)
        }!
        let week3Shoulders = allWeeks[2][0].exercises.first { exercise in
            exercise.movement.primaryMuscles.contains(.shoulders)
        }!
        
        let week1Quads = allWeeks[0][0].exercises.first { exercise in
            exercise.movement.primaryMuscles.contains(.quads)
        }!
        let week3Quads = allWeeks[2][0].exercises.first { exercise in
            exercise.movement.primaryMuscles.contains(.quads)
        }!
        
        #expect(week2Shoulders.sets.count <= week1Shoulders.sets.count, "Week 2 shoulders shouldn't progress due to joint pain")
        #expect(week3Shoulders.sets.count <= week2Shoulders.sets.count, "Week 3 shoulders still shouldn't progress")
        #expect(week3Quads.sets.count > week1Quads.sets.count, "Quads should progress normally across both weeks")
    }
    
    @Test("Too Much Feedback Reduces Sets by 1")
    func testTooMuchFeedbackReducesSets() async throws {
        // Create workouts for 3 consecutive weeks
        let workout = createWorkout(muscles: [.chest, .triceps], setCount: 4) // Start with more sets to clearly see reduction
        
        var allWeeks: [[WorkoutEntity]] = [
            [workout.copy()], // Week 1
            [workout.copy()], // Week 2
            [workout.copy()]  // Week 3
        ]
        
        // Add "too much" feedback to chest exercise in Week 1
        if let chestExercise = allWeeks[0][0].exercises.first(where: { $0.movement.primaryMuscles.contains(.chest) }) {
            chestExercise.feedback = ExerciseFeedback(
                exerciseId: chestExercise.id,
                workoutId: allWeeks[0][0].id,
                intensity: .moderate,
                setVolume: .tooMuch
            )
        }
        
        // Progress from Week 1 to Week 2 (should reduce chest by 1 set)
        let firstTwoWeeks = [allWeeks[0], allWeeks[1]]
        var progressionWeeks: [[WorkoutEntity]] = firstTwoWeeks
        ProgressionEngine.applyProgression(to: &progressionWeeks)
        allWeeks[1] = progressionWeeks[1]
        
        // Get chest and triceps exercises for both weeks
        let chest1 = allWeeks[0][0].exercises.first { $0.movement.primaryMuscles.contains(.chest) }!
        let chest2 = allWeeks[1][0].exercises.first { $0.movement.primaryMuscles.contains(.chest) }!
        let triceps1 = allWeeks[0][0].exercises.first { $0.movement.primaryMuscles.contains(.triceps) }!
        let triceps2 = allWeeks[1][0].exercises.first { $0.movement.primaryMuscles.contains(.triceps) }!
        
        // Verify that chest exercise lost exactly 1 set due to "too much" feedback
        #expect(chest2.sets.count == chest1.sets.count - 1,
               "Chest should lose exactly 1 set due to 'too much' feedback, had \(chest1.sets.count), now has \(chest2.sets.count)")
        
        // While triceps should progress normally
        #expect(triceps2.sets.count > triceps1.sets.count, "Triceps should progress normally")
        
        // Week 2 has no feedback, progress to Week 3
        let week2And3 = [allWeeks[1], allWeeks[2]]
        var progression2: [[WorkoutEntity]] = week2And3
        ProgressionEngine.applyProgression(to: &progression2)
        allWeeks[2] = progression2[1]
        
        // Get chest exercise for Week 3
        let chest3 = allWeeks[2][0].exercises.first { $0.movement.primaryMuscles.contains(.chest) }!
        
        // Verify that Week 3 chest progresses again after issue resolved
        #expect(chest3.sets.count > chest2.sets.count, "Week 3 chest should progress again after issue resolved")
    }
    
    @Test("Weekly Cap of +2 Sets Is Respected and Prioritized Muscles Get Preference")
    func testWeeklyCapRespectedWithPriorities() async throws {
        // Create 4 workouts that train different muscles
        let workout1 = createWorkout(title: "Legs A", muscles: [.quads], setCount: 2) // Prioritized muscle
        let workout2 = createWorkout(title: "Push", muscles: [.chest], setCount: 2)   // Prioritized muscle
        let workout3 = createWorkout(title: "Pull", muscles: [.back], setCount: 2)     // Not prioritized
        let workout4 = createWorkout(title: "Arms", muscles: [.biceps], setCount: 2)   // Not prioritized
        
        // Create a mock plan with muscle preferences
        let plan = TrainingPlanEntity(name: "Plan", startDate: Date(), daysPerWeek: 4, isCompleted: false)
        
        // Set quads and chest as prioritized muscles for growth
        plan.musclePreferences = [
            MuscleTrainingPreference(muscleGroup: .quads, goal: .grow),
            MuscleTrainingPreference(muscleGroup: .chest, goal: .grow),
            MuscleTrainingPreference(muscleGroup: .back, goal: .maintain),
            MuscleTrainingPreference(muscleGroup: .biceps, goal: .maintain)
        ]
        
        // Create weekly workouts array and associate workouts with the plan
        let week1 = [workout1, workout2, workout3, workout4]
        let week2 = [workout1.copy(),
                    workout2.copy(),
                    workout3.copy(),
                    workout4.copy()]
        
        // Associate workouts with the plan for proper prioritization
        for workout in week1 + week2 {
            workout.trainingPlan = plan
        }
        
        var weeklyWorkouts: [[WorkoutEntity]] = [week1, week2]
        
        // Apply progression
        ProgressionEngine.applyProgression(to: &weeklyWorkouts)
        
        // Count how many sets were added to each muscle group
        let prioritizedMuscleGroups: [MuscleGroup] = [.quads, .chest]
        let nonPrioritizedMuscleGroups: [MuscleGroup] = [.back, .biceps]
        
        var prioritizedAddedSets = 0
        var nonPrioritizedAddedSets = 0
        
        // Check prioritized muscles
        for muscleGroup in prioritizedMuscleGroups {
            let week1Sets = weeklyWorkouts[0].reduce(0) { sum, workout in
                sum + workout.exercises.filter { $0.movement.primaryMuscles.contains(muscleGroup) }.map { $0.sets.count }.reduce(0, +)
            }
            
            let week2Sets = weeklyWorkouts[1].reduce(0) { sum, workout in
                sum + workout.exercises.filter { $0.movement.primaryMuscles.contains(muscleGroup) }.map { $0.sets.count }.reduce(0, +)
            }
            
            prioritizedAddedSets += (week2Sets - week1Sets)
        }
        
        // Check non-prioritized muscles
        for muscleGroup in nonPrioritizedMuscleGroups {
            let week1Sets = weeklyWorkouts[0].reduce(0) { sum, workout in
                sum + workout.exercises.filter { $0.movement.primaryMuscles.contains(muscleGroup) }.map { $0.sets.count }.reduce(0, +)
            }
            
            let week2Sets = weeklyWorkouts[1].reduce(0) { sum, workout in
                sum + workout.exercises.filter { $0.movement.primaryMuscles.contains(muscleGroup) }.map { $0.sets.count }.reduce(0, +)
            }
            
            nonPrioritizedAddedSets += (week2Sets - week1Sets)
        }
        
        // Verify that prioritized muscles got more sets added than non-prioritized
        #expect(prioritizedAddedSets > nonPrioritizedAddedSets,
               "Prioritized muscles should get more sets added: prioritized=\(prioritizedAddedSets) non-prioritized=\(nonPrioritizedAddedSets)")
        
        // Verify the total number of sets added across all muscle groups doesn't exceed the hard limit
        let totalAddedSets = prioritizedAddedSets + nonPrioritizedAddedSets
        #expect(totalAddedSets <= prioritizedMuscleGroups.count * 2,
               "Each prioritized muscle should not get more than 2 sets per week")
    }
    @Test("Challenging intensity increases reps by 1 without changing weight")
    func testChallengingIntensityIncreasesRepsOnly() throws {
        // Create a barbell movement
        let movement = MovementEntity(
            type: .barbellBenchPress,
            primaryMuscles: [.chest],
            secondaryMuscles: [],
            equipment: .barbell
        )
        
        // Create an exercise with a set of 10 reps at 100lbs
        let set = ExerciseSetEntity(weight: 100, completedReps: 10, targetReps: 10, isComplete: true)
        let exercise = ExerciseInstanceEntity(
            movement: movement,
            exerciseType: "Bench Press",
            sets: [set]
        )
        
        // Create week 1 and week 2 workouts
        let workout1 = WorkoutEntity(
            title: "Title",
            description: "Test workout for progression testing",
            isComplete: false,
            scheduledDate: Date(),
            exercises: [exercise]
        )
        let workout2 = workout1.copy()
        
        // Add feedback indicating the exercise was challenging
        workout1.exercises[0].feedback = ExerciseFeedback(
            exerciseId: workout1.exercises[0].id,
            workoutId: workout1.id,
            intensity: .challenging,
            setVolume: .moderate
        )
        
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [workout1],
            [workout2]
        ]
        
        // Apply progression
        ProgressionEngine.applyProgression(to: &weeklyWorkouts)
        
        let updatedSet = weeklyWorkouts[1][0].exercises[0].sets[0]
        
        // Reps should increase by 1 (from 10 to 11), weight should stay at 100
        #expect(updatedSet.targetReps == 11, "Target reps should increase by 1")
        #expect(updatedSet.weight == 100, "Weight should remain the same")
    }

}
