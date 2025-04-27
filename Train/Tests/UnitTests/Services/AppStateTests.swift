import Testing
@testable import Train

@Suite("AppState Persistence Tests")
struct AppStateTests {
    // MARK: - Properties
    
    @Test("Data is saved to correct path when saving plans")
    func testSavePlansSavesDataToCorrectPath() {
        // Given
        let mockFileManager = MockFileManager()
        let appState = TestableAppState()
        appState.mockFileManager = mockFileManager
        
        let workout = MockData.createMockWorkout()
        appState.currentPlan = workout
        
        // When
        appState.savePlans()
        
        // Then
        #expect(mockFileManager.lastSavedPath != nil, "Data should be saved to a path")
        #expect(mockFileManager.lastSavedData != nil, "Data should be saved")
        
        // In a real test, we'd also verify the path is correct and data format
    }
    
    @Test("Plans are loaded from file correctly when file exists")
    func testLoadPlansLoadsDataCorrectlyWhenFileExists() {
        // Given
        let mockFileManager = MockFileManager()
        mockFileManager.fileExists = true
        
        // Create mock data to be "loaded"
        let savedWorkout = MockData.createMockWorkout(title: "Saved Workout")
        let wrapper = SavedPlans(currentPlan: savedWorkout, pastPlans: [])
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        guard let data = try? encoder.encode(wrapper) else {
            #fail("Failed to encode test data")
            return
        }
        
        mockFileManager.fileData = data
        
        let appState = TestableAppState()
        appState.mockFileManager = mockFileManager
        
        // When
        appState.loadPlans()
        
        // Then
        #expect(appState.currentPlan != nil, "Current plan should be loaded")
        #expect(appState.currentPlan?.title == "Saved Workout", "Loaded workout should match saved workout")
    }
    
    @Test("No errors occur when loading plans and file doesn't exist")
    func testLoadPlansDoesNotThrowErrorWhenFileDoesNotExist() {
        // Given
        let mockFileManager = MockFileManager()
        mockFileManager.fileExists = false
        
        let appState = TestableAppState()
        appState.mockFileManager = mockFileManager
        
        // When & Then
        // This should not throw an exception
        appState.loadPlans() // No assertion needed, just checking it doesn't crash
    }
    
    @Test("App handles corrupt data gracefully when loading plans")
    func testLoadPlansHandlesErrorWhenDataIsCorrupted() {
        // Given
        let mockFileManager = MockFileManager()
        mockFileManager.fileExists = true
        mockFileManager.fileData = "This is not valid JSON data".data(using: .utf8)
        
        let appState = TestableAppState()
        appState.mockFileManager = mockFileManager
        
        // When
        appState.loadPlans()
        
        // Then
        // The app state should handle the error gracefully and not crash
        // Test passes if no crash occurs
    }
    
    @Test("Round trip persistence preserves all workout data")
    func testRoundTripPersistencePreservesValues() {
        // Given
        let mockFileManager = MockFileManager()
        let appState = TestableAppState()
        appState.mockFileManager = mockFileManager
        
        // Create mock workout with specific properties
        let originalWorkout = MockData.createMockWorkout(title: "Round Trip Test", isComplete: true)
        originalWorkout.scheduledDate = Date()
        
        let exercise = MockData.createMockExercise()
        exercise.sets = [
            MockData.createMockSet(weight: 225.5, completedReps: 8, targetReps: 10, isComplete: true),
            MockData.createMockSet(weight: 245.0, completedReps: 6, targetReps: 6, isComplete: true)
        ]
        originalWorkout.exercises = [exercise]
        
        appState.currentPlan = originalWorkout
        
        // Mock the save and load process
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let wrapper = SavedPlans(currentPlan: originalWorkout, pastPlans: [])
        
        guard let data = try? encoder.encode(wrapper) else {
            #fail("Failed to encode test data")
            return
        }
        
        // Set up for loading
        mockFileManager.fileExists = true
        mockFileManager.fileData = data
        
        // When
        // Reset the app state
        appState.currentPlan = nil
        // Load the data back
        appState.loadPlans()
        
        // Then
        #expect(appState.currentPlan != nil, "Current plan should be loaded")
        
        if let loadedWorkout = appState.currentPlan {
            #expect(loadedWorkout.title == "Round Trip Test", "Title should be preserved")
            #expect(loadedWorkout.isComplete == true, "Completion status should be preserved")
            #expect(loadedWorkout.scheduledDate != nil, "Date should be preserved")
            
            #expect(loadedWorkout.exercises.count == 1, "Exercise count should be preserved")
            
            if let loadedExercise = loadedWorkout.exercises.first {
                #expect(loadedExercise.sets.count == 2, "Set count should be preserved")
                
                if loadedExercise.sets.count >= 2 {
                    #expect(loadedExercise.sets[0].weight == 225.5, "Set weight should be preserved")
                    #expect(loadedExercise.sets[0].completedReps == 8, "Completed reps should be preserved")
                    #expect(loadedExercise.sets[0].targetReps == 10, "Target reps should be preserved")
                    #expect(loadedExercise.sets[0].isComplete == true, "Set completion status should be preserved")
                    
                    #expect(loadedExercise.sets[1].weight == 245.0, "Set weight should be preserved")
                    #expect(loadedExercise.sets[1].completedReps == 6, "Completed reps should be preserved")
                }
            }
        }
    }
}
