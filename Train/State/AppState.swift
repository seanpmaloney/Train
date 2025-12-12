import Foundation
import Combine
import SwiftUI
import FirebaseFirestore

// Add MainActor to the entire class since this is primarily UI state
@MainActor
class AppState: ObservableObject {
    @Published var currentPlan: TrainingPlanEntity?
    @Published var pastPlans: [TrainingPlanEntity] = []
    @Published var scheduledWorkouts: [WorkoutEntity] = []
    @Published var activeWorkout: WorkoutEntity?
    @Published var activeWorkoutId: UUID?
    @Published var isLoaded: Bool = false
    @Published var shouldShowPlanComplete: Bool = false
    @Published var completedPlanStats: PlanCompletionStats?
    
    // User account related properties
    @Published var currentUser: UserEntity? = nil // Current authenticated user
    @Published var requiresAuthentication: Bool = false // Set to true when features require authentication
    @Published var syncEnabled: Bool = false // Whether to sync data with Firebase
    
    private let saveQueue = DispatchQueue(label: "com.train.saveQueue", qos: .background)
    
    // Use a property for the filename to allow customization in tests
    private var fileName = "plans.json"
    
    // MARK: - Test Support (Debug Only)
    
    #if DEBUG
    // These properties and methods will only be compiled in debug builds
    // They provide hooks for testing to avoid touching real data
    
    /// Set a custom filename for testing
    @MainActor
    func setCustomFileName(_ name: String) {
        fileName = name
    }
    
    /// Enable test mode with a custom file name
    @MainActor
    func enableTestMode(withFileName name: String) {
        setCustomFileName(name)
    }
    
    @MainActor
    func setLoaded(val: Bool) {
        isLoaded = val
    }
    #endif
    
    // Wrapper struct for Codable serialization
    fileprivate struct SavedPlans: Codable {
        let currentPlan: TrainingPlanEntity?
        let pastPlans: [TrainingPlanEntity]
        let scheduledWorkouts: [WorkoutEntity]
        let activeWorkout: WorkoutEntity?
        let requiresAuthentication: Bool
        let syncEnabled: Bool
        let currentUser: UserEntity?
    }
    
    // MARK: File I/O operations marked as nonisolated
    
    // Mark file operations as nonisolated so they can be called from background contexts
    nonisolated func savePlans() {
        // Capture the state on the main thread first
        Task { @MainActor in
            // Create saved plans wrapper
            let savedPlans = SavedPlans(
                currentPlan: self.currentPlan,
                pastPlans: self.pastPlans,
                scheduledWorkouts: self.scheduledWorkouts,
                activeWorkout: self.activeWorkout,
                requiresAuthentication: self.requiresAuthentication,
                syncEnabled: self.syncEnabled,
                currentUser: self.currentUser
            )
            
            // Now perform the file operations in the background
            self._savePlansInBackground(savedPlans: savedPlans)
        }
    }
    
