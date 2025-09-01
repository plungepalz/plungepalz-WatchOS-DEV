//
//  HomeScreen.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import SwiftUI
import HealthKit

struct HomeScreen: View {
    @StateObject private var screenManager = WatchScreenManager()
    @ObservedObject var navigationManager: NavigationManager
    @EnvironmentObject var sessionDataManager: SessionDataManager
    
    // MARK: - HealthKit
    @StateObject private var healthKitManager = HealthKitManager.shared
    
    // Placeholder for connection status
    enum ConnectionStatus {
        case connecting
        case subscribed      // NEW: API success + isUserSubscribed = true
        case notSubscribed   // NEW: API success + isUserSubscribed = false
        case notPaired       // No userId in storage
        case noWiFi          // Network error
        
        var iconName: String {
            switch self {
            case .subscribed:
                return "checkmark.icloud.fill"
            case .connecting:
                return "wifi"
            case .notSubscribed:
                return "exclamationmark.triangle.fill"
            case .notPaired:
                return "person.crop.circle.badge.exclamationmark.fill"
            case .noWiFi:
                return "wifi.slash"
            }
        }
        
        var statusText: String {
            switch self {
            case .subscribed:
                return "Subscribed"
            case .connecting:
                return "Connecting..."
            case .notSubscribed:
                return "Not Subscribed"
            case .notPaired:
                return "Not Paired"
            case .noWiFi:
                return "No WiFi"
            }
        }
        
        var iconColor: Color {
            switch self {
            case .subscribed:
                return .green
            case .connecting:
                return .yellow
            case .notSubscribed:
                return .red
            case .notPaired:
                return .yellow
            case .noWiFi:
                return .red
            }
        }

        var statusTextColor: Color {
            switch self {
            case .subscribed:
                return .green
            case .connecting:
                return Color(red: 0.4, green: 0.8, blue: 1.0) // Same blue as connecting icon
            case .notSubscribed:
                return .red
            case .notPaired:
                return .yellow
            case .noWiFi:
                return .red
            }
        }
    }
    
    // TODO: Replace with real connection status logic
    @State private var connectionStatus: ConnectionStatus = .connecting
    @State private var wifiSignalStrength = 1
    
    // NEW: API behavior
    private func performConnection() {
        // Start with connecting state
        connectionStatus = .connecting
        
        // Start WiFi animation
        startWifiAnimation()
        
        // Call the SessionDataManager to fetch data
        sessionDataManager.fetchLastSessionData()
    }
    
