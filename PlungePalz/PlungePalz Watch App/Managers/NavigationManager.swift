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
    case getReadyCountdownTimer = 6
    case countdownActivated = 7
    case activityStoppedOrPaused = 8
    case sessionDeleted = 9
    case sessionRecap = 10
    case pendingSaveSessions = 11
    case savingOrDeletingPendingActivities = 12
    
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
        case .getReadyCountdownTimer:
            return "Get Ready Countdown Timer"
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
    @Published var originalNavigationSource: CountdownActivatedScreen.NavigationSource = .setTemperature
    
    // Navigation stack to track actual navigation history
    private var navigationStack: [AppScreen] = [.home]
    
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
        // Remove current screen from stack
        if !navigationStack.isEmpty {
            navigationStack.removeLast()
        }
        
        // Get the previous screen from the stack
        if let previousScreenFromStack = navigationStack.last {
            previousScreen = currentScreen
            currentScreen = previousScreenFromStack
        } else {
            // Fallback to home if stack is empty
            previousScreen = currentScreen
            currentScreen = .home
        }
    }
    
    func goToHome() {
        previousScreen = currentScreen
        currentScreen = .home
        
        // Clear navigation stack and add home
        navigationStack = [.home]
    }
    
    func goToScreen(_ screen: AppScreen) {
        // print("=== NAVIGATION MANAGER: goToScreen called ===")
        // print("From screen: \(currentScreen.title) (\(currentScreen.rawValue))")
        // print("To screen: \(screen.title) (\(screen.rawValue))")
        previousScreen = currentScreen
        currentScreen = screen
        
        // Add to navigation stack
        navigationStack.append(screen)
        
        // print("=== NAVIGATION MANAGER: Screen change completed ===")
    }
} 