    import HealthKit
import Foundation

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    private let calendar = Calendar.current
    
    @Published var hrvValue: Double?
    @Published var sleepHours: Double?
    @Published var restingHeartRate: Double?
    @Published var isAuthorized = false
    @Published var externalWorkouts: [ExternalWorkout] = []
    @Published var workoutSourcePriorities: [String] = []
    
    private var allExternalWorkouts: [ExternalWorkout] = [] // Unfiltered workouts
    
    private init() {
        loadWorkoutSourcePriorities()
    }
    
    func requestAuthorization() async -> Bool {
        // Define the types we want to read from HealthKit
        let typesToRead: Set<HKSampleType> = [
            HKQuantityType(.heartRateVariabilitySDNN),
            HKQuantityType(.restingHeartRate),
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType()
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            isAuthorized = true
            
            // Immediately fetch data after authorization is granted
            await fetchTodayData()
            
            return true
        } catch {
            print("Error requesting HealthKit authorization: \(error)")
            return false
        }
    }
    
    func fetchTodayData() async {
        guard isAuthorized else { return }
        
        // Get today's start and end dates
        let end = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -36, to: end)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        
        // Fetch HRV
        await fetchHRV(predicate: predicate)
        
        // Fetch Sleep
        await fetchSleep(predicate: predicate)
        
        // Fetch Resting Heart Rate
        await fetchRestingHeartRate(predicate: predicate)
        
        // Fetch recent workouts (last 30 days)
        await fetchRecentWorkouts()
    }
    
    private func fetchHRV(predicate: NSPredicate) async {
        let hrvType = HKQuantityType(.heartRateVariabilitySDNN)
        
        do {
            let results : Double? = try await withCheckedThrowingContinuation { continuation in
                let query = HKStatisticsQuery(
                    quantityType: hrvType,
                    quantitySamplePredicate: predicate,
                    options: .discreteAverage
                ) { _, statistics, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    let value = statistics?.averageQuantity()?.doubleValue(for: HKUnit.secondUnit(with: .milli))
                    continuation.resume(returning: value)
                }
                
                healthStore.execute(query)
            }
            
            hrvValue = results
        } catch {
            print("Error fetching HRV: \(error)")
            hrvValue = nil
        }
    }
    
    struct SleepInterval {
        let start: Date
        let end: Date
        
        var duration: TimeInterval {
            end.timeIntervalSince(start)
        }
        
        func overlaps(with other: SleepInterval) -> Bool {
            return start < other.end && other.start < end
        }
        
        func merge(with other: SleepInterval) -> SleepInterval {
            let newStart = min(start, other.start)
            let newEnd = max(end, other.end)
            return SleepInterval(start: newStart, end: newEnd)
        }
    }
    
    private struct SleepSource {
        let name: String
        let stageData: [SleepInterval]
        let asleepData: [SleepInterval]
        let inBedData: [SleepInterval]
        
        var hasSleepStages: Bool { !stageData.isEmpty }
        var hasAsleepData: Bool { !asleepData.isEmpty }
        var hasInBedData: Bool { !inBedData.isEmpty }
        
        // Total duration across all sleep stages
        var stageDuration: TimeInterval {
            stageData.reduce(0) { $0 + $1.duration }
        }
        
        // Helper to get best available data
        func getBestAvailableData() -> (intervals: [SleepInterval], type: String) {
            if hasSleepStages {
                return (stageData, "Sleep Stages")
            } else if hasAsleepData {
                return (asleepData, "Asleep")
            } else {
                return (inBedData, "In Bed")
            }
        }
    }
    
    private func fetchSleep(predicate: NSPredicate) async {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        // Define sleep categories
        let sleepStageValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,    // 3
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,    // 4
            HKCategoryValueSleepAnalysis.asleepREM.rawValue      // 5
        ]
        
        do {
            let results: Double? = try await withCheckedThrowingContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: sleepType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
                ) { _, samples, error in
                    if let error = error {
                        print("Sleep query error: \(error.localizedDescription)")
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    let sleepSamples = samples as? [HKCategorySample] ?? []
                    
                    // Group samples by source
                    let sourceGroups = Dictionary(grouping: sleepSamples) {
                        $0.sourceRevision.source.name
                    }
                    
                    // Process each source's data
                    var sleepSources: [SleepSource] = []
                    
                    for (sourceName, samples) in sourceGroups {
                        // Categorize samples for this source
                        let stageIntervals = samples
                            .filter { sleepStageValues.contains($0.value) }
                            .map { SleepInterval(start: $0.startDate, end: $0.endDate) }
                        
                        let asleepIntervals = samples
                            .filter { $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue }
                            .map { SleepInterval(start: $0.startDate, end: $0.endDate) }
                        
                        let inBedIntervals = samples
                            .filter { $0.value == HKCategoryValueSleepAnalysis.inBed.rawValue }
                            .map { SleepInterval(start: $0.startDate, end: $0.endDate) }
                        
                        let source = SleepSource(
                            name: sourceName,
                            stageData: stageIntervals,
                            asleepData: asleepIntervals,
                            inBedData: inBedIntervals
                        )
                        
                        sleepSources.append(source)
                    }
                    
                    // Find best source based on data quality
                    let bestSource = sleepSources
                        .sorted { source1, source2 in
                            // Prefer sources with sleep stages
                            if source1.hasSleepStages != source2.hasSleepStages {
                                return source1.hasSleepStages
                            }
                            // If both have stages, prefer the one with more data
                            if source1.hasSleepStages && source2.hasSleepStages {
                                return source1.stageDuration > source2.stageDuration
                            }
                            // Prefer sources with asleep data
                            if source1.hasAsleepData != source2.hasAsleepData {
                                return source1.hasAsleepData
                            }
                            // Finally, prefer sources with any data
                            return source1.hasInBedData
                        }
                        .first
                    
                    guard let selectedSource = bestSource else {
                        print("No sleep data found in time window")
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    // Get best available data from selected source
                    let (intervals, dataType) = selectedSource.getBestAvailableData()
                    
                    // Merge overlapping intervals
                    var mergedIntervals: [SleepInterval] = []
                    for interval in intervals.sorted(by: { $0.start < $1.start }) {
                        if let lastInterval = mergedIntervals.last,
                           lastInterval.overlaps(with: interval) {
                            mergedIntervals[mergedIntervals.count - 1] = lastInterval.merge(with: interval)
                        } else {
                            mergedIntervals.append(interval)
                        }
                    }
                    
                    // Calculate total duration
                    let totalHours = mergedIntervals.reduce(0.0) { total, interval in
                        total + (interval.duration / 3600.0)
                    }
                    
                    // Comprehensive debug logging
                    print("""
                    Sleep Analysis Results:
                    - Selected source: \(selectedSource.name)
                    - Data type used: \(dataType)
                    - Original intervals: \(intervals.count)
                    - Merged intervals: \(mergedIntervals.count)
                    - Total sleep: \(String(format: "%.2f", totalHours)) hours
                    
                    Available sources:
                    \(sleepSources.map { "• \($0.name): stages=\($0.hasSleepStages), asleep=\($0.hasAsleepData), inBed=\($0.hasInBedData)" }.joined(separator: "\n"))
                    """)
                    
                    continuation.resume(returning: totalHours)
                }
                
                healthStore.execute(query)
            }
            
            sleepHours = results
            
        } catch {
            print("Error fetching sleep data: \(error.localizedDescription)")
            sleepHours = nil
        }
    }
    
    private func fetchRestingHeartRate(predicate: NSPredicate) async {
        let heartRateType = HKQuantityType(.restingHeartRate)
        
        do {
            let results : Double?  = try await withCheckedThrowingContinuation { continuation in
                let query = HKStatisticsQuery(
                    quantityType: heartRateType,
                    quantitySamplePredicate: predicate,
                    options: .discreteAverage
                ) { _, statistics, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    let value = statistics?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    continuation.resume(returning: value)
                }
                
                healthStore.execute(query)
            }
            
            restingHeartRate = results
        } catch {
            print("Error fetching resting heart rate: \(error)")
            restingHeartRate = nil
        }
    }
    
    // MARK: - Workout Data
    
    func fetchRecentWorkouts() async {
        guard isAuthorized else { return }
        
        // Get workouts from the last 30 days
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        
        do {
            let workouts: [ExternalWorkout] = try await withCheckedThrowingContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: HKObjectType.workoutType(),
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
                ) { _, samples, error in
                    if let error = error {
                        print("Error fetching workouts: \(error)")
                        continuation.resume(returning: [])
                        return
                    }
                    
                    let hkWorkouts = samples as? [HKWorkout] ?? []
                    let externalWorkouts = hkWorkouts.map { ExternalWorkout(from: $0) }
                    
                    print("Fetched \(externalWorkouts.count) external workouts")
                    continuation.resume(returning: externalWorkouts)
                }
                
                healthStore.execute(query)
            }
            
            self.allExternalWorkouts = workouts
            self.externalWorkouts = filterDuplicateWorkouts(workouts)
            
        } catch {
            print("Error fetching workouts: \(error)")
            self.externalWorkouts = []
        }
    }
    
    /// Get external workouts for a specific date
    func getExternalWorkouts(for date: Date) -> [ExternalWorkout] {
        return externalWorkouts.filter { workout in
            calendar.isDate(workout.startDate, inSameDayAs: date)
        }
    }
    
    /// Get all workouts (external) for a date range
    func getExternalWorkouts(from startDate: Date, to endDate: Date) -> [ExternalWorkout] {
        return externalWorkouts.filter { workout in
            workout.startDate >= startDate && workout.startDate <= endDate
        }
    }
    
    // MARK: - Workout Source Priority Management
    
    private func loadWorkoutSourcePriorities() {
        if let savedPriorities = UserDefaults.standard.array(forKey: "WorkoutSourcePriorities") as? [String] {
            workoutSourcePriorities = savedPriorities
        } else {
            // Set default priorities: Apple Watch > Garmin Connect > Strava > Others alphabetically
            workoutSourcePriorities = getDefaultSourcePriorities()
            saveWorkoutSourcePriorities()
        }
    }
    
    private func saveWorkoutSourcePriorities() {
        UserDefaults.standard.set(workoutSourcePriorities, forKey: "WorkoutSourcePriorities")
    }
    
    private func getDefaultSourcePriorities() -> [String] {
        return ["Apple Watch", "Garmin Connect", "Strava"]
    }
    
    func updateWorkoutSourcePriorities(_ newPriorities: [String]) {
        workoutSourcePriorities = newPriorities
        saveWorkoutSourcePriorities()
        
        // Re-filter workouts with new priorities
        externalWorkouts = filterDuplicateWorkouts(allExternalWorkouts)
    }
    
    func getDetectedWorkoutSources() -> [String] {
        let detectedSources = Set(allExternalWorkouts.map { $0.sourceName })
        
        // Combine existing priorities with newly detected sources
        var allSources = workoutSourcePriorities
        
        // Add any new sources not in priorities (alphabetically)
        let newSources = detectedSources.subtracting(Set(workoutSourcePriorities)).sorted()
        allSources.append(contentsOf: newSources)
        
        // Update priorities to include new sources
        if !newSources.isEmpty {
            updateWorkoutSourcePriorities(allSources)
        }
        
        return allSources.filter { detectedSources.contains($0) }
    }
    
    // MARK: - Duplicate Filtering
    
    private func filterDuplicateWorkouts(_ workouts: [ExternalWorkout]) -> [ExternalWorkout] {
        print("[HealthKit] Starting duplicate filtering with \(workouts.count) workouts")
        
        // First, let's manually group duplicates with more precise logic
        var filteredWorkouts: [ExternalWorkout] = []
        var processedWorkouts: Set<UUID> = []
        
        for workout in workouts {
            if processedWorkouts.contains(workout.id) {
                continue // Already processed as part of a duplicate group
            }
            
            
            // Find all potential duplicates for this workout
            let duplicates = workouts.filter { otherWorkout in
                otherWorkout.id != workout.id &&
                !processedWorkouts.contains(otherWorkout.id) &&
                abs(otherWorkout.startDate.timeIntervalSince1970 - workout.startDate.timeIntervalSince1970) <= 300
            }
            
            if duplicates.isEmpty {
                // No duplicates, keep the original workout
                filteredWorkouts.append(workout)
                processedWorkouts.insert(workout.id)
            } else {
                // Found duplicates, choose the best one
                let allDuplicates = [workout] + duplicates
                let bestWorkout = chooseBestWorkout(from: allDuplicates)
                
                print("[HealthKitManager] Found \(allDuplicates.count) duplicates at \(workout.startDate):")
                for dup in allDuplicates {
                    let isChosen = dup.id == bestWorkout.id ? "✓" : "✗"
                    print("  \(isChosen) \(dup.sourceName): \(dup.title) (\(dup.durationString))")
                }
                
                filteredWorkouts.append(bestWorkout)
                
                // Mark all duplicates as processed
                for duplicate in allDuplicates {
                    processedWorkouts.insert(duplicate.id)
                }
            }
        }
        
        print("[HealthKit] Filtered from \(workouts.count) to \(filteredWorkouts.count) workouts")
        return filteredWorkouts.sorted { $0.startDate > $1.startDate }
    }
    
    private func chooseBestWorkout(from workouts: [ExternalWorkout]) -> ExternalWorkout {
        // Sort by source priority (lower index = higher priority)
        let bestWorkout = workouts.min { workout1, workout2 in
            let priority1 = workoutSourcePriorities.firstIndex(of: workout1.sourceName) ?? Int.max
            let priority2 = workoutSourcePriorities.firstIndex(of: workout2.sourceName) ?? Int.max
            
            if priority1 != priority2 {
                return priority1 < priority2
            }
            
            // If same priority, prefer the one with more data (heart rate or calories)
            let hasData1 = workout1.averageHeartRate != nil || workout1.totalEnergyBurned != nil
            let hasData2 = workout2.averageHeartRate != nil || workout2.totalEnergyBurned != nil
            
            if hasData1 != hasData2 {
                return hasData1
            }
            
            // Finally, prefer the one that was recorded first (earlier start time)
            return workout1.startDate < workout2.startDate
        } ?? workouts[0]
        
        print("[HealthKit] Chose \(bestWorkout.sourceName) over other sources: \(workouts.map { $0.sourceName }.joined(separator: ", "))")
        return bestWorkout
    }
}

// Helper struct for grouping duplicate workouts
private struct DuplicateKey: Hashable {
    let startTime: TimeInterval
    let duration: TimeInterval
    
    // Normalize values to 60-second buckets for consistent hashing and equality
    private var normalizedStartTime: Int {
        Int(startTime / 60)
    }
    
    private var normalizedDuration: Int {
        Int(duration / 60)
    }
    
    func hash(into hasher: inout Hasher) {
        // Use normalized values for consistent hashing
        hasher.combine(normalizedStartTime)
        hasher.combine(normalizedDuration)
    }
    
    static func == (lhs: DuplicateKey, rhs: DuplicateKey) -> Bool {
        // Use the same normalization logic for equality
        return lhs.normalizedStartTime == rhs.normalizedStartTime &&
               lhs.normalizedDuration == rhs.normalizedDuration
    }
}
