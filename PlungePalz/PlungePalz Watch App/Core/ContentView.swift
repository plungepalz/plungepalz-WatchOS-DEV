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
            case .prepareCountdown:
                PrepareCountdownScreen(navigationManager: navigationManager)
            case .countdownActivated:
                let source: CountdownActivatedScreen.NavigationSource = navigationManager.previousScreen == .selectSession ? .selectSession : .setTemperature
                CountdownActivatedScreen(navigationManager: navigationManager, navigationSource: source)
            case .activityStoppedOrPaused:
                ActivityStoppedOrPausedScreen(navigationManager: navigationManager)
            case .sessionDeleted:
                SessionDeletedScreen(navigationManager: navigationManager)
            case .sessionRecap:
                SessionRecapScreen(navigationManager: navigationManager)
            case .pendingSaveSessions:
                PendingSaveSessionsScreen(navigationManager: navigationManager)
            case .savingOrDeletingPendingActivities:
                SavingOrDeletingPendingActivities(navigationManager: navigationManager, mode: navigationManager.activityMode)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: navigationManager.currentScreen)
        .onAppear {
            let pendingRequests = UserDefaults.standard.array(forKey: "pending_requests") as? [[String: Any]]
            if let requests = pendingRequests, !requests.isEmpty {
                navigationManager.goToScreen(.pendingSaveSessions)
            } else {
                navigationManager.goToScreen(.home)
            }
        }
    }
}

#Preview {
    ContentView()
}