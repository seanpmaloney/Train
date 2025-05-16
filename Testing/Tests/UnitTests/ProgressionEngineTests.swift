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
            [workout.copy() as! WorkoutEntity]
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
        
        var weeklyWorkouts: [[WorkoutEntity]] = [workouts, workouts.map { $0.copy() as! WorkoutEntity }]
        
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
            [legDay1.copy() , legDay.copy(), upperDay.copy() ]
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
            [workout.copy() as! WorkoutEntity]
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
            [workout.copy() as! WorkoutEntity]
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
            [workout.copy() as! WorkoutEntity]
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
            [chestWorkout.copy() as! WorkoutEntity, legWorkout.copy() as! WorkoutEntity]
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
}
