//
//  HomeScreen.swift
//  PlungePalz Watch App
//
//  Updated to support multiple activity types and GPS tracking
//

import SwiftUI
import HealthKit
import CoreLocation

struct HomeScreen: View {
    @StateObject private var screenManager = WatchScreenManager()
    @ObservedObject var navigationManager: NavigationManager
    @EnvironmentObject var sessionDataManager: SessionDataManager
    
    // MARK: - HealthKit
    @StateObject private var healthKitManager = HealthKitManager.shared
    
    // Activity options — icons/colors from ActivityTypes.swift
    private var activities: [ActivityOption] {
        ActivityTypes.catalog.map {
            ActivityOption(
                name: $0.homeDisplayName,
                icon: $0.systemIcon,
                type: $0.activityType,
                iconColor: $0.iconColor
            )
        }
    }

    private var visibleActivities: [ActivityOption] {
        guard !sessionDataManager.activityTypeSettings.isEmpty else { return activities }
        let availableTypes = Set(sessionDataManager.activityTypeSettings.map { $0.activityType })
        return activities.filter { availableTypes.contains($0.type) }
    }
    
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
                return "Connected"
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
    
    // Helper to check if we're offline (persisted in UserDefaults)
    private var isOffline: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "isOffline")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isOffline")
        }
    }
    
    // MARK: - GPS Location State
    enum GPSStatus {
        case searching
        case found
        case notFound
        case disabled  // When allowSmartwatchGPSlocator is false
    }
    
    @State private var gpsStatus: GPSStatus = .searching
    @StateObject private var locationManager = LocationManager()

    // MARK: - Connection Functions
    private func performConnection() {
        connectionStatus = .connecting
        UserDefaults.standard.set(false, forKey: "isOffline") // Reset offline flag when attempting connection
        
        sessionDataManager.fetchLastSessionData { success in
            if success {
                // API call succeeded - update status based on subscription
                UserDefaults.standard.set(false, forKey: "isOffline")
                self.updateConnectionStatusBasedOnSubscription()
            } else {
                // API call failed (offline/network error) - show No WiFi status
                // Cached data has already been loaded by SessionDataManager
                #if DEBUG
                print("📡 HomeScreen: API call failed, showing No WiFi status (using cached data)")
                #endif
                UserDefaults.standard.set(true, forKey: "isOffline")
                self.connectionStatus = .noWiFi
            }
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
            startGPSTracking()
        } else {
            connectionStatus = .notSubscribed
        }
    }
    
    // MARK: - Pending Activities Check
    private func checkPendingActivities() {
        let pendingRequests = UserDefaults.standard.array(forKey: "pending_requests") as? [[String: Any]] ?? []
        let pendingCount = pendingRequests.count
        
        #if DEBUG
        print("📦 HomeScreen: Checking pending activities - Count: \(pendingCount)")
        print("📦 Previous screen: \(navigationManager.previousScreen.title)")
        #endif
        
        if pendingCount > 0 {
            // Check if we're coming from PendingSaveSessionsScreen, SavingOrDeletingPendingActivities, or NotSubscribed
            // to avoid infinite navigation loop
            let previousScreen = navigationManager.previousScreen
            let isComingFromPendingScreens = previousScreen == .pendingSaveSessions || 
                                            previousScreen == .savingOrDeletingPendingActivities ||
                                            previousScreen == .notSubscribed
            
            if isComingFromPendingScreens {
                #if DEBUG
                print("📦 Pending activities found but user is coming from \(previousScreen.title) - Skipping navigation to avoid loop")
                #endif
                return
            }
            
            #if DEBUG
            print("📦 Pending activities found: \(pendingCount) session(s) waiting to be saved - Navigating to PendingSaveSessionsScreen")
            #endif
            // Navigate to PendingSaveSessionsScreen when pending activities are found
            DispatchQueue.main.async {
                self.navigationManager.goToScreen(.pendingSaveSessions)
            }
        }
    }
    
    // MARK: - GPS Tracking Functions
    private func startGPSTracking() {
        // Check if GPS is allowed from API settings
        guard sessionDataManager.allowSmartwatchGPSlocator else {
            #if DEBUG
            print("📍 GPS tracking disabled by user settings")
            #endif
            gpsStatus = .disabled
            return
        }
        
        #if DEBUG
        print("📍 Starting GPS tracking with 60-second timeout")
        #endif
        
        gpsStatus = .searching
        locationManager.requestLocation()
        
        // Set 60-second timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) {
            if self.gpsStatus == .searching {
                #if DEBUG
                print("⏱️ GPS timeout reached - location not found")
                #endif
                self.gpsStatus = .notFound
            }
        }
    }

    var body: some View {
        let screenSize = screenManager.currentScreenSize
        let screenHeight = WKInterfaceDevice.current().screenBounds.height

        // ====== Define all adaptive UI constants for HomeScreen ======
        let topContainerHeightRatio = WatchGlobalUIConfig.HomeScreen.topContainerHeightRatio(for: screenSize)
        let connectionStatusIconSize = WatchGlobalUIConfig.HomeScreen.connectionStatusIconSize(for: screenSize)
        let chevronPadding = WatchGlobalUIConfig.HomeScreen.chevronPadding(for: screenSize)
        let plungeButtonCornerRadius = WatchGlobalUIConfig.HomeScreen.plungeButtonCornerRadius(for: screenSize)
        let plungeButtonHorizontalPadding = WatchGlobalUIConfig.HomeScreen.plungeButtonHorizontalPadding(for: screenSize)
        let plungeButtonVerticalPadding = WatchGlobalUIConfig.HomeScreen.plungeButtonVerticalPadding(for: screenSize)
        let bottomLogoSpacing = WatchGlobalUIConfig.HomeScreen.bottomLogoSpacing(for: screenSize)
        let middleContainerPaddingTrailing = WatchGlobalUIConfig.HomeScreen.middleContainerPaddingTrailing(for: screenSize)
        // ====== End of adaptive UI constants for HomeScreen ======

        VStack(spacing: 0) {
            // Top Black Container
            ZStack {
                Color.black
                
                // Connection Status (always centered in screen)
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
                
                // GPS Icon (absolute positioned top-left, only visible when subscribed)
                if connectionStatus == .subscribed {
                    VStack {
                        HStack {
                            if gpsStatus == .searching {
                                if #available(watchOS 10.0, *) {
                                    Image(systemName: "location.slash")
                                        .font(.system(size: connectionStatusIconSize * 0.7, weight: .bold))
                                        .foregroundStyle(.yellow)
                                        .symbolEffect(.bounce.up.byLayer, options: .repeating)
                                } else {
                                    Image(systemName: "location.slash")
                                        .font(.system(size: connectionStatusIconSize * 0.7, weight: .bold))
                                        .foregroundStyle(.yellow)
                                }
                            } else if gpsStatus == .found {
                                Image(systemName: "location.fill")
                                    .font(.system(size: connectionStatusIconSize * 0.7, weight: .bold))
                                    .foregroundStyle(.green)
                            } else {
                                // notFound or disabled
                                Image(systemName: "location.slash")
                                    .font(.system(size: connectionStatusIconSize * 0.7, weight: .bold))
                                    .foregroundStyle(.yellow)
                            }
                            Spacer()
                        }
                        .padding(.leading, 12)
                        .padding(.top, 12)
                        Spacer()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 0))
            .frame(maxWidth: .infinity)
            .frame(height: screenHeight * topContainerHeightRatio)
            
            // Middle Blue Container - Flexible layout greedy stack pushing bottom down
            ZStack {
                Color(red: 0/255, green: 116/255, blue: 255/255)
                
                if connectionStatus == .subscribed || connectionStatus == .noWiFi {
                    // Show scrollable activity list
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            // MARK: Activity Pills
                            ForEach(0..<visibleActivities.count, id: \.self) { index in
                                ActivitySelectionRow(
                                    activity: visibleActivities[index],
                                    connectionStatusIconSize: connectionStatusIconSize
                                )
                                .onTapGesture {
                                    sessionDataManager.activityType = visibleActivities[index].type

                                    #if DEBUG
                                    print("🎯 Activity selected: \(visibleActivities[index].name) (\(visibleActivities[index].type))")
                                    #endif

                                    navigationManager.goToScreen(.selectSession)
                                }
                            }

                            // MARK: Routine Pills (shown only when routines are available)
                            if connectionStatus == .subscribed && !sessionDataManager.routineData.isEmpty {
                                ForEach(sessionDataManager.routineData) { routine in
                                    RoutineSelectionRow(
                                        routine: routine,
                                        connectionStatusIconSize: connectionStatusIconSize
                                    )
                                    .onTapGesture {
                                        #if DEBUG
                                        print("🔄 Routine selected: \(routine.nickname)")
                                        #endif
                                        sessionDataManager.activeRoutine = routine
                                        navigationManager.goToScreen(.routineView)
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
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Dynamic sizing taking leftover room
            .padding(.vertical, 2)
                        
            // Bottom Black Container (adaptive logo and text)
            VStack(spacing: 4) {
                // Elegant, thin structural separator accent
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal, 8)
                
                HStack(spacing: 8) {
                    // App Branding Icon
                    Image("HomeScreenIconImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .cornerRadius(5)
                    
                    // Brand Text Layout
                    Text("PlungePalz")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 0)
                .padding(.bottom, 6) // Smooth clearance padding matching watch casing radii
            }
            .frame(maxWidth: .infinity)
            .background(Color.black)
            .fixedSize(horizontal: false, vertical: true) // Prevents vertical bloating
        }
        .edgesIgnoringSafeArea(.all)
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
        .onAppear {
            #if DEBUG
            print("🏠 HomeScreen: onAppear - Performing connection check, fetchLastSessionData, and pending activities check")
            #endif
            
            // Always check for pending activities first
            checkPendingActivities()
            
            // Check for stored userId in local memory
            let storedUserId = UserDefaults.standard.string(forKey: "userId")
            
            // First, check if we're offline (persisted state)
            let currentlyOffline = isOffline
            
            if let userId = storedUserId, !userId.isEmpty {
                if currentlyOffline {
                    #if DEBUG
                    print("📊 HomeScreen: Offline detected, but still attempting connection to check status")
                    #endif
                }
                
                // Always perform connection (which calls fetchLastSessionData)
                #if DEBUG
                print("✅ HomeScreen: Performing connection check and fetching session data")
                #endif
                performConnection()
            } else {
                #if DEBUG
                print("❌ No User ID found - user needs to pair device")
                #endif
                connectionStatus = .notPaired
            }

            sessionDataManager.resetSessionTracking()
            requestHealthKitPermissions()
        }
        .onChange(of: locationManager.location) { newLocation in
            if let location = newLocation, gpsStatus == .searching {
                #if DEBUG
                print("📍 GPS location found: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                #endif
                
                // Store coordinates in SessionDataManager
                sessionDataManager.sessionLatitude = location.coordinate.latitude
                sessionDataManager.sessionLongitude = location.coordinate.longitude
                
                // Update status to found
                gpsStatus = .found
            }
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
    let iconColor: Color
}

// MARK: - Activity Selection Row
struct ActivitySelectionRow: View {
    let activity: ActivityOption
    let connectionStatusIconSize: CGFloat
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .font(.system(size: connectionStatusIconSize * 0.9, weight: .bold))
                .foregroundStyle(activity.iconColor)
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
                .fill(Color(hex: "#001F3F"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
        )
        .padding(.horizontal, 8)
    }
}

// MARK: - Routine Selection Row
struct RoutineSelectionRow: View {
    let routine: RoutineModel
    let connectionStatusIconSize: CGFloat

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "point.topright.arrow.triangle.backward.to.point.bottomleft.scurvepath")
                .font(.system(size: connectionStatusIconSize * 0.9, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: connectionStatusIconSize)

            Text(routine.nickname)
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
                .fill(Color.black.opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.4), lineWidth: 2)
        )
        .padding(.horizontal, 8)
    }
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        #if DEBUG
        print("📍 LocationManager: Requesting location authorization and single location update")
        #endif
        
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        #if DEBUG
        print("📍 LocationManager: Location updated - Lat: \(location.coordinate.latitude), Lon: \(location.coordinate.longitude)")
        #endif
        
        DispatchQueue.main.async {
            self.location = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        #if DEBUG
        print("❌ LocationManager: Failed to get location - \(error.localizedDescription)")
        #endif
    }
}

#Preview {
    HomeScreen(navigationManager: NavigationManager())
        .environmentObject(SessionDataManager())
}