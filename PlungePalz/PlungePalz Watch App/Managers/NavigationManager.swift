//
//  NavigationManager.swift
//  PlungePalz Watch App
//
//  Updated to support ActivityStartedScreen for Sauna/Cold Shower
//

import SwiftUI
import Combine

// MARK: - Screen Enum
enum AppScreen: Int, CaseIterable {
    case home = 1
    case connectDevice = 2
    case notSubscribed = 3
    case saunaOrColdShowerMessage = 4  // Info screen for Sauna/Cold Shower
    case selectSession = 5
    case setTimer = 6
    case setTemperature = 7
    case getReadyCountdownTimer = 8
    case countdownActivated = 9        // For Cold Plunge
    case activityStarted = 10          // NEW: For Sauna/Cold Shower (countup only)
    case activityStoppedOrPaused = 11
    case sessionDeleted = 12
    case sessionRecap = 13
    case pendingSaveSessions = 14
    case savingOrDeletingPendingActivities = 15
    
    var title: String {
        switch self {
        case .home:
            return "Home"
        case .connectDevice:
            return "Connect Device"
        case .notSubscribed:
            return "Not Subscribed"
        case .saunaOrColdShowerMessage:
            return "Activity Info"
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
        case .activityStarted:
            return "Activity Started"
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
        #if DEBUG
        print("=== NAVIGATION MANAGER: goToScreen called ===")
        print("From screen: \(currentScreen.title) (\(currentScreen.rawValue))")
        print("To screen: \(screen.title) (\(screen.rawValue))")
        #endif
        
        previousScreen = currentScreen
        currentScreen = screen
        
        // Add to navigation stack
        navigationStack.append(screen)
        
        #if DEBUG
        print("=== NAVIGATION MANAGER: Screen change completed ===")
        #endif
    }
}