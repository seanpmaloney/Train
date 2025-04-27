import Foundation

// Add MainActor to the entire class since this is primarily UI state
@MainActor
class AppState: ObservableObject {
    @Published var currentPlan: TrainingPlanEntity?
    @Published var pastPlans: [TrainingPlanEntity] = []
    @Published var scheduledWorkouts: [WorkoutEntity] = []
    @Published var activeWorkout: WorkoutEntity?
    @Published var activeWorkoutId: UUID?
    @Published private(set) var isLoaded: Bool = false
    
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
                activeWorkout: self.activeWorkout
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
                let data = try encoder.encode(savedPlans)
                
                // Get documents directory URL
                guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    print("Error: Could not access documents directory")
                    return
                }
                
                // Use the captured fileName copy instead of accessing self.fileName
                let fileURL = url.appendingPathComponent(fileNameCopy)
                
                // Write atomically to temporary file first
                let tempURL = url.appendingPathComponent("\(fileNameCopy).temp")
                try data.write(to: tempURL, options: .atomic)
                
                // Remove existing file if it exists
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try FileManager.default.removeItem(at: fileURL)
                }
                
                // Rename temp file to final file
                try FileManager.default.moveItem(at: tempURL, to: fileURL)
                
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
            
            // Update UI state on main actor
            await MainActor.run {
                self.currentPlan = savedPlans.currentPlan
                self.pastPlans = savedPlans.pastPlans
                self.scheduledWorkouts = savedPlans.scheduledWorkouts
                self.activeWorkout = savedPlans.activeWorkout
                self.isLoaded = true
                print("Successfully loaded plans from \(url.path)")
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
            plan.workouts.contains { $0.id == workout.id }
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
        if let index = scheduledWorkouts.firstIndex(where: { $0.id == workout.id }) {
            scheduledWorkouts[index].isComplete = isComplete
            savePlans()
        }
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
    
    // MARK: - Plan Management
    
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
    
    func archiveCurrentPlan() {
        guard let plan = currentPlan else { return }
        
        // Set end date to now
        plan.endDate = Date()
        plan.isCompleted = true
        
        // Move to past plans
        pastPlans.append(plan)
        currentPlan = nil
        
        // Save changes
        savePlans()
    }
    
    func deletePastPlan(_ plan: TrainingPlanEntity) {
        unscheduleWorkoutsForPlan(plan)
        pastPlans.removeAll { $0.id == plan.id }
        savePlans()
    }
    
    func isPlanCurrent(_ plan: TrainingPlanEntity) -> Bool {
        return currentPlan?.id == plan.id
    }
    
    // Creates a SavedPlans struct capturing the current state for serialization
    @MainActor
    private func createSavedPlansSnapshot() -> SavedPlans {
        return SavedPlans(
            currentPlan: self.currentPlan,
            pastPlans: self.pastPlans,
            scheduledWorkouts: self.scheduledWorkouts,
            activeWorkout: self.activeWorkout
        )
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
}
