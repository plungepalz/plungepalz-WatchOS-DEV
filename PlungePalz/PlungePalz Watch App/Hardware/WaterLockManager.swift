//
//  WaterLockManager.swift
// WatchOS App
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
        #if DEBUG
        print("=== WATER LOCK MANAGER: checkSystemWaterLockState called ===")
        print("System water lock enabled: \(isEnabled)")
        print("Current isSystemWaterLockEnabled: \(isSystemWaterLockEnabled)")
        #endif
        DispatchQueue.main.async {
            self.isSystemWaterLockEnabled = isEnabled
            #if DEBUG
            print("=== WATER LOCK MANAGER: Updated isSystemWaterLockEnabled to: \(isEnabled) ===")
            #endif
        }
    }
    
    /// Enables water lock mode programmatically using the correct API
    func enableWaterLock() {
        #if DEBUG
        print("=== WATER LOCK MANAGER: enableWaterLock called ===")
        print("Current isWaterLockEnabled: \(isWaterLockEnabled)")
        print("Current isLocked: \(isLocked)")
        #endif
        
        // Use the correct API to enable Water Lock mode
        WKInterfaceDevice.current().enableWaterLock()
        
        isWaterLockEnabled = true
        isLocked = true
        
        // Start monitoring for Water Lock state changes
        startWaterLockMonitoring()
        
        #if DEBUG
        print("=== WATER LOCK MANAGER: Water lock enabled programmatically ===")
        print("New isWaterLockEnabled: \(isWaterLockEnabled)")
        print("New isLocked: \(isLocked)")
        #endif
    }
    
    /// Disables water lock mode
    func disableWaterLock() {
        guard isWaterLockEnabled else { return }
        
        isWaterLockEnabled = false
        isLocked = false
        
        // Stop the water lock timer
        stopWaterLockMonitoring()
        
        #if DEBUG
        print("=== WATER LOCK MANAGER: Water lock disabled ===")
        #endif
    }
    
    /// Starts monitoring for Water Lock state changes
    private func startWaterLockMonitoring() {
        // Check immediately
        checkSystemWaterLockState()
        
        // Set up periodic checking
        waterLockTimer?.invalidate()
        waterLockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.checkSystemWaterLockState()
        }
    }
    
    /// Stops monitoring for Water Lock state changes
    private func stopWaterLockMonitoring() {
        waterLockTimer?.invalidate()
        waterLockTimer = nil
    }
    
    /// Returns true if the stop button should be disabled (when system water lock is enabled)
    var shouldDisableStopButton: Bool {
        return isSystemWaterLockEnabled
    }
}