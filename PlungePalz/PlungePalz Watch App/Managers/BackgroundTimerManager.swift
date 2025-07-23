//
//  BackgroundTimerManager.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import Foundation
import WatchKit
import Combine

class BackgroundTimerManager: ObservableObject {
    static let shared = BackgroundTimerManager()
    
    // MARK: - Published Properties
    @Published var isInBackground: Bool = false
    @Published var backgroundStartTime: Date?
    @Published var lastHeartRateBeforeSleep: Int?
    @Published var isActiveSession: Bool = false
    
    // MARK: - Private Properties
    private var backgroundTask: WKRefreshBackgroundTask?
    private var backgroundTimer: Timer?
    private var sessionDataManager: SessionDataManager?
    
    private init() {}
    
    // MARK: - Public Properties
    var currentSessionDataManager: SessionDataManager? {
        return self.sessionDataManager
    }
    
    // MARK: - Public Methods
    func setSessionDataManager(_ manager: SessionDataManager) {
        self.sessionDataManager = manager
    }
    
    func startActiveSession() {
        isActiveSession = true
        #if DEBUG
        print("🔄 Active session started")
        #endif
    }
    
    func endActiveSession() {
        isActiveSession = false
        #if DEBUG
        print("🔄 Active session ended")
        #endif
    }
    
    func handleAppDidEnterBackground() {
        guard let sessionManager = sessionDataManager else { return }
        
        #if DEBUG
        print("🔄 Background: Starting background timer logic")
        #endif
        
        isInBackground = true
        backgroundStartTime = Date()
        
        // Store the last heart rate value before sleep
        if let lastHR = sessionManager.HRArray.last {
            lastHeartRateBeforeSleep = lastHR
            #if DEBUG
            print("🔄 Background: Stored last HR: \(lastHR)")
            #endif
        }
        
        // Store current timer state
        storeTimerState()
        
        // Start background timer
        startBackgroundTimer()
        
        // Request background execution time
        requestBackgroundExecution()
    }
    
    func handleAppWillEnterForeground() {
        guard let sessionManager = sessionDataManager else { return }
        
        #if DEBUG
        print("🔄 Foreground: Restoring timer state")
        #endif
        
        isInBackground = false
        
        // Calculate elapsed time and update session data
        calculateAndUpdateElapsedTime()
        
        // Stop background timer
        stopBackgroundTimer()
        
        // Clear background task
        backgroundTask?.setTaskCompletedWithSnapshot(false)
        backgroundTask = nil
        
        #if DEBUG
        print("🔄 Foreground: Timer state restored")
        #endif
    }
    
    // MARK: - Private Methods
    private func storeTimerState() {
        guard let sessionManager = sessionDataManager else { return }
        
        let state: [String: Any] = [
            "accumulatedSessionTime": sessionManager.accumulatedSessionTime,
            "currentTimerMode": sessionManager.currentTimerMode,
            "originalCountdownTimeSeconds": sessionManager.originalCountdownTimeSeconds,
            "epicTime": sessionManager.epicTime ?? 0,
            "timestamp": Date().timeIntervalSince1970,
            "isActiveSession": isActiveSession
        ]
        
        UserDefaults.standard.set(state, forKey: "timer_background_state")
        
        #if DEBUG
        print("🔄 Background: Stored timer state - accumulated: \(sessionManager.accumulatedSessionTime), mode: \(sessionManager.currentTimerMode)")
        #endif
    }
    
    private func startBackgroundTimer() {
        backgroundTimer?.invalidate()
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateBackgroundTimer()
        }
        
        #if DEBUG
        print("🔄 Background: Background timer started")
        #endif
    }
    
    private func stopBackgroundTimer() {
        backgroundTimer?.invalidate()
        backgroundTimer = nil
        
        #if DEBUG
        print("🔄 Background: Background timer stopped")
        #endif
    }
    
    private func updateBackgroundTimer() {
        guard let sessionManager = sessionDataManager else { return }
        
        // Update accumulated session time
        sessionManager.accumulatedSessionTime += 1
        
        // Append heart rate data (repeat last value)
        if let lastHR = lastHeartRateBeforeSleep {
            sessionManager.HRArray.append(lastHR)
        }
        
        // Update timer mode if needed
        updateTimerModeIfNeeded()
        
        #if DEBUG
        print("🔄 Background: Timer updated - accumulated: \(sessionManager.accumulatedSessionTime)")
        #endif
    }
    
    private func updateTimerModeIfNeeded() {
        guard let sessionManager = sessionDataManager else { return }
        
        // Check if we need to switch from countdown to countup mode
        if sessionManager.currentTimerMode == "Countdown" {
            let elapsed = sessionManager.accumulatedSessionTime
            let totalDuration = sessionManager.originalCountdownTimeSeconds
            
            if elapsed >= totalDuration {
                sessionManager.currentTimerMode = "Countup"
                #if DEBUG
                print("🔄 Background: Switched to countup mode")
                #endif
            }
        }
    }
    
    private func requestBackgroundExecution() {
        // Request background execution time
        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: Date().addingTimeInterval(30),
            userInfo: nil
        ) { error in
            if let error = error {
                #if DEBUG
                print("🔄 Background: Failed to schedule background refresh: \(error)")
                #endif
            } else {
                #if DEBUG
                print("🔄 Background: Background refresh scheduled")
                #endif
            }
        }
    }
    
    private func calculateAndUpdateElapsedTime() {
        guard let sessionManager = sessionDataManager,
              let startTime = backgroundStartTime else { return }
        
        let elapsedTime = Int(Date().timeIntervalSince(startTime))
        
        #if DEBUG
        print("🔄 Foreground: Calculated elapsed time: \(elapsedTime) seconds")
        #endif
        
        // Update accumulated session time
        sessionManager.accumulatedSessionTime += elapsedTime
        
        // Append heart rate data for the sleep period
        if let lastHR = lastHeartRateBeforeSleep {
            for _ in 0..<elapsedTime {
                sessionManager.HRArray.append(lastHR)
            }
            #if DEBUG
            print("🔄 Foreground: Appended \(elapsedTime) HR values of \(lastHR)")
            #endif
        }
        
        // Update timer mode if needed
        updateTimerModeIfNeeded()
        
        // Clear stored data
        backgroundStartTime = nil
        lastHeartRateBeforeSleep = nil
        
        #if DEBUG
        print("🔄 Foreground: Final accumulated time: \(sessionManager.accumulatedSessionTime)")
        #endif
    }
} 