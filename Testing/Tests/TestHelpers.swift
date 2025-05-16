import Testing
import Foundation
@testable import Train

/// TestHelpers.swift - Shared utilities and mock data for unit and UI tests.
/// This file provides common test data, mock objects, and helper functions.

// MARK: - Mock Data

struct MockData {
    // Mock workout data
    static func createMockWorkout(title: String = "Test Workout", 
                                 isComplete: Bool = false) -> WorkoutEntity {
        let workout = WorkoutEntity(
            title: title,
            description: "Test workout description",
            isComplete: isComplete
        )
        workout.exercises.append(createMockExercise())
        workout.exercises.append(createMockExercise())
        workout.exercises.append(createMockExercise())
        return workout
    }
    
    // Mock exercise data
    static func createMockExercise(movementType: MovementType = .barbellBenchPress) -> ExerciseInstanceEntity {
        let movement = MovementEntity(
            type: movementType,
            primaryMuscles: [MuscleGroup.chest],
            secondaryMuscles: [MuscleGroup.triceps],
            equipment: .barbell
        )
        
        return ExerciseInstanceEntity(
            movement: movement,
            exerciseType: "Strength",
            sets: [createMockSet()]
        )
    }
    
    static func createMockPlan() -> TrainingPlanEntity {
        let plan = TrainingPlanEntity(name: "Plan", notes: "Note", startDate: Date.now, daysPerWeek: 5, isCompleted: false)
        plan.weeklyWorkouts = Array(repeating: [], count: 1)
        plan.weeklyWorkouts[0].append(createMockWorkout(title: "workout1"))
        plan.weeklyWorkouts[0].append(createMockWorkout(title: "workout2"))
        plan.weeklyWorkouts[0].append(createMockWorkout(title: "workout3"))
        return plan
    }
    
    // Mock set data
    static func createMockSet(weight: Double = 100, 
                             completedReps: Int = 10, 
                             targetReps: Int = 10, 
                             isComplete: Bool = false) -> ExerciseSetEntity {
        return ExerciseSetEntity(
            weight: weight,
            completedReps: completedReps,
            targetReps: targetReps,
            isComplete: isComplete
        )
    }
}

// MARK: - Test Helpers

/// Wait for a specified time (in seconds)
func wait(for duration: TimeInterval) async {
    try? await Task.sleep(for: .seconds(duration))
}

// MARK: - Mock Classes

/// Mock data structure for tests that matches the internal SavedPlans in AppState
struct MockSavedPlans: Codable {
    let currentPlan: TrainingPlanEntity?
    let pastPlans: [TrainingPlanEntity]
    let scheduledWorkouts: [WorkoutEntity]
    let activeWorkout: WorkoutEntity?
}

/// Mock file manager for testing persistence operations
class MockFileManager: @unchecked Sendable {
    var fileExists = false
    var fileData: Data?
    var lastSavedData: Data?
    var lastSavedPath: String?
    var error: Error?
    
    func fileExists(atPath path: String) -> Bool {
        return fileExists
    }
    
    func contents(atPath path: String) -> Data? {
        return fileData
    }
    
    func createDirectory(at url: URL, withIntermediateDirectories: Bool, attributes: [FileAttributeKey: Any]?) throws {
        if let error = error {
            throw error
        }
    }
    
    func createFile(atPath path: String, contents data: Data?, attributes: [FileAttributeKey: Any]?) -> Bool {
        print("MockFileManager: Saving to \(path), data size: \(data?.count ?? 0) bytes")
        lastSavedPath = path
        lastSavedData = data
        return error == nil
    }
}

/// Testable AppState subclass with injectable dependencies for testing
@MainActor
class TestableAppState: AppState {
    // This is properly isolated to the MainActor
    var mockFileManager: MockFileManager?
    private let testFileName = "test_plans.json" // Use a different filename for tests
    
    // Override nonisolated methods with nonisolated implementations
    nonisolated override func getDocumentsURL() -> URL? {
        // Use a completely different path for tests to avoid any conflict with the app
        return URL(fileURLWithPath: "/tmp/test_documents")
    }
    
