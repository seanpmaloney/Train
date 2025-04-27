import Testing
@testable import Train

@Suite("EnhancedActiveWorkoutViewModel Tests")
struct EnhancedActiveWorkoutViewModelTests {
    // MARK: - Properties
    
    private var viewModel: EnhancedActiveWorkoutViewModel!
    private var mockWorkout: WorkoutEntity!
    private var mockAppState: TestableAppState!
    
    // MARK: - Setup and Teardown
    
    func setUp() {
        // Initialize test dependencies before each test
        mockAppState = TestableAppState()
        mockWorkout = MockData.createMockWorkout()
        
        // Add some exercises to the workout
        let exercise1 = MockData.createMockExercise(movementType: .benchPress)
        let exercise2 = MockData.createMockExercise(movementType: .squats)
        mockWorkout.exercises = [exercise1, exercise2]
        
        // Set up view model with mock data
        viewModel = EnhancedActiveWorkoutViewModel(workout: mockWorkout)
    }
    
    func tearDown() {
        // Clean up after each test
        viewModel = nil
        mockWorkout = nil
        mockAppState = nil
    }
    
    // MARK: - Tests
    
    @Test("Completion percentage is zero when no exercises are complete")
    func testGetCompletionPercentageWhenNoExercisesComplete() {
        // Given
        let workout = MockData.createMockWorkout()
        let exercise1 = MockData.createMockExercise()
        let exercise2 = MockData.createMockExercise()
        
        // Ensure no sets are complete
        exercise1.sets.forEach { $0.isComplete = false }
        exercise2.sets.forEach { $0.isComplete = false }
        
        workout.exercises = [exercise1, exercise2]
        let viewModel = EnhancedActiveWorkoutViewModel(workout: workout)
        
        // When
        let percentage = viewModel.getCompletionPercentage()
        
        // Then
        #expect(percentage == 0.0)
    }
    
    @Test("Completion percentage is 0.5 when half of exercises are complete")
    func testGetCompletionPercentageWhenHalfExercisesComplete() {
        // Given
        let workout = MockData.createMockWorkout()
        let exercise1 = MockData.createMockExercise()
        let exercise2 = MockData.createMockExercise()
        
        // Make first exercise's sets complete, second exercise's sets incomplete
        exercise1.sets.forEach { $0.isComplete = true }
        exercise2.sets.forEach { $0.isComplete = false }
        
        workout.exercises = [exercise1, exercise2]
        let viewModel = EnhancedActiveWorkoutViewModel(workout: workout)
        
        // When
        let percentage = viewModel.getCompletionPercentage()
        
        // Then
        #expect(abs(percentage - 0.5) < 0.001)
    }
    
    @Test("Workout is marked as complete when completing workout")
    func testCompleteWorkoutMarksWorkoutAsComplete() {
        // Given
        #expect(!viewModel.isComplete)
        
        // When
        viewModel.completeWorkout(appState: mockAppState)
        
        // Then
        #expect(viewModel.isComplete)
        #expect(mockWorkout.isComplete)
    }
    
    @Test("Set is marked complete when calling markSetComplete")
    func testMarkSetCompleteUpdatesSetCompletionStatus() {
        // Given
        guard let exercise = viewModel.exercises.first,
              let set = exercise.sets.first else {
            #fail("Test setup failed - exercise or set missing")
            return
        }
        #expect(!set.isComplete)
        
        // When
        viewModel.markSetComplete(set: set, isComplete: true)
        
        // Then
        #expect(set.isComplete)
    }
    
    @Test("Set details are updated with new weight and reps")
    func testUpdateSetDetailsChangesWeightAndReps() {
        // Given
        guard let exercise = viewModel.exercises.first,
              let set = exercise.sets.first else {
            #fail("Test setup failed - exercise or set missing")
            return
        }
        let originalWeight = set.weight
        let originalReps = set.completedReps
        let newWeight = originalWeight + 10
        let newReps = originalReps + 2
        
        // When
        viewModel.updateSetDetails(set: set, weight: newWeight, completedReps: newReps)
        
        // Then
        #expect(set.weight == newWeight)
        #expect(set.completedReps == newReps)
    }
    
    @Test("Exercise history returns historical instances")
    func testGetExerciseHistoryReturnsHistoricalInstances() {
        // Given
        let appState = TestableAppState()
        let currentExercise = MockData.createMockExercise(movementType: .benchPress)
        
        // Create past workout with same exercise type
        let pastWorkout = MockData.createMockWorkout(title: "Past Workout", isComplete: true)
        let pastExercise = MockData.createMockExercise(movementType: .benchPress)
        pastWorkout.exercises = [pastExercise]
        
        // Add to app state
        appState.pastPlans = [pastWorkout]
        viewModel.connectAppState(appState)
        
        // When
        let history = viewModel.getExerciseHistory(for: currentExercise)
        
        // Then
        #expect(history.count >= 1)
    }
}
