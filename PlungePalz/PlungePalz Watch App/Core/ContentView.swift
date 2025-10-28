//
//  ContentView.swift
//  PlungePalz Watch App
//
//  Updated to support ActivityStartedScreen for Sauna/Cold Shower
//

import SwiftUI

struct ContentView: View {
    @StateObject private var navigationManager = NavigationManager()
    @EnvironmentObject var sessionDataManager: SessionDataManager
    @EnvironmentObject var backgroundTimerManager: BackgroundTimerManager
    
    var body: some View {
        Group {
            switch navigationManager.currentScreen {
            case .home:
                HomeScreen(navigationManager: navigationManager)
            case .connectDevice:
                ConnectDeviceScreen(navigationManager: navigationManager)
            case .notSubscribed:
                NotSubscribed(navigationManager: navigationManager)
            case .saunaOrColdShowerMessage:  // Activity info screen
                SaunaOrColdShowerMessage(navigationManager: navigationManager)
            case .selectSession:
                SelectSessionScreen(navigationManager: navigationManager)
            case .setTimer:
                SetTimerScreen(navigationManager: navigationManager)
            case .setTemperature:
                SetTemperatureScreen(navigationManager: navigationManager)
            case .getReadyCountdownTimer:
                GetReadyCountdownTimer(navigationManager: navigationManager)
            case .countdownActivated:
                // Use the original navigation source that was set when the user started the flow
                let source: CountdownActivatedScreen.NavigationSource = navigationManager.originalNavigationSource
                CountdownActivatedScreen(navigationManager: navigationManager, navigationSource: source)
            case .activityStarted:  // NEW: For Sauna/Cold Shower
                ActivityStartedScreen(navigationManager: navigationManager)
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
        .onChange(of: navigationManager.currentScreen) { newScreen in
            #if DEBUG
            print("📱 ContentView: Screen changed to: \(newScreen.title)")
            #endif
        }
        .animation(.easeInOut(duration: 0.3), value: navigationManager.currentScreen)
        .onAppear {
            // Connect BackgroundTimerManager with SessionDataManager
            backgroundTimerManager.setSessionDataManager(sessionDataManager)
            
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
        .environmentObject(SessionDataManager())
        .environmentObject(BackgroundTimerManager.shared)
}