    nonisolated override func getFileManager() -> FileManager {
        // Since we can't access mockFileManager from nonisolated context,
        // we'll use it directly in the overridden methods
        return FileManager.default
    }
    
    // Make these methods nonisolated to match parent class
    nonisolated override func loadPlans() {
        // Since this is called from a nonisolated context, we need to bounce to MainActor
        Task { @MainActor in
            // Access mockFileManager on the main actor
            if let mockFileManager = self.mockFileManager {
                // Process mock data if needed
                if mockFileManager.fileExists, let data = mockFileManager.fileData {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    do {
                        let savedPlans = try decoder.decode(MockSavedPlans.self, from: data)
                        self.currentPlan = savedPlans.currentPlan
                        self.pastPlans = savedPlans.pastPlans
                        self.scheduledWorkouts = savedPlans.scheduledWorkouts
                        self.activeWorkout = savedPlans.activeWorkout
                    } catch {
                        print("Error decoding test data: \(error)")
                        // Initialize with empty data on error
                        self.currentPlan = nil
                        self.pastPlans = []
                        self.scheduledWorkouts = []
                        self.activeWorkout = nil
                    }
                } else {
                    // Initialize with empty data if no mock data exists
                    self.currentPlan = nil
                    self.pastPlans = []
                    self.scheduledWorkouts = []
                    self.activeWorkout = nil
                }
            } else {
                // No mock file manager, just initialize with empty data
                self.currentPlan = nil
                self.pastPlans = []
                self.scheduledWorkouts = []
                self.activeWorkout = nil
            }
            
            // CRITICAL: Must mark as loaded regardless of success/failure
            // This was missing before and caused tests to fail
            self.setLoaded(val: true)
        }
    }
    
    nonisolated override func savePlans() {
        Task { @MainActor in
            // Access mockFileManager safely on MainActor
            if let mockFileManager = self.mockFileManager {
                // Debug print state before saving
                print("TestableAppState: Saving state with currentPlan: \(String(describing: self.currentPlan?.name)), scheduledWorkouts: \(self.scheduledWorkouts.count)")
                
                // Create saved plans wrapper from main actor context
                let savedPlans = MockSavedPlans(
                    currentPlan: self.currentPlan,
                    pastPlans: self.pastPlans,
                    scheduledWorkouts: self.scheduledWorkouts,
                    activeWorkout: self.activeWorkout
                )
                
                // Use mock file manager for saving
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                do {
                    // This must happen on the main actor to ensure all properties are properly captured
                    let data = try encoder.encode(savedPlans)
                    print("TestableAppState: Encoded \(data.count) bytes of data")
                    
                    // Ensure path is properly constructed
                    let path = "/tmp/test_documents/\(self.testFileName)"
                    print("TestableAppState: Saving to path: \(path)")
                    
                    // Create the directory if it doesn't exist
                    let directoryURL = URL(fileURLWithPath: "/tmp/test_documents")
                    if !FileManager.default.fileExists(atPath: directoryURL.path) {
                        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
                    }
                    
                    // Save the data using the mock file manager
                    if mockFileManager.createFile(atPath: path, contents: data, attributes: nil) {
                        // Update the mock file manager's state for future loadPlans calls
                        mockFileManager.fileExists = true
                        mockFileManager.fileData = data
                    }
                    
                    // Verify the data was saved
                    print("TestableAppState: Data saved, mockFileManager.lastSavedPath: \(String(describing: mockFileManager.lastSavedPath))")
                    print("TestableAppState: Data saved, mockFileManager.lastSavedData size: \(mockFileManager.lastSavedData?.count ?? 0) bytes")
                } catch {
                    print("Error encoding test data: \(error)")
                }
            } else {
                print("TestableAppState: No mockFileManager available for saving")
            }
            // Don't call super.savePlans() to avoid touching real files
        }
    }
    
    // Override initializer to avoid loading from real files
    override init() {
        super.init()
        // Set custom filename for testing using the new helper method
        self.setCustomFileName(testFileName)
        // Mark as loaded immediately for tests that don't explicitly call loadPlans
        self.setLoaded(val: true)
    }
}
