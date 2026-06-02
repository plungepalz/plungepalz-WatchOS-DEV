//
//  WorkoutManager.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/5/25.
//

import Foundation
import HealthKit
import Combine

class WorkoutManager: NSObject, ObservableObject {
    // MARK: - HealthKit Properties
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    
    // MARK: - Published Properties
    @Published var isActive: Bool = false
    @Published var isPaused: Bool = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var workoutState: HKWorkoutSessionState = .notStarted
    @Published var timerMode: String = "countdown" // "countdown" or "countup"
    
    // Heart rate data for workout
    private var heartRateSamples: [HKQuantitySample] = []
    
    // Flag to track if we're in the process of ending a workout
    private var isEndingWorkout: Bool = false
    
    // Timer for elapsed time
    private var timer: Timer?
    private var sessionStartDate: Date?
    private var pauseDate: Date?
    
    // MARK: - Start Workout
    func startWorkout(startDate: Date = Date()) {
        #if DEBUG
        print("=== WORKOUT MANAGER: startWorkout called ===")
        print("Current isActive: \(isActive)")
        print("Current isPaused: \(isPaused)")
        print("Current workoutState: \(workoutState)")
        #endif
        
        // Only start if not already active
        guard !isActive else { 
            #if DEBUG
            print("=== WORKOUT MANAGER: Already active, returning early ===")
            #endif
            return 
        }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .mindAndBody // Using .mindAndBody for cold plunge therapy
        configuration.locationType = .indoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
            session?.delegate = self
            builder?.delegate = self
            
            // Start the session and builder
            session?.startActivity(with: startDate)
            builder?.beginCollection(withStart: startDate) { (success, error) in
                // Handle error if needed
            }
            
            isActive = true
            isPaused = false
            workoutState = .running
            sessionStartDate = startDate
            startTimer()
        } catch {
            print("Failed to start workout session: \(error)")
        }
    }
    
    // MARK: - Pause Workout
    func pauseWorkout() {
        guard isActive, !isPaused else { return }
        session?.pause()
        isPaused = true
        workoutState = .paused
        pauseDate = Date()
        stopTimer()
    }
    
    // MARK: - Resume Workout
    func resumeWorkout() {
        guard isActive, isPaused else { return }
        session?.resume()
        isPaused = false
        workoutState = .running
        
        // Update the session start date to account for the pause duration
        if let pauseDate = pauseDate {
            let pauseDuration = Date().timeIntervalSince(pauseDate)
            sessionStartDate = sessionStartDate?.addingTimeInterval(pauseDuration)
        }
        
        pauseDate = nil
        startTimer()
    }
    
    // MARK: - Stop Workout (simplified approach)
    func stopWorkout() {
        guard let session = self.session else { return }
        
        #if DEBUG
        print("=== WORKOUT MANAGER: stopWorkout called ===")
        print("Current session state: \(session.state)")
        #endif
        
        session.stopActivity(with: Date())
    }
    
    // MARK: - Handle Workout Ending (discard — does NOT save to Apple Fitness)
    private func handleWorkoutEnding() {
        guard !isEndingWorkout, let builder = self.builder else { return }
        isEndingWorkout = true

        builder.endCollection(withEnd: Date()) { [weak self] (_, _) in
            // Discard instead of finishWorkout — nothing is written to HealthKit/Apple Fitness
            self?.builder?.discardWorkout()

            DispatchQueue.main.async {
                self?.isActive = false
                self?.isEndingWorkout = false
                self?.stopTimer()
                print("✅ Workout discarded — not saved to Apple Fitness")
            }
        }
    }
    
    // MARK: - Add Heart Rate Data
    func addHeartRateData(_ heartRate: Int, timestamp: Date) {
        guard isActive, let builder = builder else { return }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let heartRateQuantity = HKQuantity(unit: HKUnit(from: "count/min"), doubleValue: Double(heartRate))
        let heartRateSample = HKQuantitySample(type: heartRateType, quantity: heartRateQuantity, start: timestamp, end: timestamp)
        
        builder.add([heartRateSample]) { success, error in
            if let error = error {
                print("Failed to add heart rate data: \(error)")
            }
        }
    }
    
    // MARK: - Discard Workout
    func discardWorkout() {
        guard isActive else { return }
        session?.end()
        builder?.discardWorkout()
        isActive = false
        isPaused = false
        elapsedTime = 0
        workoutState = .ended
        sessionStartDate = nil
        pauseDate = nil
        session = nil
        builder = nil
        stopTimer()
    }
    
    // MARK: - Timer Management
    private func startTimer() {
        #if DEBUG
        print("=== WORKOUT MANAGER: startTimer called ===")
        #endif
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
        #if DEBUG
        print("=== WORKOUT MANAGER: Timer started ===")
        #endif
    }
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    private func updateElapsedTime() {
        guard let start = sessionStartDate else { 
            #if DEBUG
            print("=== WORKOUT MANAGER: updateElapsedTime - no sessionStartDate ===")
            #endif
            return 
        }
        if isPaused, let pauseDate = pauseDate {
            // When paused, use the time up to the pause point
            elapsedTime = pauseDate.timeIntervalSince(start)
            #if DEBUG
            print("=== WORKOUT MANAGER: updateElapsedTime (paused) - elapsedTime: \(elapsedTime) ===")
            #endif
        } else {
            // When running, use current time minus start time
            elapsedTime = Date().timeIntervalSince(start)
            #if DEBUG
            print("=== WORKOUT MANAGER: updateElapsedTime (running) - elapsedTime: \(elapsedTime) ===")
            #endif
        }
    }

    // Add to WorkoutManager.swift
    func completelyEndSession() {
        #if DEBUG
        print("=== WORKOUT MANAGER: COMPLETELY ENDING SESSION ===")
        #endif
        
        // Stop timer FIRST (regardless of session state)
        stopTimer()
        
        // Only try to stop session if it's in a valid state
        // if let session = session, session.state == .running || session.state == .paused {
        //     session.stopActivity(with: Date())
        // }

        // CRITICAL: Properly end HealthKit session (discard BEFORE ending so it does not get saved to Apple Fitness)
        if let session = session {
            if session.state == .running || session.state == .paused || session.state == .stopped {

                // Always discard BEFORE ending — covers running, paused, and stopped states
                builder?.discardWorkout()

                #if DEBUG
                print("=== WORKOUT MANAGER: Discarding workout before ending session ===")
                #endif

                // End the session entirely
                session.end()

                #if DEBUG
                print("=== WORKOUT MANAGER: HealthKit session ended ✅ ===")
                #endif
            }
        }
        
        // Clear all state immediately (don't wait for HealthKit)
        isActive = false
        isPaused = false
        elapsedTime = 0
        sessionStartDate = nil
        pauseDate = nil

        // CRITICAL: Clear session references to prevent background activity
        session = nil
        builder = nil
        
        #if DEBUG
        print("=== WORKOUT MANAGER: SESSION COMPLETELY ENDED ===")
        #endif
    }
}

// MARK: - HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.workoutState = toState
            if toState == .stopped {
                self.handleWorkoutEnding()
            }
        }
    }
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error)")
    }
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {}
}