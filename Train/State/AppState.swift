import Foundation

class AppState: ObservableObject {
    @Published var currentPlan: TrainingPlanEntity?
    @Published var pastPlans: [TrainingPlanEntity] = []
    @Published var scheduledWorkouts: [WorkoutEntity] = []
    @Published var isLoaded: Bool = false
    
    private let saveQueue = DispatchQueue(label: "com.train.saveQueue", qos: .background)
    private let fileName = "plans.json"
    
    // Wrapper struct for Codable serialization
    struct SavedPlans: Codable {
        let currentPlan: TrainingPlanEntity?
        let pastPlans: [TrainingPlanEntity]
        let scheduledWorkouts: [WorkoutEntity]
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
    
    func markWorkoutComplete(_ workout: WorkoutEntity, isComplete: Bool) {
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
    
    public func savePlans() {
        saveQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Create saved plans wrapper
                let savedPlans = SavedPlans(
                    currentPlan: self.currentPlan,
                    pastPlans: self.pastPlans,
                    scheduledWorkouts: self.scheduledWorkouts
                )
                
                // Encode to JSON
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(savedPlans)
                
                // Get documents directory URL
                guard let url = self.getDocumentsURL() else {
                    print("Error: Could not access documents directory")
                    return
                }
                
                let fileURL = url.appendingPathComponent(self.fileName)
                
                // Write atomically to temporary file first
                let tempURL = url.appendingPathComponent("\(self.fileName).temp")
                try data.write(to: tempURL, options: .atomic)
                
                // Remove existing file if it exists
                if self.getFileManager().fileExists(atPath: fileURL.path) {
                    try self.getFileManager().removeItem(at: fileURL)
                }
                
                // Rename temp file to final file
                try self.getFileManager().moveItem(at: tempURL, to: fileURL)
                
                print("Successfully saved plans to \(fileURL.path)")
            } catch {
                print("Error saving plans: \(error.localizedDescription)")
            }
        }
    }
    
    public func loadPlans() {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) else {
            print("Could not find document directory")
            self.isLoaded = true // Still mark as loaded even if no plans exist
            return
        }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            print("No saved plans file exists at \(url.path)")
            self.isLoaded = true // Still mark as loaded for first launch
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            DispatchQueue.main.async {
                do {
                    let savedPlans = try decoder.decode(SavedPlans.self, from: data)
                    self.currentPlan = savedPlans.currentPlan
                    self.pastPlans = savedPlans.pastPlans
                    self.scheduledWorkouts = savedPlans.scheduledWorkouts
                    self.isLoaded = true
                    print("Successfully loaded plans from \(url.path)")
                } catch let DecodingError.keyNotFound(key, context) {
                    print("Decoding error: Missing key '\(key.stringValue)' – \(context.debugDescription)")
                    self.isLoaded = true // Mark as loaded even on error
                } catch let DecodingError.typeMismatch(type, context) {
                    print("Decoding error: Type mismatch for type \(type) – \(context.debugDescription)")
                    self.isLoaded = true
                } catch let DecodingError.valueNotFound(value, context) {
                    print("Decoding error: Missing value of type \(value) – \(context.debugDescription)")
                    self.isLoaded = true
                } catch let DecodingError.dataCorrupted(context) {
                    print("Decoding error: Data corrupted – \(context.debugDescription)")
                    self.isLoaded = true
                } catch {
                    print("Unknown error loading plans: \(error.localizedDescription)")
                    self.isLoaded = true
                }
            }
        } catch {
            print("Error reading plans file: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isLoaded = true
            }
        }
    }
    
    // Methods that can be overridden for testing
    public func getDocumentsURL() -> URL? {
        return self.getFileManager().urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    public func getFileManager() -> FileManager {
        return FileManager.default
    }
}
