# Train App Testing Architecture

This document outlines the testing architecture for the Train app, following Apple's best practices for iOS development. The testing structure uses the modern Swift Testing framework (introduced with Xcode 16) to ensure code quality, maintainability, and reliability through comprehensive unit and UI testing.

## Testing Structure

```
/Tests/
    /UnitTests/           # Unit tests for individual components
        /ViewModels/      # Tests for view models
        /Services/        # Tests for services and data handling
        /Utilities/       # Tests for utility functions and extensions
    /UITests/             # UI tests for user flows
        /Flows/           # Organized by user flow
            /TrainingFlow/
            /WorkoutFlow/
    TestHelpers.swift     # Shared test helpers and mock data
    Train.xctestplan      # Test plan configuration
```

## Key Testing Principles

1. **Test Independence**
   - Each test is completely independent and does not rely on the state of other tests.
   - Swift Testing enables stateless testing with structs rather than classes.

2. **Given/When/Then Structure**
   - Tests are structured in a given/when/then format for clarity:
     - **Given**: Set up test prerequisites and inputs
     - **When**: Execute the code being tested
     - **Then**: Assert that the outputs match expectations using the `#expect` macro

3. **Naming Conventions**
   - Test suites: Use the `@Suite` annotation with a descriptive name
   - Test methods: Use the `@Test` annotation with a descriptive name
   - Method naming: `test<FunctionalityBeingTested><Condition>` (e.g., `testMarkSetCompleteUpdatesSetCompletionStatus`)
   
4. **Mocking & Dependency Injection**
   - Use mock objects (like `MockFileManager`) for external dependencies
   - Inject dependencies as needed for isolation testing

## Adding New Tests

### Unit Tests

1. Create a new Swift file in the appropriate directory under `/UnitTests/`
2. Name the file according to the component being tested (e.g., `TrainingSessionTests.swift`)
3. Import Testing and the Train module:
   ```swift
   import Testing
   @testable import Train
   ```
4. Create a test suite struct with the `@Suite` annotation
5. Add test methods with the `@Test` annotation

Example:
```swift
@Suite("Training Session Tests")
struct TrainingSessionTests {
    @Test("Start time is set when session starts")
    func testStartSessionSetsStartTime() {
        // Given
        let session = TrainingSession()
        
        // When
        session.start()
        
        // Then
        #expect(session.startTime != nil)
    }
}
```

### UI Tests

1. Create a new Swift file in the appropriate directory under `/UITests/`
2. Import Testing and UIKit:
   ```swift
   import Testing
   import UIKit
   ```
3. Create a test suite struct with the `@Suite` annotation
4. Add test methods that verify UI behavior using `UITestSession`

Example:
```swift
@Suite("Exercise Flow UI Tests")
struct ExerciseFlowUITests {
    @Test("Adding new set increases set count")
    func testAddSetIncreasesSetCount() async throws {
        // Launch the app
        let app = try await UITestSession.launch(named: "Train")
        
        // Navigation and test steps
        try await app.find(.button, named: "AddSetButton").tap()
        
        // Assertions
        try await app.assert(.element, labeled: "SetCount: 2", exists: true)
    }
}
```

## Accessibility Identifiers

For UI testing, ensure that key UI elements have accessibility identifiers:

```swift
button
    .accessibilityIdentifier("AddSetButton")
```

## Running Tests

1. Open the project in Xcode
2. Select the Train.xctestplan from the scheme selector
3. Use Cmd+U to run all tests
4. View test results in the test navigator

## Swift Testing vs. XCTest

The Swift Testing framework (introduced in Xcode 16) provides several advantages over XCTest:

1. **Macro-based assertions** (`#expect`) rather than method calls
2. **Structured annotations** with `@Suite` and `@Test` instead of inheritance
3. **Stateless test suites** using structs instead of classes
4. **Improved async testing** with built-in async/await support
5. **Better UI testing** with UITestSession

## Code Coverage

Code coverage is enabled in the test plan. After running tests, view the coverage report in Xcode's Report Navigator to identify areas that need additional testing.

## Continuous Integration

This testing architecture is designed to work with Xcode Cloud. The test plan is configured to:
- Run tests in parallel where possible
- Block builds if tests fail
- Generate code coverage reports
