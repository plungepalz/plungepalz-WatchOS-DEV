//
//  NavigationManager.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import SwiftUI

// MARK: - Screen Enum
enum AppScreen: Int, CaseIterable {
    case home = 1
    case connectDevice = 2
    case selectSession = 3
    case setTimer = 4
    case setTemperature = 5
    case countdownActivated = 6
    case activityStoppedOrPaused = 7
    case sessionDeleted = 8
    case sessionRecap = 9
    case pendingSaveSessions = 10
    case savingOrDeletingPendingActivities = 11
    
    var title: String {
        switch self {
        case .home:
            return "Home"
        case .connectDevice:
            return "Connect Device"
        case .selectSession:
            return "Select Session"
        case .setTimer:
            return "Set Timer"
        case .setTemperature:
            return "Set Temperature"
        case .countdownActivated:
            return "Countdown Activated"
        case .activityStoppedOrPaused:
            return "Activity Stopped/Paused"
        case .sessionDeleted:
            return "Session Deleted"
        case .sessionRecap:
            return "Session Recap"
        case .pendingSaveSessions:
            return "Pending Save Sessions"
        case .savingOrDeletingPendingActivities:
            return "Saving or Deleting Activities"
        }
    }
    
    var screenNumber: Int {
        return self.rawValue
    }
}

// MARK: - Navigation Manager
class NavigationManager: ObservableObject {
    @Published var currentScreen: AppScreen = .home
    @Published var previousScreen: AppScreen = .home
    @Published var activityMode: SavingOrDeletingPendingActivities.ActivityMode = .saving
    
    func nextScreen() {
        previousScreen = currentScreen
        let currentIndex = currentScreen.rawValue
        if currentIndex < AppScreen.allCases.count {
            currentScreen = AppScreen(rawValue: currentIndex + 1) ?? .home
        } else {
            // Go back to home after the last screen
            currentScreen = .home
        }
    }
    
    func goToPreviousScreen() {
        previousScreen = currentScreen
        let currentIndex = currentScreen.rawValue
        if currentIndex > 1 {
            currentScreen = AppScreen(rawValue: currentIndex - 1) ?? .home
        }
    }
    
    func goToHome() {
        previousScreen = currentScreen
        currentScreen = .home
    }
    
    func goToScreen(_ screen: AppScreen) {
        // print("=== NAVIGATION MANAGER: goToScreen called ===")
        // print("From screen: \(currentScreen.title) (\(currentScreen.rawValue))")
        // print("To screen: \(screen.title) (\(screen.rawValue))")
        previousScreen = currentScreen
        currentScreen = screen
        // print("=== NAVIGATION MANAGER: Screen change completed ===")
    }
} 