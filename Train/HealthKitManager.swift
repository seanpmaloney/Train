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
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
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
    
    private func fetchSleep(predicate: NSPredicate) async {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        do {
            let results : Double? = try await withCheckedThrowingContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: sleepType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: nil
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    let sleepSamples = samples as? [HKCategorySample] ?? []
                    let totalSeconds = sleepSamples.reduce(0.0) { total, sample in
                        total + sample.endDate.timeIntervalSince(sample.startDate)
                    }
                    
                    continuation.resume(returning: totalSeconds / 3600.0) // Convert to hours
                }
                
                healthStore.execute(query)
            }
            
            sleepHours = results
        } catch {
            print("Error fetching sleep: \(error)")
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
