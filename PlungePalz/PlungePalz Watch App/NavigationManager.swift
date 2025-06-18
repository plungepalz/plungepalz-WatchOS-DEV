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
    case sessionRecap = 8
    
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
        case .sessionRecap:
            return "Session Recap"
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
        previousScreen = currentScreen
        currentScreen = screen
    }
} 