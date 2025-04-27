import Testing
import Foundation
@testable import Train

/// AppStateTests - Tests for the AppState class
/// Focuses on validating the persistence and plan management functionality

@Suite("AppState Tests")
struct AppStateTests {
    
    // MARK: - Persistence Tests
    
    @Test("Test saving plans")
    func testSavePlans() async throws {

    }
    
    @Test("Test loading plans when file exists")
    func testLoadPlansWhenFileExists() async throws {
        // Create a mock file manager
        let mockFileManager = MockFileManager()
        
        // Setup mock data on the MainActor
        let mockData = await MainActor.run {
            // Create mock saved plans data with specific test values
            let pastPlan = MockData.createMockPlan()
            pastPlan.name = "Past Plan" // Set specific name for testing
            
            let currentPlan = MockData.createMockPlan()
            currentPlan.name = "Current Plan"
            
            let mockScheduledWorkout = MockData.createMockWorkout(title: "Scheduled Test")
            mockScheduledWorkout.scheduledDate = Date()
            
            // Create the mock structure
            let mockSavedPlans = MockSavedPlans(
                currentPlan: currentPlan,
                pastPlans: [pastPlan],
                scheduledWorkouts: [mockScheduledWorkout],
                activeWorkout: nil
            )
            
            // Encode the mock data
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try! encoder.encode(mockSavedPlans)
        }
        
        // Setup the mock file manager to return this data
        mockFileManager.fileExists = true
        mockFileManager.fileData = mockData
        
        // Create the AppState with the mock file manager
        let appState = await MainActor.run {
            let state = TestableAppState()
            state.mockFileManager = mockFileManager
            // Make sure isLoaded is false initially so we can verify it gets set
            state.setLoaded(val: false)
            return state
        }
        
        // When: Load the plans
        appState.loadPlans()
        
        // Wait for async operations to complete
        try await Task.sleep(for: .milliseconds(500))
        
        // Then: Verify the loaded data
        await MainActor.run {
            // Verify that the isLoaded flag is set
            #expect(appState.isLoaded, "AppState should be marked as loaded")
            
            // Verify the current plan was loaded correctly
            #expect(appState.currentPlan != nil, "Current plan should not be nil")
            #expect(appState.currentPlan?.name == "Current Plan", "Current plan should have the correct name")
            
            // Verify the past plans were loaded correctly
            #expect(appState.pastPlans.count == 1, "There should be 1 past plan")
            #expect(appState.pastPlans.first?.name == "Past Plan", "Past plan should have correct title")
            
            // Verify scheduled workouts were loaded correctly
            #expect(appState.scheduledWorkouts.count == 1, "There should be 1 scheduled workout")
            #expect(appState.scheduledWorkouts.first?.title == "Scheduled Test", "Scheduled workout should have correct title")
        }
    }
    
    @Test("Test loading plans when file doesn't exist")
    func testLoadPlansWhenFileDoesNotExist() async throws {
        // Given: A mock file manager where the file doesn't exist
        let mockFileManager = MockFileManager()
        mockFileManager.fileExists = false // Explicitly set to false
        mockFileManager.fileData = nil
        
        // Create the AppState with this mock file manager
        let appState = await MainActor.run {
            let state = TestableAppState()
            state.mockFileManager = mockFileManager
            
            // Since we're going to call loadPlans(), temporarily set isLoaded to false
            // to verify it gets set back to true
            state.setLoaded(val: false)
            
            return state
        }
        
        // When: Load the plans
        appState.loadPlans()
        
        // Wait for async operations to complete
        try await Task.sleep(for: .milliseconds(500))
        
        // Then: Verify that even with no file, state is properly initialized
        await MainActor.run {
            // Verify isLoaded flag is set even when file doesn't exist
            #expect(appState.isLoaded, "AppState should be marked as loaded even when file doesn't exist")
            
            // Verify default state
            #expect(appState.currentPlan == nil, "Current plan should be nil")
            #expect(appState.pastPlans.isEmpty, "Past plans should be empty")
            #expect(appState.scheduledWorkouts.isEmpty, "Scheduled workouts should be empty")
        }
    }
    
    @Test("Test loading plans with corrupted data")
    func testLoadPlansWithCorruptedData() async throws {
        // Given: A mock file manager with corrupted data
        let mockFileManager = MockFileManager()
        mockFileManager.fileExists = true
        mockFileManager.fileData = "This is not valid JSON".data(using: .utf8) // Corrupted data
        
        // Create the AppState with this mock file manager
        let appState = await MainActor.run {
            let state = TestableAppState()
            state.mockFileManager = mockFileManager
            
            // Since we're going to call loadPlans(), temporarily set isLoaded to false
            // to verify it gets set back to true
            state.setLoaded(val: false)
            
            return state
        }
        
        // When: Load the plans with corrupted data
        appState.loadPlans()
        
        // Wait for async operations to complete
        try await Task.sleep(for: .milliseconds(500))
        
        // Then: Verify that app state handles corrupted data gracefully
        await MainActor.run {
            // Verify isLoaded flag is set even when data is corrupted
            #expect(appState.isLoaded, "AppState should be marked as loaded even with corrupted data")
            
            // Verify state is reset to defaults on corrupt data
            #expect(appState.currentPlan == nil, "Current plan should be nil when data is corrupted")
            #expect(appState.pastPlans.isEmpty, "Past plans should be empty when data is corrupted")
            #expect(appState.scheduledWorkouts.isEmpty, "Scheduled workouts should be empty when data is corrupted")
        }
    }
    
    @Test("Test round-trip persistence")
    func testRoundTripPersistence() async throws {

    }
    
    @Test("Test setting current plan")
    func testSetCurrentPlan() async throws {

    }
    
    @Test("Test archiving current plan")
    func testArchiveCurrentPlan() async throws {
 
    }
    
    @Test("Test deleting past plan")
    func testDeletePastPlan() async throws {

    }
    
    @Test("Test scheduling workout")
    func testScheduleWorkout() async throws {

    }
    
    @Test("Test unscheduling workout")
    func testUnscheduleWorkout() async throws {
        // Given

    }
    
    @Test("Test getting workouts for date")
    func testGetWorkoutsForDate() async throws {
        // Given

    }
    
    @Test("Test marking workout complete")
    func testMarkWorkoutComplete() async throws {
       
    }
}
