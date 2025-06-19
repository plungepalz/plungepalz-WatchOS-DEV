//
//  WaterLockManager.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import WatchKit
import Foundation
import SwiftUI

class WaterLockManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = WaterLockManager()
    
    // MARK: - Published Properties
    @Published var isWaterLockEnabled = false
    @Published var isLocked: Bool = false
    @Published var isSystemWaterLockEnabled: Bool = false
    
    // MARK: - Properties
    private var waterLockTimer: Timer?
    
    // MARK: - Initialization
    private init() {
        checkSystemWaterLockState()
    }
    
    // MARK: - Public Methods
    
    /// Checks if the system water lock mode is enabled using the public API
    func checkSystemWaterLockState() {
        let isEnabled = WKInterfaceDevice.current().isWaterLockEnabled
        DispatchQueue.main.async {
            self.isSystemWaterLockEnabled = isEnabled
            // print("System water lock state: \(isEnabled ? "Enabled" : "Disabled")")
        }
    }
    
    /// Enables water lock mode (app simulation)
    func enableWaterLock() {
        isWaterLockEnabled = true
        isLocked = true
        print("Water lock enabled (app simulation)")
    }
    
    /// Disables water lock mode (app simulation)
    func disableWaterLock() {
        guard isWaterLockEnabled else { return }
        
        // Re-enable autorotation
        WKExtension.shared().isAutorotating = true
        
        isWaterLockEnabled = false
        isLocked = false
        
        // Stop the water lock timer
        stopWaterLockTimer()
        
        print("Water lock disabled (app simulation)")
    }
    
    /// Returns true if the stop button should be disabled (when system water lock is enabled)
    var shouldDisableStopButton: Bool {
        return isSystemWaterLockEnabled
    }
    
    
    private func stopWaterLockTimer() {
        waterLockTimer?.invalidate()
        waterLockTimer = nil
    }
    
    private func checkWaterLockStatus() {
        // Periodically check system water lock state
        checkSystemWaterLockState()
        
        // Periodically ensure water lock is still active
        if isWaterLockEnabled {
            // Re-apply water lock settings if needed
            WKExtension.shared().isAutorotating = false
        }
    }
}