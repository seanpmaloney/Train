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
    
    private init() {}
    
    func requestAuthorization() async -> Bool {
        // Define the types we want to read from HealthKit
        let typesToRead: Set<HKSampleType> = [
            HKQuantityType(.heartRateVariabilitySDNN),
            HKQuantityType(.restingHeartRate),
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            isAuthorized = true
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
} 
