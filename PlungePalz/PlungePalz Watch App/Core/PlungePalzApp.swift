//
//  PlungePalzApp.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import SwiftUI
import WatchKit

@main
struct PlungePalzApp: App {
    @StateObject var sessionDataManager = SessionDataManager()
    @StateObject var backgroundTimerManager = BackgroundTimerManager.shared
    @StateObject var workoutManager = WorkoutManager()

    init() {
        #if DEBUG
        WatchScreenManager.logDetectedScreenSize()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionDataManager)
                .environmentObject(backgroundTimerManager)
                .environmentObject(workoutManager)
        }
    }
}

// MARK: - WKApplicationDelegate
class AppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidEnterBackground() {
        #if DEBUG
        print("🔄 App entered background")
        #endif
        BackgroundTimerManager.shared.handleAppDidEnterBackground()
        
        // Schedule background refresh to keep app active
        scheduleBackgroundRefresh()
    }
    
    func applicationWillEnterForeground() {
        #if DEBUG
        print("🔄 App will enter foreground")
        #endif
        BackgroundTimerManager.shared.handleAppWillEnterForeground()
    }
    
    func applicationDidBecomeActive() {
        #if DEBUG
        print("🔄 App became active")
        #endif
        // Ensure we're on the correct screen when app becomes active
        ensureCorrectScreenState()
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            #if DEBUG
            print("🔄 Handling background task: \(task)")
            #endif
            
            // Schedule the next background refresh
            scheduleBackgroundRefresh()
            
            // Mark task as completed
            task.setTaskCompletedWithSnapshot(false)
        }
    }
    
    private func scheduleBackgroundRefresh() {
        // Schedule background refresh every 30 seconds to keep app active
        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: Date().addingTimeInterval(30),
            userInfo: nil
        ) { error in
            if let error = error {
                #if DEBUG
                print("🔄 Failed to schedule background refresh: \(error)")
                #endif
            } else {
                #if DEBUG
                print("🔄 Background refresh scheduled successfully")
                #endif
            }
        }
    }
    
    private func ensureCorrectScreenState() {
        // If we're in an active session, ensure we stay on the countdown screen
        let sessionManager = BackgroundTimerManager.shared.currentSessionDataManager
        if let manager = sessionManager, manager.accumulatedSessionTime > 0 {
            // We're in an active session, ensure we're on the countdown screen
            #if DEBUG
            print("🔄 Ensuring we stay on countdown screen during active session")
            #endif
        }
    }
}
