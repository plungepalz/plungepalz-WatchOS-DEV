//
//  HealthKitManager.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var heartRateUpdateHandler: ((Int) -> Void)?
    
    @Published var isHeartRatePermissionGranted: Bool = false
    
    private init() {}
    
    func requestHeartRatePermission(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            // print("HealthKit is not available on this device")
            DispatchQueue.main.async {
                self.isHeartRatePermissionGranted = false
                completion(false)
            }
            return
        }
        
        // The quantity types to write to the health store (for workouts)
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        
        // The quantity types to read from the health store
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.activitySummaryType(),
        ]
        
        // Request authorization for both read and write permissions
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if let error = error {
                    // print("HealthKit authorization error: \(error)")
                }
                self?.isHeartRatePermissionGranted = success
                completion(success)
            }
        }
    }
    
    func startHeartRateMonitoring(updateHandler: @escaping (Int) -> Void) {
        self.heartRateUpdateHandler = updateHandler
        
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            // print("Heart rate type not available")
            return
        }
        
        // Create a predicate for recent heart rate data
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-60), end: nil, options: .strictStartDate)
        
        // Create the query
        heartRateQuery = HKAnchoredObjectQuery(type: heartRateType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRateSamples(samples)
        }
        
        // Set up continuous updates
        heartRateQuery?.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRateSamples(samples)
        }
        
        // Execute the query
        if let query = heartRateQuery {
            healthStore.execute(query)
        }
    }
    
    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else { return }
        
        // Get the most recent heart rate reading
        if let mostRecentSample = heartRateSamples.last {
            let heartRate = mostRecentSample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            let heartRateInt = Int(round(heartRate))
            
            DispatchQueue.main.async {
                self.heartRateUpdateHandler?(heartRateInt)
            }
        }
    }
    
    func stopHeartRateMonitoring() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
        heartRateUpdateHandler = nil
    }
} 