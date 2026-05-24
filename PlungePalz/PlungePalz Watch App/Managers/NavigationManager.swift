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
    case selectSession = 4
    case setTimer = 5
    case setTemperature = 6
    case getReadyCountdownTimer = 7
    case countdownActivated = 8
    case activityStarted = 9
    case activityStoppedOrPaused = 10
    case sessionDeleted = 11
    case sessionRecap = 12
    case pendingSaveSessions = 13
    case savingOrDeletingPendingActivities = 14
    // MARK: - Routine Screens
    case routineView = 15
    case routineGetReady = 16
    case routineTransition = 17
    case routineModality = 18
    case routinePause = 19
    case routineRecap = 20

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .connectDevice:
            return "Connect Device"
        case .notSubscribed:
            return "Not Subscribed"
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
        case .routineView:
            return "Routine View"
        case .routineGetReady:
            return "Routine Get Ready"
        case .routineTransition:
            return "Routine Transition"
        case .routineModality:
            return "Routine Modality"
        case .routinePause:
            return "Routine Pause"
        case .routineRecap:
            return "Routine Recap"
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

    // MARK: - Routine Pause Communication
    /// "Modality" or "Transition" — set by ModalityScreen / TransitionScreen before navigating to PauseScreen
    @Published var routinePauseSource: String = ""
    /// "save" | "skip" | "" — set by PauseScreen; observed by ModalityScreen / TransitionScreen
    @Published var routinePauseAction: String = ""
    
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