    private func startWifiAnimation() {
        // Create a timer that fires every 0.3 seconds
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            if connectionStatus == .connecting {
                // Cycle through WiFi signal strengths (1-3)
                wifiSignalStrength = wifiSignalStrength % 3 + 1
            } else {
                // Stop the timer when we're no longer connecting
                timer.invalidate()
            }
        }
    }
    
    private func getWifiIconName() -> String {
        if connectionStatus == .connecting {
            return "wifi.\(wifiSignalStrength)"
        }
        return connectionStatus.iconName
    }

    // MARK: - Check Subscription Status
    private func updateConnectionStatusBasedOnSubscription() {
        // Always check subscription status when this function is called
        let isUserSubscribed = UserDefaults.standard.bool(forKey: "isUserSubscribed")
        
        #if DEBUG
        print("📊 HomeScreen: Checking subscription status, isUserSubscribed = \(isUserSubscribed)")
        #endif
        
        // Check if we have valid session data (indicates successful API call)
        if sessionDataManager.lastSessionData != nil {
            // API call was successful, set status based on subscription
            if isUserSubscribed {
                connectionStatus = .subscribed
            } else {
                connectionStatus = .notSubscribed
            }
        } else {
            // API call failed or no data - could be network issue  
            connectionStatus = .noWiFi
        }
    }

    
    var body: some View {
        let screenSize = screenManager.currentScreenSize
        let screenHeight = WKInterfaceDevice.current().screenBounds.height
        // ====== Define all adaptive UI constants for HomeScreen ======//
        

        // Container Height Ratios
        let topContainerHeightRatio = WatchGlobalUIConfig.HomeScreen.topContainerHeightRatio(for: screenSize)
        let middleBlueContainerHeightRatio = WatchGlobalUIConfig.HomeScreen.middleBlueContainerHeightRatio(for: screenSize)
        let bottomContainerHeightRatio = WatchGlobalUIConfig.HomeScreen.bottomContainerHeightRatio(for: screenSize)

        // Top Container Assets
        let connectionStatusIconSize = WatchGlobalUIConfig.HomeScreen.connectionStatusIconSize(for: screenSize)
        
        // Middle Container Assets
        let chevronPadding = WatchGlobalUIConfig.HomeScreen.chevronPadding(for: screenSize)
        let plungeButtonCornerRadius = WatchGlobalUIConfig.HomeScreen.plungeButtonCornerRadius(for: screenSize)
        let plungeButtonHorizontalPadding = WatchGlobalUIConfig.HomeScreen.plungeButtonHorizontalPadding(for: screenSize)
        let plungeButtonVerticalPadding = WatchGlobalUIConfig.HomeScreen.plungeButtonVerticalPadding(for: screenSize)
        let bottomLogoSpacing = WatchGlobalUIConfig.HomeScreen.bottomLogoSpacing(for: screenSize)
        let middleContainerPaddingTrailing = WatchGlobalUIConfig.HomeScreen.middleContainerPaddingTrailing(for: screenSize)

        // Bottom Container Assets
        let bottomContainerLogoSize = WatchGlobalUIConfig.HomeScreen.bottomContainerLogoSize(for: screenSize)
        let bottomContainerLogoSpacing = WatchGlobalUIConfig.HomeScreen.bottomContainerLogoSpacing(for: screenSize)
        let bottomContainerAssetPadding = WatchGlobalUIConfig.HomeScreen.bottomContainerAssetPadding(for: screenSize)

        // ====== End of adaptive UI constants for HomeScreen ======
        
        
        
        // Add more as you add to WatchGlobalUIConfig.HomeScreen
        VStack(spacing: 0) {
            // Top Black Container
            ZStack {
                Color.black
                VStack(spacing: 4) {
                    if connectionStatus == .connecting {
                        if #available(watchOS 10.0, *) {
                            Image(systemName: "wifi")
                                .font(.system(size: connectionStatusIconSize, weight: .bold))
                                .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                                .symbolEffect(.bounce.up.byLayer, options: .repeating)
                                .padding(.top, bottomLogoSpacing)
                        } else {
                            Image(systemName: "wifi")
                                .font(.system(size: connectionStatusIconSize, weight: .bold))
                                .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                                .padding(.top, bottomLogoSpacing)
                        }
                    } else if connectionStatus == .subscribed {
                        if #available(watchOS 10.0, *) {
                            Image(systemName: "checkmark.icloud.fill")
                                .font(.system(size: connectionStatusIconSize, weight: .bold))
                                .foregroundStyle(connectionStatus.iconColor)
                                .symbolEffect(.bounce.up.byLayer, options: .nonRepeating)
                                .padding(.top, bottomLogoSpacing)
                        } else {
                            Image(systemName: "checkmark.icloud.fill")
                                .font(.system(size: connectionStatusIconSize, weight: .bold))
                                .foregroundStyle(connectionStatus.iconColor)
                                .padding(.top, bottomLogoSpacing)
                        }
                    } else {
                        if #available(watchOS 10.0, *) {
                            Image(systemName: connectionStatus.iconName)
                                .font(.system(size: connectionStatusIconSize, weight: .bold))
                                .foregroundStyle(connectionStatus.iconColor)
                                .symbolEffect(.bounce.up.byLayer, options: .nonRepeating)
                                .padding(.top, bottomLogoSpacing)
                        } else {
                            Image(systemName: connectionStatus.iconName)
                                .font(.system(size: connectionStatusIconSize, weight: .bold))
                                .foregroundStyle(connectionStatus.iconColor)
                                .padding(.top, bottomLogoSpacing)
                        }
                    }
                    Text(connectionStatus.statusText)
                        .watchAdaptivePoppinsFont(style: .title, weight: .bold)
                        .foregroundStyle(connectionStatus.statusTextColor)
                        .padding(.bottom, bottomLogoSpacing)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 0))
            .frame(maxWidth: .infinity)
            .frame(height: screenHeight * topContainerHeightRatio)
            
            // Middle Blue Container (adaptive height and padding)
            ZStack {
                Color(red: 0/255, green: 116/255, blue: 255/255)
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: connectionStatusIconSize, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.trailing, chevronPadding)
                    HStack(spacing: chevronPadding) {
                        // Subscribed or No WiFi
                        if connectionStatus == .subscribed || connectionStatus == .noWiFi {
                            Image(systemName: "snowflake")
                                .font(.system(size: connectionStatusIconSize, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Plunge")
                                .watchAdaptivePoppinsFont(style: .title, weight: .regular)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        // Not Paired
                        else if connectionStatus == .notPaired {
                            Image(systemName: "app.connected.to.app.below.fill")
                                .font(.system(size: connectionStatusIconSize, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Pair")
                                .watchAdaptivePoppinsFont(style: .title, weight: .regular)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        // Not Subscribed - show different button
                        else if connectionStatus == .notSubscribed {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: connectionStatusIconSize, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Subscribe")
                                .watchAdaptivePoppinsFont(style: .title, weight: .regular)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                    .padding(.vertical, plungeButtonVerticalPadding)
                    .padding(.horizontal, plungeButtonHorizontalPadding)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: plungeButtonCornerRadius))
                    .padding(.trailing, middleContainerPaddingTrailing)
                    .onTapGesture {
                        switch connectionStatus {
                        case .connecting:
                            // Do nothing while connecting
                            #if DEBUG
                            print("⏳ Still connecting, please wait...")
                            #endif
                            break
                        case .subscribed, .noWiFi:
                            #if DEBUG
                            print("✅ Navigating to select session")
                            #endif
                            navigationManager.goToScreen(.selectSession)
                        case .notPaired:
                            #if DEBUG
                            print("📱 Navigating to connect device")
                            #endif
                            navigationManager.goToScreen(.connectDevice)
                        case .notSubscribed:
                            #if DEBUG
                            navigationManager.goToScreen(.notSubscribed)  // Navigate to NotSubscribed screen
                            #endif
                            // TODO: Navigate to subscription screen when implemented
                            break
                        }
                    }
                    .opacity(connectionStatus == .connecting ? 0.5 : 1.0)
                    Spacer(minLength: 0)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 0))
            .frame(maxWidth: .infinity)
            .frame(height: screenHeight * middleBlueContainerHeightRatio)
            .padding(.vertical, 2)
                        
            // Bottom Black Container (adaptive logo and text)
            HStack(alignment: .center, spacing: bottomContainerLogoSpacing) {
                Image("HomeScreenIconImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: bottomContainerLogoSize, height: bottomContainerLogoSize)
                Text("PlungePalz")
                    .watchAdaptivePoppinsFont(style: .body, weight: .bold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.bottom, bottomContainerAssetPadding)
            .padding(.top, bottomLogoSpacing)
            .frame(maxWidth: .infinity)
            .frame(height: screenHeight * bottomContainerHeightRatio)
            .background(Color.black)
        }
        .edgesIgnoringSafeArea(.all)
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
        .onAppear {
            // Check for stored userId in local memory
            let storedUserId = UserDefaults.standard.string(forKey: "userId")
            
            if let userId = storedUserId, !userId.isEmpty {
                // Check if we already have session data
                if sessionDataManager.lastSessionData != nil {
                    // We already have data, just update the status based on current subscription
                    #if DEBUG
                    print("📊 HomeScreen: Already have session data, updating status")
                    #endif
                    updateConnectionStatusBasedOnSubscription()
                } else {
                    // No session data yet, perform full connection
                    #if DEBUG
                    print("✅ User ID found, starting connection process")
                    #endif
                    performConnection()
                }
            } else {
                #if DEBUG
                print("❌ No User ID found - user needs to pair device")
                #endif
                connectionStatus = .notPaired
            }

            sessionDataManager.resetSessionTracking()
            requestHealthKitPermissions()
        }
        .onChange(of: sessionDataManager.lastSessionData) { _ in
            // When session data changes, update connection status based on subscription
            #if DEBUG
            print("📊 HomeScreen: Session data changed, updating connection status")
            #endif
            updateConnectionStatusBasedOnSubscription()
        }
    }
    
    // MARK: - HealthKit Permission Request
    private func requestHealthKitPermissions() {
        healthKitManager.requestHeartRatePermission { granted in
            DispatchQueue.main.async {
                if granted {
                    // print("✅ HealthKit heart rate permission granted")
                } else {
                    // print("❌ HealthKit heart rate permission denied")
                }
            }
        }
    }
}

#Preview {
    let previewManager: SessionDataManager = {
        let manager = SessionDataManager()
        manager.lastSessionData = [
            "lastSessionTimeSet": "3:15",
            "lastSessionWaterTemp": "45.5",
            "unitOfMeasure": "Imperial"
        ]
        return manager
    }()
    return HomeScreen(navigationManager: NavigationManager())
        .environmentObject(previewManager)
} 
