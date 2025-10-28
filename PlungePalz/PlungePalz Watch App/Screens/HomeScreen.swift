//
//  HomeScreen.swift
//  PlungePalz Watch App
//
//  Updated to support multiple activity types
//

import SwiftUI
import HealthKit

struct HomeScreen: View {
    @StateObject private var screenManager = WatchScreenManager()
    @ObservedObject var navigationManager: NavigationManager
    @EnvironmentObject var sessionDataManager: SessionDataManager
    
    // MARK: - HealthKit
    @StateObject private var healthKitManager = HealthKitManager.shared
    
    // MARK: - Activity Selection State
    @State private var selectedActivityIndex: Int = 0
    
    // Activity options
    let activities = [
        ActivityOption(name: "Plunge", icon: "snowflake", type: "Cold Plunge"),
        ActivityOption(name: "Sauna", icon: "heater.vertical", type: "Sauna"),
        ActivityOption(name: "Cold Shower", icon: "shower", type: "Cold Shower")
    ]
    
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

    @State private var connectionStatus: ConnectionStatus = .connecting
    @State private var isAPIBusy: Bool = false
    @StateObject private var apiManager = APIs.shared

    // MARK: - Connection Functions
    private func performConnection() {
        connectionStatus = .connecting
        
        sessionDataManager.fetchLastSessionData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            updateConnectionStatusBasedOnSubscription()
        }
    }

    private func updateConnectionStatusBasedOnSubscription() {
        let isUserSubscribed = UserDefaults.standard.bool(forKey: "isUserSubscribed")
        
        #if DEBUG
        print("👤 HomeScreen: updateConnectionStatusBasedOnSubscription called")
        print("👤 isUserSubscribed: \(isUserSubscribed)")
        #endif
        
        if isUserSubscribed {
            connectionStatus = .subscribed
        } else {
            connectionStatus = .notSubscribed
        }
    }

    var body: some View {
        let screenSize = screenManager.currentScreenSize
        let screenWidth = WKInterfaceDevice.current().screenBounds.width
        let screenHeight = WKInterfaceDevice.current().screenBounds.height

        // ====== Define all adaptive UI constants for HomeScreen ======
        let topContainerHeightRatio = WatchGlobalUIConfig.HomeScreen.topContainerHeightRatio(for: screenSize)
        let middleBlueContainerHeightRatio = WatchGlobalUIConfig.HomeScreen.middleBlueContainerHeightRatio(for: screenSize)
        let bottomContainerHeightRatio = WatchGlobalUIConfig.HomeScreen.bottomContainerHeightRatio(for: screenSize)
        let connectionStatusIconSize = WatchGlobalUIConfig.HomeScreen.connectionStatusIconSize(for: screenSize)
        let chevronPadding = WatchGlobalUIConfig.HomeScreen.chevronPadding(for: screenSize)
        let plungeButtonCornerRadius = WatchGlobalUIConfig.HomeScreen.plungeButtonCornerRadius(for: screenSize)
        let plungeButtonHorizontalPadding = WatchGlobalUIConfig.HomeScreen.plungeButtonHorizontalPadding(for: screenSize)
        let plungeButtonVerticalPadding = WatchGlobalUIConfig.HomeScreen.plungeButtonVerticalPadding(for: screenSize)
        let bottomLogoSpacing = WatchGlobalUIConfig.HomeScreen.bottomLogoSpacing(for: screenSize)
        let middleContainerPaddingTrailing = WatchGlobalUIConfig.HomeScreen.middleContainerPaddingTrailing(for: screenSize)
        let bottomContainerLogoSize = WatchGlobalUIConfig.HomeScreen.bottomContainerLogoSize(for: screenSize)
        let bottomContainerLogoSpacing = WatchGlobalUIConfig.HomeScreen.bottomContainerLogoSpacing(for: screenSize)
        let bottomContainerAssetPadding = WatchGlobalUIConfig.HomeScreen.bottomContainerAssetPadding(for: screenSize)
        // ====== End of adaptive UI constants for HomeScreen ======

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
            
            // Middle Blue Container - Activity Selection or Navigation
            ZStack {
                Color(red: 0/255, green: 116/255, blue: 255/255)
                
                if connectionStatus == .subscribed || connectionStatus == .noWiFi {
                    // Show scrollable activity list
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(0..<activities.count, id: \.self) { index in
                                ActivitySelectionRow(
                                    activity: activities[index],
                                    isSelected: selectedActivityIndex == index,
                                    connectionStatusIconSize: connectionStatusIconSize
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedActivityIndex = index
                                        // Set the activity type in SessionDataManager
                                        sessionDataManager.activityType = activities[index].type
                                        
                                        #if DEBUG
                                        print("🎯 Activity selected: \(activities[index].name) (\(activities[index].type))")
                                        #endif
                                        
                                        // Navigate based on activity type
                                        if activities[index].type == "Cold Plunge" {
                                            navigationManager.goToScreen(.selectSession)
                                        } else {
                                            // For Sauna or Cold Shower, show info message first
                                            navigationManager.goToScreen(.saunaOrColdShowerMessage)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    // Not Paired or Not Subscribed - show navigation button
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: connectionStatusIconSize, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.trailing, chevronPadding)
                        HStack(spacing: chevronPadding) {
                            if connectionStatus == .notPaired {
                                Image(systemName: "app.connected.to.app.below.fill")
                                    .font(.system(size: connectionStatusIconSize, weight: .bold))
                                    .foregroundStyle(.white)
                                Text("Pair")
                                    .watchAdaptivePoppinsFont(style: .title, weight: .regular)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            } else if connectionStatus == .notSubscribed {
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
                        .padding(.horizontal, plungeButtonHorizontalPadding)
                        .padding(.vertical, plungeButtonVerticalPadding)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: plungeButtonCornerRadius))
                        .padding(.trailing, middleContainerPaddingTrailing)
                        .opacity(connectionStatus == .connecting ? 0.5 : 1.0)
                        Spacer(minLength: 0)
                    }
                    .onTapGesture {
                        if connectionStatus == .notPaired {
                            navigationManager.goToScreen(.connectDevice)
                        } else if connectionStatus == .notSubscribed {
                            navigationManager.goToScreen(.notSubscribed)
                        }
                    }
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
    }
    
    // MARK: - HealthKit Authorization
    func requestHealthKitPermissions() {
        healthKitManager.requestHeartRatePermission { success in
            if success {
                #if DEBUG
                print("✅ HealthKit heart rate permission granted")
                #endif
            } else {
                #if DEBUG
                print("❌ HealthKit heart rate permission denied")
                #endif
            }
        }
    }
}

// MARK: - Activity Option Model
struct ActivityOption {
    let name: String
    let icon: String
    let type: String
}

// MARK: - Activity Selection Row
struct ActivitySelectionRow: View {
    let activity: ActivityOption
    let isSelected: Bool
    let connectionStatusIconSize: CGFloat
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .font(.system(size: connectionStatusIconSize * 0.9, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: connectionStatusIconSize)
            
            Text(activity.name)
                .watchAdaptivePoppinsFont(style: .title, weight: .regular)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            
            Spacer()
            
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.black.opacity(0.3) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.white.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 2)
        )
        .padding(.horizontal, 8)
    }
}

#Preview {
    HomeScreen(navigationManager: NavigationManager())
        .environmentObject(SessionDataManager())
}