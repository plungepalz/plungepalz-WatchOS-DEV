//
//  ContentView.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var navigationManager = NavigationManager()
    
    var body: some View {
        Group {
            switch navigationManager.currentScreen {
            case .home:
                HomeScreen(navigationManager: navigationManager)
            case .connectDevice:
                ConnectDeviceScreen(navigationManager: navigationManager)
            case .selectSession:
                SelectSessionScreen(navigationManager: navigationManager)
            case .setTimer:
                SetTimerScreen(navigationManager: navigationManager)
            case .setTemperature:
                SetTemperatureScreen(navigationManager: navigationManager)
            case .countdownActivated:
                CountdownActivatedScreen(navigationManager: navigationManager)
            case .activityStoppedOrPaused:
                ActivityStoppedOrPausedScreen(navigationManager: navigationManager)
            case .sessionRecap:
                SessionRecapScreen(navigationManager: navigationManager)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: navigationManager.currentScreen)
    }
}

#Preview {
    ContentView()
}