    // Background file operation - no UI access
    private func _savePlansInBackground(savedPlans: SavedPlans) {
        // Capture fileName before using it in the background context
        let fileNameCopy = self.fileName
        
        // Use dispatch queue for background work
        DispatchQueue.global(qos: .background).async {
            do {
                // Encode to JSON
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                
                // Register feedback subclasses for polymorphic JSON encoding (no longer needed here, handled in plans)
                let data = try encoder.encode(savedPlans)
                
                // Get documents directory URL
                guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    print("Error: Could not access documents directory")
                    return
                }
                
                // Use the captured fileName copy instead of accessing self.fileName
                let fileURL = url.appendingPathComponent(fileNameCopy)
                
                // Write directly with atomic option - iOS handles the temp file internally
                try data.write(to: fileURL, options: .atomic)
                
                print("Successfully saved plans to \(fileURL.path)")
            } catch {
                print("Error saving plans: \(error.localizedDescription)")
            }
        }
    }
    
    // Mark loading operation as nonisolated
    func loadPlans() {
        // Capture fileName before using it in a non-isolated context
        let fileNameCopy = self.fileName
        
        Task {
            await self._loadPlansAndUpdateUI(fileName: fileNameCopy)
        }
    }
    
    // Private method that loads plans and updates UI
    private nonisolated func _loadPlansAndUpdateUI(fileName: String) async {
        // Check if file exists
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) else {
            await MainActor.run {
                print("Could not find document directory")
                self.isLoaded = true // Still mark as loaded even if no plans exist
            }
            return
        }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            await MainActor.run {
                print("No saved plans file exists at \(url.path)")
                self.isLoaded = true // Still mark as loaded for first launch
            }
            return
        }
        
        do {
            // Read and decode data in background
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let savedPlans = try decoder.decode(SavedPlans.self, from: data)
            
            // Update app state on main thread
            await MainActor.run {
                self.currentPlan = savedPlans.currentPlan
                self.pastPlans = savedPlans.pastPlans
                self.scheduledWorkouts = savedPlans.scheduledWorkouts
                self.activeWorkout = savedPlans.activeWorkout
                self.requiresAuthentication = savedPlans.requiresAuthentication
                self.syncEnabled = savedPlans.syncEnabled
                self.currentUser = savedPlans.currentUser
                self.isLoaded = true
                print("Successfully loaded \(savedPlans.pastPlans.count) past plans")
                if let user = savedPlans.currentUser {
                    print("Loaded user: \(user.displayName ?? user.id)")
                }
            }
        } catch let DecodingError.keyNotFound(key, context) {
            await MainActor.run {
                print("Decoding error: Missing key '\(key.stringValue)' – \(context.debugDescription)")
                self.isLoaded = true // Mark as loaded even on error
            }
        } catch let DecodingError.typeMismatch(type, context) {
            await MainActor.run {
                print("Decoding error: Type mismatch for type \(type) – \(context.debugDescription)")
                self.isLoaded = true
            }
        } catch let DecodingError.valueNotFound(value, context) {
            await MainActor.run {
                print("Decoding error: Missing value of type \(value) – \(context.debugDescription)")
                self.isLoaded = true
            }
        } catch let DecodingError.dataCorrupted(context) {
            await MainActor.run {
                print("Decoding error: Data corrupted – \(context.debugDescription)")
                self.isLoaded = true
            }
        } catch {
            await MainActor.run {
                print("Unknown error loading plans: \(error.localizedDescription)")
                self.isLoaded = true
            }
        }
    }
    
    init() {
        loadPlans()
    }
    
    // MARK: - User Account Management
    
    /// Updates the user profile in AppState and persists the changes
    /// - Parameter user: The user to update, or nil to clear the current user
    @MainActor
    func updateUser(_ user: UserEntity?) {
        // Update the user in app state
        self.currentUser = user
        
        if let user = user {
            print("Updated user in AppState: \(user.displayName ?? user.id)")
        } else {
            print("Cleared user in AppState")
        }
        
        // Save changes to persist the updated user
        savePlans()
    }
    
    /// Finalizes the onboarding process by saving the generated plan and updating user data
    /// This method requires a username to be already set in the user entity
    @MainActor
    func finalizeOnboarding(user: UserEntity, plan: TrainingPlanEntity?, marketingOptIn: Bool, userSessionManager: UserSessionManager) async throws {
        print("Starting finalizeOnboarding for user: \(user.displayName ?? user.id)")
        
        // Store the marketing preference in UserDefaults for easy access
        UserDefaults.standard.set(marketingOptIn, forKey: "marketingOptIn")
        
        // Update the user profile with marketing preference
        var updatedUser = user
        updatedUser.marketingOptIn = marketingOptIn
        
        // Save the user in AppState
        self.currentUser = updatedUser
        print("✅ Set AppState.currentUser to: \(updatedUser.displayName ?? updatedUser.id)")
        
        // Save the changes to disk immediately to ensure persistence
        savePlans()
        
        // Now that we have all user data including username, save directly to Firebase
        do {
            try await FirestoreService.shared.saveUser(updatedUser)
            print("✅ Complete user data saved to Firestore: \(updatedUser.id)")
        } catch {
            print("⚠️ Error saving user to Firestore: \(error.localizedDescription)")
            // Re-throw the error to allow proper handling by the caller
            throw error
        }
        
        // Update the user profile via the user session manager and set authentication state
        print("Signing in user in UserSessionManager: \(updatedUser.id), displayName: \(updatedUser.displayName ?? "none")")
        
        // Use signInWithUser to properly set auth state
        userSessionManager.signInWithUser(updatedUser, appState: self)
        
        // Verify the user was properly updated in the session manager
        if let currentUser = userSessionManager.currentUser {
            print("✅ UserSessionManager currentUser updated successfully: \(currentUser.id), displayName: \(currentUser.displayName ?? "none")")
        } else {
            print("⚠️ UserSessionManager currentUser is still nil after update!")
        }
        
        // Verify authentication state
        print("UserSessionManager authState: \(userSessionManager.authState)")
        
        print("Onboarding completed for user ID: \(user.id), username: \(user.username ?? "none"), marketing opt-in: \(marketingOptIn)")
        
        // Set the generated plan if available
        if let plan = plan {
            self.setCurrentPlan(plan)
            self.savePlans()
            print("Set current training plan: \(plan.name)")
        }
        
        // Mark app as requiring authentication if needed
        self.setRequiresAuthentication(true)
        print("App now requires authentication")
    }
    
    /// Get all plans (current and past)
    func getAllPlans() -> [TrainingPlanEntity] {
        var allPlans = pastPlans
        if let currentPlan = currentPlan {
            allPlans.append(currentPlan)
        }
        return allPlans
    }
    
    /// Update a plan with new data (for syncing)
    func updatePlan(_ updatedPlan: TrainingPlanEntity) {
        if let currentPlan = currentPlan, currentPlan.id == updatedPlan.id {
            self.currentPlan = updatedPlan
        } else if let index = pastPlans.firstIndex(where: { $0.id == updatedPlan.id }) {
            pastPlans[index] = updatedPlan
        } else {
            // New plan, add it
            addPlan(updatedPlan)
        }
        
        savePlans()
    }
    
    /// Clear all data (for account deletion)
    func clearAllData() {
        currentPlan = nil
        pastPlans = []
        scheduledWorkouts = []
        activeWorkout = nil
        activeWorkoutId = nil
        
        savePlans()
    }
    
    /// Enable or disable authentication requirement
    func setRequiresAuthentication(_ requires: Bool) {
        requiresAuthentication = requires
        savePlans()
    }
    
    /// Enable or disable data syncing
    func setSyncEnabled(_ enabled: Bool) {
        syncEnabled = enabled
        savePlans()
    }
    
    // MARK: - Calendar Management
    
    private func sortWorkouts() {
        scheduledWorkouts.sort { w1, w2 in
            switch (w1.scheduledDate, w2.scheduledDate) {
            case (nil, nil): return false
            case (nil, _): return false
            case (_, nil): return true
            case (let date1?, let date2?): return date1 < date2
            }
        }
    }
    
    func scheduleWorkout(_ workout: WorkoutEntity) {
        // Add workout to scheduled workouts list if not already present
        if !scheduledWorkouts.contains(where: { $0.id == workout.id }) {
            scheduledWorkouts.append(workout)
            sortWorkouts()
        }
    }
    
    func scheduleWorkouts(_ workouts: [WorkoutEntity]) {
        var didChange = false
        for workout in workouts {
            if !scheduledWorkouts.contains(where: { $0.id == workout.id }) {
                scheduledWorkouts.append(workout)
                didChange = true
            }
        }
        
        if didChange {
            sortWorkouts()
            savePlans()
        }
    }
    
    func unscheduleWorkout(_ workout: WorkoutEntity) {
        if let index = scheduledWorkouts.firstIndex(where: { $0.id == workout.id }) {
            scheduledWorkouts.remove(at: index)
            savePlans()
        }
    }
    
    func unscheduleWorkoutsForPlan(_ plan: TrainingPlanEntity) {
        let initialCount = scheduledWorkouts.count
        scheduledWorkouts.removeAll { workout in
            plan.weeklyWorkouts.flatMap {$0}.contains { $0.id == workout.id }
        }
        
        if scheduledWorkouts.count != initialCount {
            savePlans()
        }
    }
    
    func updateWorkoutDate(_ workout: WorkoutEntity, to date: Date?) {
        if let index = scheduledWorkouts.firstIndex(where: { $0.id == workout.id }) {
            scheduledWorkouts[index].scheduledDate = date
            sortWorkouts()
            savePlans()
        }
    }
    
    @MainActor
    public func markWorkoutComplete(_ workout: WorkoutEntity, isComplete: Bool) {
        // Update scheduled workout if present
        if let index = scheduledWorkouts.firstIndex(where: { $0.id == workout.id }) {
            scheduledWorkouts[index].isComplete = isComplete
        }

        // Also update workout inside the current plan's weeklyWorkouts if applicable
        if let plan = getPlanForWorkout(workout) {
            for weekIndex in 0..<plan.weeklyWorkouts.count {
                if let workoutIndex = plan.weeklyWorkouts[weekIndex].firstIndex(where: { $0.id == workout.id }) {
                    plan.weeklyWorkouts[weekIndex][workoutIndex].isComplete = isComplete
                }
            }
        }

        savePlans()
    }
    
    func getWorkouts(for date: Date) -> [WorkoutEntity] {
        let calendar = Calendar.current
        return scheduledWorkouts.filter { workout in
            guard let workoutDate = workout.scheduledDate else { return false }
            return calendar.isDate(workoutDate, inSameDayAs: date)
        }
    }
    
    func getWorkouts(from startDate: Date, to endDate: Date) -> [WorkoutEntity] {
        return scheduledWorkouts.filter { workout in
            guard let workoutDate = workout.scheduledDate else { return false }
            return (startDate...endDate).contains(workoutDate)
        }
    }
    
    func setCurrentPlan(_ plan: TrainingPlanEntity) {
        // Move current plan to past plans if it exists
        if let current = currentPlan {
            pastPlans.insert(current, at: 0)
        }
        
        // Set new current plan
        currentPlan = plan
        
        // Save to persistent storage
        savePlans()
    }
    
    /// A centralized method to finalize a plan - either a new one or an existing one
    /// - Parameters:
    ///   - plan: The plan to finalize (can be new or existing)
    ///   - workouts: Array of workouts to add to the plan
    ///   - clear: Whether to clear existing workouts (for editing existing plans)
    ///   - setAsCurrent: Whether to set as the current plan
    func finalizePlan(
        _ plan: TrainingPlanEntity,
        workouts: [[WorkoutEntity]] = [],
        clear: Bool = false,
        setAsCurrent: Bool = true
    ) {
        // Clear existing workouts if requested (for edited plans)
        if clear {
            plan.weeklyWorkouts.removeAll()
        }
        
        // Add all workouts to the plan if provided
        for week in workouts {
            // Add to plan
            plan.weeklyWorkouts.append(week)
            for workout in week {
                // Set parent reference
                workout.trainingPlan = plan
                
                // Schedule workout
                scheduleWorkout(workout)
            }
        }
        
        // Update plan's end date based on last workout
        plan.endDate = plan.calculatedEndDate
        
        // Set as current plan if requested
        if setAsCurrent {
            setCurrentPlan(plan)
        } else {
            // Just save the changes without setting as current
            savePlans()
        }
    }
    
    func archiveCurrentPlan() {
        guard let plan = currentPlan else { return }
        archiveSpecificPlan(plan)
        currentPlan = nil
    }
    
    private func archiveSpecificPlan(_ plan: TrainingPlanEntity) {
        // Set completion date and mark as completed
        plan.endDate = Date()
        plan.isCompleted = true
        
        // Move to past plans if not already there
        if !pastPlans.contains(where: { $0.id == plan.id }) {
            pastPlans.append(plan)
        }
        
        // Save changes
        savePlans()
    }
    
    func deletePastPlan(_ plan: TrainingPlanEntity) {
        unscheduleWorkoutsForPlan(plan)
        pastPlans.removeAll { $0.id == plan.id }
        savePlans()
    }
    
    func isPlanCurrent(_ plan: TrainingPlanEntity) -> Bool {
        currentPlan?.id == plan.id
    }
    
    /// Finds a plan by its ID in either current or past plans
    func findPlan(with id: UUID) -> TrainingPlanEntity? {
        if let currentPlan = currentPlan, currentPlan.id == id {
            return currentPlan
        }
        return pastPlans.first { $0.id == id }
    }
    
    // Creates a SavedPlans struct capturing the current state for serialization
    @MainActor
    private func createSavedPlansSnapshot() -> SavedPlans {
        let savedPlans = SavedPlans(
            currentPlan: self.currentPlan,
            pastPlans: self.pastPlans,
            scheduledWorkouts: self.scheduledWorkouts,
            activeWorkout: self.activeWorkout,
            requiresAuthentication: false,
            syncEnabled: false,
            currentUser: self.currentUser
        )
        return savedPlans
    }
    
    @MainActor
    public func setActiveWorkout(_ workout: WorkoutEntity) {
        self.activeWorkout = workout
        self.activeWorkoutId = workout.id
    }
    
    @MainActor
    public func getActiveWorkout() -> WorkoutEntity {
        guard let activeWorkout = self.activeWorkout else {
            fatalError("Active workout is not set")
        }
        return activeWorkout
    }
    
    @MainActor
    public func getNextWorkout() -> WorkoutEntity {
        // Return the first incomplete workout, or the first workout if all are complete
        guard !scheduledWorkouts.isEmpty else {
            fatalError("No scheduled workouts available")
        }
        let index = scheduledWorkouts.firstIndex(where: { !$0.isComplete }) ?? 0
        return scheduledWorkouts[index]
    }
    
    // MARK: - Helper Methods
    
    nonisolated func getDocumentsURL() -> URL? {
        return self.getFileManager().urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    nonisolated func getFileManager() -> FileManager {
        return FileManager.default
    }
    
    @MainActor
    func addPlan(_ plan: TrainingPlanEntity) {
        // Set as current plan if there is no current plan
        if currentPlan == nil {
            currentPlan = plan
        } else {
            // Otherwise add to past plans
            pastPlans.append(plan)
        }
        
        // Save changes
        savePlans()
    }
    
    // MARK: - Workout Feedback Management
    
    /// Record pre-workout feedback before starting a workout
    func recordPreWorkoutFeedback(for workout: WorkoutEntity, soreMuscles: [MuscleGroup], jointPainAreas: [JointArea]) {
        // Create feedback
        let feedback = PreWorkoutFeedback(workoutId: workout.id, soreMuscles: soreMuscles, jointPainAreas: jointPainAreas)
        
        // Attach feedback directly to the workout
        workout.preWorkoutFeedback = feedback
        
        // For backward compatibility, also add to plan's feedback collection if available
        if let plan = getPlanForWorkout(workout) {
            plan.addFeedback(feedback)
        }
        
        savePlans()
    }
    
    /// Records feedback for a specific exercise
    func recordExerciseFeedback(for exercise: ExerciseInstanceEntity, in workout: WorkoutEntity, intensity: ExerciseIntensity, setVolume: SetVolumeRating) {
        // Create feedback
        let feedback = ExerciseFeedback(exerciseId: exercise.id, workoutId: workout.id, intensity: intensity, setVolume: setVolume)
        
        // Attach feedback directly to the exercise
        exercise.feedback = feedback
        
        // For backward compatibility, also add to plan's feedback collection if available
        if let plan = getPlanForWorkout(workout) {
            plan.addFeedback(feedback)
        }
        
        savePlans()
    }
    
    /// Records post-workout feedback
    func recordPostWorkoutFeedback(for workout: WorkoutEntity, fatigue: FatigueLevel) {
        // Create feedback
        let feedback = PostWorkoutFeedback(workoutId: workout.id, sessionFatigue: fatigue)
        
        // Attach feedback directly to the workout
        workout.postWorkoutFeedback = feedback
        
        // For backward compatibility, also add to plan's feedback collection if available
        if let plan = getPlanForWorkout(workout) {
            plan.addFeedback(feedback)
        }
        
        savePlans()
    }
    
    /// Helper to get the plan that contains a workout
    private func getPlanForWorkout(_ workout: WorkoutEntity) -> TrainingPlanEntity? {
        if let plan = workout.trainingPlan {
            return plan
        }
        
        // If workout.trainingPlan is nil, try to find the plan
        if let plan = currentPlan, planContainsWorkout(plan, workout) {
            return plan
        }
        
        for plan in pastPlans {
            if planContainsWorkout(plan, workout) {
                return plan
            }
        }
        
        return nil
    }
    
    /// Helper to check if a plan contains a workout
    private func planContainsWorkout(_ plan: TrainingPlanEntity, _ workout: WorkoutEntity) -> Bool {
        return plan.weeklyWorkouts.flatMap { $0 }.contains { $0.id == workout.id }
    }
    
    /// Get all feedback for a specific workout, prioritizing direct feedback on entities
    func getFeedback(for workoutId: UUID) -> (pre: PreWorkoutFeedback?, exercises: [ExerciseFeedback], post: PostWorkoutFeedback?) {
        // First try to find the workout directly in scheduled workouts or active workout
        let workout = findWorkout(with: workoutId)
        
        if let workout = workout {
            // Get exercise feedback directly from the workout's exercises
            let exerciseFeedbacks = workout.exercises.compactMap { $0.feedback }
            
            // Return feedback directly from the workout entity if available
            return (pre: workout.preWorkoutFeedback,
                    exercises: exerciseFeedbacks,
                    post: workout.postWorkoutFeedback)
        }
        
        // Fallback to plan-based feedback for backward compatibility
        
        // Try current plan first
        if let plan = currentPlan {
            let feedback = plan.getFeedback(for: workoutId)
            if feedback.pre != nil || !feedback.exercises.isEmpty || feedback.post != nil {
                return feedback
            }
        }
        
        // Try past plans if not found
        for plan in pastPlans {
            let feedback = plan.getFeedback(for: workoutId)
            if feedback.pre != nil || !feedback.exercises.isEmpty || feedback.post != nil {
                return feedback
            }
        }
        
        // Return empty result if not found
        return (pre: nil, exercises: [], post: nil)
    }
    
    /// Helper to find a workout by ID across all possible locations
    private func findWorkout(with workoutId: UUID) -> WorkoutEntity? {
        // Check active workout
        if let activeWorkout = activeWorkout, activeWorkout.id == workoutId {
            return activeWorkout
        }
        
        // Check scheduled workouts
        if let workout = scheduledWorkouts.first(where: { $0.id == workoutId }) {
            return workout
        }
        
        // Check workouts in current plan
        if let plan = currentPlan {
            let allWorkouts = plan.weeklyWorkouts.flatMap { $0 }
            if let workout = allWorkouts.first(where: { $0.id == workoutId }) {
                return workout
            }
        }
        
        // Check workouts in past plans
        for plan in pastPlans {
            let allWorkouts = plan.weeklyWorkouts.flatMap { $0 }
            if let workout = allWorkouts.first(where: { $0.id == workoutId }) {
                return workout
            }
        }
        
        return nil
    }
    
    /// Get the most recent feedback for a specific muscle from any plan
    func getMostRecentFeedbackForMuscle(_ muscle: MuscleGroup) -> PreWorkoutFeedback? {
        var allFeedback: [PreWorkoutFeedback] = []
        
        // Collect from current plan
        if let plan = currentPlan, let feedback = plan.getMostRecentFeedbackForMuscle(muscle) {
            allFeedback.append(feedback)
        }
        
        // Collect from past plans
        for plan in pastPlans {
            if let feedback = plan.getMostRecentFeedbackForMuscle(muscle) {
                allFeedback.append(feedback)
            }
        }
        
        // Return the most recent one
        return allFeedback.sorted { $0.date > $1.date }.first
    }
    
    /// Ends the current workout, records feedback, and checks for weekly progression
    func endWorkout(with fatigue: FatigueLevel) {
        guard let activeWorkout = self.activeWorkout else {
            return
        }
        
        // 1. Record post-workout feedback
        recordPostWorkoutFeedback(for: activeWorkout, fatigue: fatigue)
        
        // 2. Mark workout as complete
        markWorkoutComplete(activeWorkout, isComplete: true)
        
        // 3. Check if this completes the entire plan
        let isPlanComplete = checkIfPlanIsComplete(justCompletedWorkout: activeWorkout)
        
        // 4. Check if we need to apply weekly progression (only if plan isn't complete)
        if !isPlanComplete {
            applyWeeklyProgressionIfNeeded(justCompletedWorkout: activeWorkout)
        }
        
        // 5. Clear active workout
        self.activeWorkout = nil
        self.activeWorkoutId = nil
        
        // 6. Save changes
        savePlans()
        
        // 7. Trigger plan completion flow if needed
        if isPlanComplete {
            shouldShowPlanComplete = true
        }
    }
    
    // MARK: - Plan Complete Detection
    
    func isLastWorkoutInPlan(_ workout: WorkoutEntity) -> Bool {
        guard let plan = currentPlan else { return false }
        
        // Get all workouts in the plan
        let allWorkouts = plan.weeklyWorkouts.flatMap { $0 }
        
        // Find the workout in the plan
        guard let workoutIndex = allWorkouts.firstIndex(where: { $0.id == workout.id }) else {
            return false
        }
        
        // Check if this is the last workout
        return workoutIndex == allWorkouts.count - 1
    }
    
    /// Find an exercise entity by ID from any workout
    func getExerciseById(_ id: UUID) -> ExerciseInstanceEntity? {
        for workout in scheduledWorkouts {
            if let exercise = workout.exercises.first(where: { $0.id == id }) {
                return exercise
            }
        }
        return nil
    }
    
    // MARK: - Weekly Progression
    
    /// Applies weekly progression if there's a completed week that needs progression
    func applyWeeklyProgressionIfNeeded(justCompletedWorkout: WorkoutEntity? = nil) {
        guard let plan = currentPlan else { return }
        
        // Find the most recently completed week
        guard let completedWeekIndex = getLastCompletedWeekIndex(for: plan),
              // Make sure there's a next week to progress to
              completedWeekIndex + 1 < plan.weeklyWorkouts.count else { return }
        // Get workouts for completed and next week
        let completedWeekWorkouts = plan.weeklyWorkouts[completedWeekIndex]
        
        // Check if the just completed workout belongs to the completed week
        if let justCompletedWorkout = justCompletedWorkout,
           !completedWeekWorkouts.contains(where: { $0.id == justCompletedWorkout.id }) {
            // Return early if the completed workout is not part of the completed week
            return
        }

        let nextWeekWorkouts = plan.weeklyWorkouts[completedWeekIndex + 1]
        
        // Collect feedback for all workouts in the completed week
        var feedbackMap = [UUID: [WorkoutFeedback]]()
        for workout in completedWeekWorkouts {
            let feedback = plan.getFeedback(for: workout.id)
            var allFeedback: [WorkoutFeedback] = []
            
            if let preFeedback = feedback.pre {
                allFeedback.append(preFeedback)
            }
            allFeedback.append(contentsOf: feedback.exercises)
            if let postFeedback = feedback.post {
                allFeedback.append(postFeedback)
            }
            
            if !allFeedback.isEmpty {
                feedbackMap[workout.id] = allFeedback
            }
        }
        
        // Create arrays for progression engine
        var weeklyWorkouts = [completedWeekWorkouts, nextWeekWorkouts]
        
        // Apply progression
        let logs = ProgressionEngine.applyProgression(
            to: &weeklyWorkouts,
            debug: true
        )
        
        // Log progression results
        for log in logs {
            print("PROGRESSION: \(log)")
        }
        
        // Update the plan with the progressed workouts
        plan.weeklyWorkouts[completedWeekIndex + 1] = weeklyWorkouts[1]
        
        // Save changes
        savePlans()
        
        // Explicitly mark the plan as changed to notify subscribers
        // This line is needed to refresh the EnhancedTrainingView
        objectWillChange.send()
    }
    
    /// Determine if a week is complete (all workouts completed)
    private func isWeekComplete(weekIndex: Int, in plan: TrainingPlanEntity) -> Bool {
        guard weekIndex < plan.weeklyWorkouts.count else { return false }
        
        let weekWorkouts = plan.weeklyWorkouts[weekIndex]
        return !weekWorkouts.isEmpty && weekWorkouts.allSatisfy { $0.isComplete }
    }
    
    /// Returns the index of the first week that has any incomplete workouts
    /// Used for determining where the user is currently training
    private func getFirstIncompleteWeekIndex(for plan: TrainingPlanEntity) -> Int? {
        for (index, week) in plan.weeklyWorkouts.enumerated() {
            if week.contains(where: { !$0.isComplete }) {
                return index
            }
        }

        // If all weeks are complete, return the last one
        return plan.weeklyWorkouts.indices.last
    }
    
    /// Returns the index of the most recent week where all workouts are complete
    /// Used for progression logic to ensure the right week is progressed
    private func getLastCompletedWeekIndex(for plan: TrainingPlanEntity) -> Int? {
        // Scan the plan in reverse to find the most recent completed week
        for index in (0..<plan.weeklyWorkouts.count).reversed() {
            let week = plan.weeklyWorkouts[index]
            
            // Skip empty weeks
            if week.isEmpty {
                continue
            }
            
            // Check if all workouts in this week are complete
            if week.allSatisfy({ $0.isComplete }) {
                return index
            }
        }
        
        // No complete weeks found
        return nil
    }
    
    // MARK: - Plan Completion Detection
    
    /// Checks if the plan is complete after the given workout is finished
    /// - Parameter justCompletedWorkout: The workout that was just completed
    /// - Returns: True if this workout completion finishes the entire plan
    private func checkIfPlanIsComplete(justCompletedWorkout: WorkoutEntity) -> Bool {
        guard let plan = currentPlan else { 
            print("DEBUG: No current plan, cannot check completion")
            return false 
        }
        
        // Find the last scheduled workout in the plan
        let allWorkouts = plan.weeklyWorkouts.flatMap { $0 }
        guard !allWorkouts.isEmpty else { 
            print("DEBUG: No workouts in plan")
            return false 
        }
        
        // Sort by scheduled date, with fallback to creation order
        let sortedWorkouts = allWorkouts.sorted { workout1, workout2 in
            let date1 = workout1.scheduledDate ?? Date.distantPast
            let date2 = workout2.scheduledDate ?? Date.distantPast
            return date1 < date2
        }
        
        guard let lastWorkout = sortedWorkouts.last else { 
            print("DEBUG: Could not determine last workout")
            return false 
        }
        
        // Check if the just completed workout is the last scheduled workout
        let isLastWorkout = justCompletedWorkout.id == lastWorkout.id
        
        print("DEBUG: Checking plan completion - Last workout: \(lastWorkout.title), Just completed: \(justCompletedWorkout.title), Is last: \(isLastWorkout)")
        
        if isLastWorkout {
            print("DEBUG: Plan is complete! Calculating stats...")
            // Calculate and store stats for the completed plan
            completedPlanStats = PlanStatsCalculator.calculateStats(for: plan)
            return true
        }
        
        return false
    }
    
    // MARK: - Plan Continuation Logic
    
    /// Creates a new plan that continues from the completed plan
    /// - Parameters:
    ///   - completedPlan: The plan that was just completed
    ///   - startDate: Start date for the new plan
    ///   - includeDeload: Whether to include a deload week at the beginning
    /// - Returns: The new training plan
    func createContinuationPlan(from completedPlan: TrainingPlanEntity, startDate: Date, includeDeload: Bool = false) -> TrainingPlanEntity {
        // Create new plan with similar structure
        let newPlan = TrainingPlanEntity(
            name: "\(completedPlan.name) - Cycle 2",
            notes: "Continuation of \(completedPlan.name)",
            startDate: startDate,
            daysPerWeek: completedPlan.daysPerWeek,
            isCompleted: false
        )
        
        // Copy muscle preferences and training goal
        newPlan.musclePreferences = completedPlan.musclePreferences
        newPlan.trainingGoal = completedPlan.trainingGoal
        
        // Clone the weekly structure
        newPlan.weeklyWorkouts = cloneWeeklyWorkouts(from: completedPlan)
        
        // Apply weight adjustments
        let weeksCount = completedPlan.weeklyWorkouts.count
        applyWeightAdjustments(to: newPlan, basedOn: completedPlan, weeksCount: weeksCount, includeDeload: includeDeload)
        
        // Schedule the workouts with dates
        scheduleWorkoutsWithDates(for: newPlan, startingFrom: startDate)
        
        return newPlan
    }
    
    /// Clones the weekly workout structure from a completed plan
    private func cloneWeeklyWorkouts(from plan: TrainingPlanEntity) -> [[WorkoutEntity]] {
        return plan.weeklyWorkouts.map { week in
            week.map { workout in
                let newWorkout = workout.copy()
                newWorkout.isComplete = false
                newWorkout.preWorkoutFeedback = nil
                newWorkout.postWorkoutFeedback = nil
                
                // Reset exercise feedback and set completion
                for exercise in newWorkout.exercises {
                    exercise.feedback = nil
                    for set in exercise.sets {
                        set.isComplete = false
                    }
                }
                
                return newWorkout
            }
        }
    }
    
    /// Applies weight adjustments to the new plan based on the completed plan
    private func applyWeightAdjustments(to newPlan: TrainingPlanEntity, basedOn completedPlan: TrainingPlanEntity, weeksCount: Int, includeDeload: Bool) {
        // Determine multipliers based on plan length
        let backoffMultiplier = weeksCount <= 4 ? 
            WeightUtilities.PlanContinuation.shortPlanBackoffMultiplier : 
            WeightUtilities.PlanContinuation.longPlanBackoffMultiplier
        
        // Get last week's weights from completed plan
        let lastWeekWeights = getLastWeekWeights(from: completedPlan)
        
        for (weekIndex, week) in newPlan.weeklyWorkouts.enumerated() {
            for workout in week {
                for exercise in workout.exercises {
                    let movementId = exercise.movement.id
                    
                    if let lastWeight = lastWeekWeights[movementId], lastWeight > 0 {
                        let newWeight: Double
                        
                        if includeDeload && weekIndex == 0 {
                            // First week is deload
                            newWeight = lastWeight * WeightUtilities.PlanContinuation.deloadMultiplier
                        } else if includeDeload && weekIndex == 1 {
                            // Second week starts the new progression
                            newWeight = lastWeight * backoffMultiplier
                        } else if !includeDeload && weekIndex == 0 {
                            // First week starts the new progression
                            newWeight = lastWeight * backoffMultiplier
                        } else {
                            // Keep the same weight for later weeks (progression will handle increases)
                            continue
                        }
                        
                        let roundedWeight = WeightUtilities.closestWeightIn2pt5Increment(newWeight)
                        
                        // Apply to all working sets in this exercise
                        for set in exercise.sets {
                            set.weight = roundedWeight
                        }
                    }
                }
            }
        }
    }
    
    /// Gets the heaviest working weights from the last week of a completed plan
    private func getLastWeekWeights(from plan: TrainingPlanEntity) -> [UUID: Double] {
        guard let lastWeekIndex = plan.weeklyWorkouts.indices.last else { return [:] }
        
        let lastWeek = plan.weeklyWorkouts[lastWeekIndex]
        var weights: [UUID: Double] = [:]
        
        for workout in lastWeek where workout.isComplete {
            for exercise in workout.exercises {
                let movementId = exercise.movement.id
                let heaviestWeight = exercise.sets
                    .filter { $0.isComplete }
                    .map { $0.weight }
                    .max() ?? 0.0
                
                if heaviestWeight > 0 {
                    weights[movementId] = max(weights[movementId] ?? 0, heaviestWeight)
                }
            }
        }
        
        return weights
    }
    
    /// Dismisses the plan complete screen and handles the selected action
    func dismissPlanComplete(action: PlanCompleteAction) {
        shouldShowPlanComplete = false
        
        // Store reference to completed plan before any changes
        let completedPlan = currentPlan
        
        switch action {
        case .continuePlan(let startDate):
            handleContinuePlan(startDate: startDate, includeDeload: false)
        case .continueWithDeload(let startDate):
            handleContinuePlan(startDate: startDate, includeDeload: true)
        case .chooseNewPlan:
            // Navigation will be handled by the UI
            break
        case .maybeLater:
            // Just archive the plan, no new plan created
            break
        }
        
        // Archive the completed plan (not the new one)
        if let planToArchive = completedPlan {
            archiveSpecificPlan(planToArchive)
        }
        completedPlanStats = nil
    }
    
    private func handleContinuePlan(startDate: Date, includeDeload: Bool) {
        guard let completedPlan = currentPlan else { return }
        
        print("DEBUG: Creating continuation plan with deload: \(includeDeload)")
        let newPlan = createContinuationPlan(from: completedPlan, startDate: startDate, includeDeload: includeDeload)
        
        print("DEBUG: New plan created with \(newPlan.weeklyWorkouts.count) weeks")
        print("DEBUG: New plan isCompleted: \(newPlan.isCompleted)")
        
        setCurrentPlan(newPlan)
        
        print("DEBUG: Current plan set, checking if it's still current: \(currentPlan?.name ?? "nil")")
    }
    
    /// Schedules workouts for a plan with proper dates based on the original plan's pattern
    private func scheduleWorkoutsWithDates(for plan: TrainingPlanEntity, startingFrom startDate: Date) {
        let calendar = Calendar.current
        var currentDate = startDate
        
        // Get the original workout days pattern from the first week
        guard let firstWeek = plan.weeklyWorkouts.first, !firstWeek.isEmpty else { return }
        
        // Extract the weekdays from the original plan
        let originalWeekdays = firstWeek.compactMap { workout -> Int? in
            guard let scheduledDate = workout.scheduledDate else { return nil }
            return calendar.component(.weekday, from: scheduledDate)
        }.sorted()
        
        // If no original pattern, use a default pattern based on days per week
        let weekdays = originalWeekdays.isEmpty ? getDefaultWeekdays(for: plan.daysPerWeek) : originalWeekdays
        
        for (weekIndex, week) in plan.weeklyWorkouts.enumerated() {
            let weekStartDate = calendar.date(byAdding: .weekOfYear, value: weekIndex, to: startDate) ?? currentDate
            
            for (dayIndex, workout) in week.enumerated() {
                if dayIndex < weekdays.count {
                    let targetWeekday = weekdays[dayIndex]
                    let workoutDate = getDateForWeekday(targetWeekday, in: weekStartDate, using: calendar)
                    workout.scheduledDate = workoutDate
                }
            }
        }
        
        // Schedule all workouts
        let allWorkouts = plan.weeklyWorkouts.flatMap { $0 }
        scheduleWorkouts(allWorkouts)
    }
    
    /// Gets default weekdays based on training frequency
    private func getDefaultWeekdays(for daysPerWeek: Int) -> [Int] {
        switch daysPerWeek {
        case 2: return [2, 5] // Monday, Thursday
        case 3: return [2, 4, 6] // Monday, Wednesday, Friday
        case 4: return [2, 3, 5, 6] // Monday, Tuesday, Thursday, Friday
        case 5: return [2, 3, 4, 5, 6] // Monday-Friday
        case 6: return [2, 3, 4, 5, 6, 7] // Monday-Saturday
        default: return [2, 4, 6] // Default to 3 days
        }
    }
    
    /// Gets the date for a specific weekday within a given week
    private func getDateForWeekday(_ weekday: Int, in weekStartDate: Date, using calendar: Calendar) -> Date {
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: weekStartDate)?.start ?? weekStartDate
        return calendar.date(byAdding: .day, value: weekday - 1, to: weekStart) ?? weekStartDate
    }
}

/// Actions available when a plan is completed
enum PlanCompleteAction {
    case continuePlan(startDate: Date)
    case continueWithDeload(startDate: Date)
    case chooseNewPlan
    case maybeLater
}
