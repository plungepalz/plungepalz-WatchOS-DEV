//
//  HomeScreen.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import SwiftUI

struct HomeScreen: View {
    @StateObject private var screenManager = WatchScreenManager()
    @ObservedObject var navigationManager: NavigationManager
    @EnvironmentObject var sessionDataManager: SessionDataManager
    
    // Placeholder for connection status
    enum ConnectionStatus {
        case connected, connecting, notPaired, noWiFi
        
        var iconName: String {
            switch self {
            case .connected:
                return "checkmark.icloud.fill"
            case .connecting:
                return "wifi"
            case .notPaired:
                return "person.crop.circle.badge.exclamationmark.fill"
            case .noWiFi:
                return "wifi.slash"
            }
        }
        
        var statusText: String {
            switch self {
            case .connected:
                return "Connected"
            case .connecting:
                return "Connecting..."
            case .notPaired:
                return "Not Paired"
            case .noWiFi:
                return "No WiFi"
            }
        }
        
        var iconColor: Color {
            switch self {
            case .connected:
                return .green
            case .connecting:
                return .yellow
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
    
    // Dummy API behavior
    private func simulateConnection() {
        // Start with connecting state
        connectionStatus = .connecting
        
        // Start WiFi animation
        startWifiAnimation()
        
        // After 2 seconds, change to connected state
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            connectionStatus = .connected
        }
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
                    } else if connectionStatus == .connected {
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
                        .foregroundStyle(.white)
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
                        // Connected or No WiFi
                        if connectionStatus == .connected || connectionStatus == .noWiFi {
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
                            break
                        case .connected, .noWiFi:
                            navigationManager.goToScreen(.selectSession)
                        case .notPaired:
                            navigationManager.goToScreen(.connectDevice)
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
            print("=== HOMESCREEN USER ID CHECK ===")
            if let userId = storedUserId {
                print("✅ User ID found in local memory: \(userId)")
                // User is paired, simulate connection process
                simulateConnection()
            } else {
                print("❌ No User ID found in local memory - user needs to pair device")
                // User is not paired, set status immediately
                connectionStatus = .notPaired
            }
            print("=================================")

            // When the home screen is loaded, reset the session tracking
            sessionDataManager.resetSessionTracking()
            
        }
        .onChange(of: connectionStatus) { newStatus in
            if newStatus == .connected {
                sessionDataManager.fetchLastSessionData()
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