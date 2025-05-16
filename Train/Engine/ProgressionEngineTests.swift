import Foundation
import Testing
@testable import Train

@Suite("ProgressionEngine Tests")
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
        let workout = WorkoutEntity(id: id, title: title)
        workout.scheduledDate = date
        
        // Create one exercise per muscle
        for muscle in muscles {
            let movement = MovementEntity()
            movement.name = "\(muscle.rawValue) Exercise"
            movement.primaryMuscles = [muscle]
            
            let exercise = ExerciseInstanceEntity()
            exercise.movement = movement
            
            // Add the specified number of sets
            for _ in 0..<setCount {
                exercise.sets.append(ExerciseSetEntity())
            }
            
            workout.exercises.append(exercise)
        }
        
        return workout
    }
    
    /// Create a week of workouts targeting different muscle groups
    private func createWeekOfWorkouts() -> [WorkoutEntity] {
        return [
            createWorkout(title: "Push Day", muscles: [.chest, .shoulders, .triceps]),
            createWorkout(title: "Pull Day", muscles: [.upperBack, .biceps, .forearms]),
            createWorkout(title: "Leg Day", muscles: [.quads, .hamstrings, .calves]),
            createWorkout(title: "Upper Body", muscles: [.chest, .upperBack, .biceps, .triceps]),
            createWorkout(title: "Lower Body", muscles: [.quads, .hamstrings, .glutes])
        ]
    }
    
    /// Create a collection of workout feedback with pre, exercise and post feedback
    private func createFeedbackCollection(
        workoutId: UUID,
        soreMuscles: [MuscleGroup] = [],
        jointPain: [JointArea] = [],
        fatigue: FatigueLevel = .moderate,
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
        let feedbackMap: [UUID: [WorkoutFeedback]] = [:]
        
        // Apply progression
        await ProgressionEngine.applyProgression(to: &weeklyWorkouts, using: feedbackMap)
        
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
    
    @Test("Muscle at upper limit should not have sets added")
    func testNoProgressionAtUpperLimit() async throws {
        // Setup with 5 sets per exercise to hit upper limits
        let maxSetCount = 5
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [createWorkout(muscles: [.chest], setCount: maxSetCount)],
            [createWorkout(muscles: [.chest], setCount: maxSetCount)]
        ]
        
        let feedbackMap: [UUID: [WorkoutFeedback]] = [:]
        
        // Apply progression
        await ProgressionEngine.applyProgression(to: &weeklyWorkouts, using: feedbackMap)
        
        // Check that sets weren't added 
        let chestExercise = weeklyWorkouts[1][0].exercises.first!
        #expect(chestExercise.sets.count == maxSetCount)
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
        let feedbackMap: [UUID: [WorkoutFeedback]] = [:]
        
        // Apply progression - should add 2 sets total across workouts
        await ProgressionEngine.applyProgression(to: &weeklyWorkouts, using: feedbackMap)
        
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
        let workout = createWorkout(muscles: [.chest], setCount: 3)
        let exercise = workout.exercises.first!
        
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [workout],
            [workout.copy() as! WorkoutEntity]
        ]
        
        // Create feedback indicating the exercise has too much volume
        let feedbackMap: [UUID: [WorkoutFeedback]] = [
            workout.id: [ExerciseFeedback(exerciseId: exercise.id, workoutId: workout.id, intensity: .moderate, setVolume: .tooMuch)]
        ]
        
        // Apply progression
        await ProgressionEngine.applyProgression(to: &weeklyWorkouts, using: feedbackMap)
        
        // Check that sets weren't added
        let nextWeekExercise = weeklyWorkouts[1][0].exercises.first!
        #expect(nextWeekExercise.sets.count == exercise.sets.count)
    }
    
    @Test("Sore muscle should have sets reduced in previous workout pattern")
    func testSoreMuscleReduction() async throws {
        // Create two workouts in sequence - leg day first, then upper body
        let legDay = createWorkout(title: "Leg Day", muscles: [.quads], setCount: 3)
        let upperDay = createWorkout(title: "Upper Day", muscles: [.chest], setCount: 3)
        
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [legDay, upperDay],
            [legDay.copy() as! WorkoutEntity, upperDay.copy() as! WorkoutEntity]
        ]
        
        // Report quads as sore during upper day
        let feedbackMap: [UUID: [WorkoutFeedback]] = [
            upperDay.id: [PreWorkoutFeedback(workoutId: upperDay.id, soreMuscles: [.quads], jointPainAreas: [])]
        ]
        
        // Apply progression
        await ProgressionEngine.applyProgression(to: &weeklyWorkouts, using: feedbackMap)
        
        // Check that leg day in the next week has had sets reduced
        let nextWeekLegDay = weeklyWorkouts[1][0]
        #expect(nextWeekLegDay.exercises.first!.sets.count == 2) // Reduced from 3 to 2
    }
    
    @Test("Completely drained session should reduce 2 sets from next week")
    func testCompletelyDrainedReduction() async throws {
        let workout = createWorkout(muscles: [.chest, .shoulders, .triceps], setCount: 3)
        
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [workout],
            [workout.copy() as! WorkoutEntity]
        ]
        
        // Mark workout as completely drained
        let feedbackMap: [UUID: [WorkoutFeedback]] = [
            workout.id: [PostWorkoutFeedback(workoutId: workout.id, sessionFatigue: .completelyDrained)]
        ]
        
        // Apply progression
        await ProgressionEngine.applyProgression(to: &weeklyWorkouts, using: feedbackMap)
        
        // Count total sets before and after
        let originalSetCount = workout.exercises.reduce(0) { $0 + $1.sets.count }
        let newSetCount = weeklyWorkouts[1][0].exercises.reduce(0) { $0 + $1.sets.count }
        
        // Should have 2 fewer sets total
        #expect(newSetCount == originalSetCount - 2)
    }
    
    @Test("Joint pain in knee should flag all related exercises")
    func testJointPainFlagging() async throws {
        let workout = createWorkout(muscles: [.quads, .chest], setCount: 3)
        
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [workout],
            [workout.copy() as! WorkoutEntity]
        ]
        
        // Report knee pain
        let feedbackMap: [UUID: [WorkoutFeedback]] = [
            workout.id: [PreWorkoutFeedback(workoutId: workout.id, soreMuscles: [], jointPainAreas: [.knee])]
        ]
        
        // Apply progression
        await ProgressionEngine.applyProgression(to: &weeklyWorkouts, using: feedbackMap)
        
        // Check that lower body exercises are flagged
        let nextWeekWorkout = weeklyWorkouts[1][0]
        let quadExercise = nextWeekWorkout.exercises.first { 
            $0.movement.primaryMuscles.contains(.quads)
        }
        let chestExercise = nextWeekWorkout.exercises.first {
            $0.movement.primaryMuscles.contains(.chest)
        }
        
        // Quad exercise should be flagged, chest should not
        #expect(quadExercise?.shouldShowJointWarning == true)
        #expect(chestExercise?.shouldShowJointWarning == false)
    }
    
    // MARK: - Safeguard Tests
    
    @Test("No exercise should exceed 5 sets")
    func testNoExerciseExceedsFiveSets() async throws {
        let workout = createWorkout(muscles: [.quads], setCount: 4)
        
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [workout],
            [workout.copy() as! WorkoutEntity]
        ]
        
        // Create empty feedback to allow progression
        let feedbackMap: [UUID: [WorkoutFeedback]] = [:]
        
        // Apply progression - should try to add sets
        await ProgressionEngine.applyProgression(to: &weeklyWorkouts, using: feedbackMap)
        
        // Check exercise doesn't exceed 5 sets
        let nextWeekExercise = weeklyWorkouts[1][0].exercises.first!
        #expect(nextWeekExercise.sets.count <= 5)
    }
    
    @Test("Non-targeted muscles shouldn't get sets added")
    func testNonTargetedMusclesUnchanged() async throws {
        let workout = createWorkout(muscles: [.quads, .chest], setCount: 3)
        
        var weeklyWorkouts: [[WorkoutEntity]] = [
            [workout],
            [workout.copy() as! WorkoutEntity]
        ]
        
        // Create feedback to mark chest at too much
        let chestExercise = workout.exercises.first { 
            $0.movement.primaryMuscles.contains(.chest)
        }!
        
        let feedbackMap: [UUID: [WorkoutFeedback]] = [
            workout.id: [ExerciseFeedback(
                exerciseId: chestExercise.id, 
                workoutId: workout.id,
                intensity: .moderate, 
                setVolume: .tooMuch
            )]
        ]
        
        // Apply progression
        await ProgressionEngine.applyProgression(to: &weeklyWorkouts, using: feedbackMap)
        
        // Check that quads received progression but chest didn't
        let nextWeekWorkout = weeklyWorkouts[1][0]
        
        let nextWeekQuads = nextWeekWorkout.exercises.first { 
            $0.movement.primaryMuscles.contains(.quads)
        }!
        
        let nextWeekChest = nextWeekWorkout.exercises.first { 
            $0.movement.primaryMuscles.contains(.chest)
        }!
        
        // Quads should get a set added, chest should remain unchanged
        #expect(nextWeekQuads.sets.count > 3)
        #expect(nextWeekChest.sets.count == 3)
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
        
        var weeklyWorkouts: [[WorkoutEntity]] = [workouts, workouts.map { $0.copy() as! WorkoutEntity }]
        let feedbackMap: [UUID: [WorkoutFeedback]] = [:]
        
        // Apply progression
        await ProgressionEngine.applyProgression(to: &weeklyWorkouts, using: feedbackMap)
        
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
}
