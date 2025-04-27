import Testing
import UIKit

@Suite("Workout Flow UI Tests")
struct WorkoutFlowUITests {
    // MARK: - Properties
    
    // For UI Testing with the new Swift Testing framework, we use the TestPlan 
    // configuration and UITestSession instead of XCUIApplication
    
    @Test("Start Workout button navigates to workout screen")
    func testStartWorkoutButtonNavigatesToWorkoutScreen() async throws {
        // Launch the app with specific testing configurations
        let app = try await UITestSession.launch(named: "Train")
        
        // Find and tap the "Start Workout" button
        try await app.find(.button, named: "StartWorkoutButton").tap()
        
        // Assert that the workout screen exists
        try await app.assert(.element, named: "WorkoutInProgressView", exists: true)
    }
    
    @Test("End Workout button shows confirmation dialog")
    func testCompleteWorkoutShowsConfirmationDialog() async throws {
        // Launch the app
        let app = try await UITestSession.launch(named: "Train")
        
        // Navigate to active workout screen
        try await app.find(.button, named: "StartWorkoutButton").tap()
        
        // Find and tap the "End Workout" button
        let endWorkoutButton = try await app.find(.button, named: "EndWorkoutButton")
        try await endWorkoutButton.tap()
        
        // Assert that the confirmation dialog appears
        let confirmationAlert = try await app.find(.alert)
        
        // Verify the dialog has the expected buttons
        try await confirmationAlert.find(.button, named: "Cancel")
        try await confirmationAlert.find(.button, named: "End Workout")
    }
    
    @Test("Exercise card shows history when swiped horizontally")
    func testExerciseCardShowsHistoryWhenSwiped() async throws {
        // Launch the app
        let app = try await UITestSession.launch(named: "Train")
        
        // Navigate to a workout with a history-enabled exercise card
        try await app.find(.button, named: "StartWorkoutButton").tap()
        
        // Find an exercise card with history
        let exerciseCard = try await app.find(.element, named: "ExerciseCard")
        
        // Swipe right to see history
        try await exerciseCard.swipeRight()
        
        // Verify history indicator is present
        try await app.assert(.text, named: "HistoryLabel", exists: true)
    }
    
    @Test("Exercise list scrolls vertically when dragged")
    func testScrollingScrollsVerticallyWhenDragged() async throws {
        // Launch the app
        let app = try await UITestSession.launch(named: "Train")
        
        // Navigate to workout screen
        try await app.find(.button, named: "StartWorkoutButton").tap()
        
        // Find the scroll view and scroll down
        let scrollView = try await app.find(.scrollView)
        
        // In Swift Testing, we can use the drag operation directly
        try await scrollView.drag(from: CGPoint(x: 0.5, y: 0.7),
                                 to: CGPoint(x: 0.5, y: 0.3))
        
        // Verify scroll position changed by checking if a bottom element is now visible
        try await app.assert(.text, named: "BottomElement", exists: true)
    }
}
