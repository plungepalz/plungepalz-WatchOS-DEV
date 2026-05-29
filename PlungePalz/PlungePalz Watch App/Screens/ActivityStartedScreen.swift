//
//  ActivityStartedScreen.swift
//  PlungePalz Watch App
//
//  Screen for Sauna and Cold Shower activities (countup-only mode)
//

import SwiftUI
import WatchKit
import HealthKit

struct ActivityStartedScreen: View {
    // MARK: - Navigation
    @ObservedObject var navigationManager: NavigationManager
    
    // MARK: - Session Data
    @EnvironmentObject var sessionDataManager: SessionDataManager
    
    // MARK: - Background Timer
    @EnvironmentObject var backgroundTimerManager: BackgroundTimerManager
    @EnvironmentObject var workoutManager: WorkoutManager
    
    // MARK: - Screen Management
    @StateObject private var screenManager = WatchScreenManager()
    
    // MARK: - Water Lock Management
    @StateObject private var waterLockManager = WaterLockManager.shared
    
    // MARK: - HealthKit
    @StateObject private var healthKitManager = HealthKitManager.shared
    
    // MARK: - Timer State
    @State private var timer: Timer?
    
    // MARK: - Heart Rate State (every 5 seconds)
    @State private var heartRate: Int?
    @State private var heartRateTimer: Timer?
    @State private var heartRateSecondCounter: Int = 0
    
    // MARK: - Session Temperature
    private var sessionTemperatureString: String {
        let tempF = sessionDataManager.sessionTempF
        guard tempF > 0 else { return "--" }
        return sessionDataManager.formatTempDisplayWithUnit(tempF: tempF)
    }

    private var activityIcon: String {
        ActivityTypes.systemIcon(for: sessionDataManager.activityType)
    }

    private var activityColor: Color {
        ActivityTypes.iconColor(for: sessionDataManager.activityType)
    }
    
    // Colors
    private let hrBoxColors: [Color] = [
        Color(hex: "#A5A5A5"),
        Color(hex: "#95E4FF"),
        Color(hex: "#32DE84"),
        Color(hex: "#F1A100"),
        Color(hex: "#FF6E65")
    ]
    
    // MARK: - Heart Rate Bar Chart
    private func hrBoxIndex(for hr: Int?) -> Int {
        guard let hr = hr else { return 0 }
        if hr < 60 { return 0 }
        if hr < 100 { return 1 }
        if hr < 140 { return 2 }
        if hr < 180 { return 3 }
        return 4
    }
    
    var body: some View {
        let screenSize = screenManager.currentScreenSize
        let screenWidth = WKInterfaceDevice.current().screenBounds.width
        let screenHeight = WKInterfaceDevice.current().screenBounds.height
        
        // Use CountdownActivatedScreen UI Config Variables
        let stopIconTopCornerPadding = WatchGlobalUIConfig.CountdownActivatedScreen.stopIconTopCornerPadding(for: screenSize)
        let stopIconSize = WatchGlobalUIConfig.CountdownActivatedScreen.stopIconSize(for: screenSize)
        let topPaddingTimer = WatchGlobalUIConfig.CountdownActivatedScreen.topPaddingTimer(for: screenSize)
        let topPaddingTempText = WatchGlobalUIConfig.CountdownActivatedScreen.topPaddingTempText(for: screenSize)
        let timerFontSize = WatchGlobalUIConfig.CountdownActivatedScreen.timerFontSize(for: screenSize)
        let temperatureFontSize = WatchGlobalUIConfig.CountdownActivatedScreen.temperatureFontSize(for: screenSize)
        let temperatureIconSize = WatchGlobalUIConfig.CountdownActivatedScreen.temperatureIconSize(for: screenSize)
        let dividerLine1TopPadding = WatchGlobalUIConfig.CountdownActivatedScreen.dividerLine1TopPadding(for: screenSize)
        let dividerLine1BottomPadding = WatchGlobalUIConfig.CountdownActivatedScreen.dividerLine1BottomPadding(for: screenSize)
        let dividerLine2TopPadding = WatchGlobalUIConfig.CountdownActivatedScreen.dividerLine2TopPadding(for: screenSize)
        let dividerLine2BottomPadding = WatchGlobalUIConfig.CountdownActivatedScreen.dividerLine2BottomPadding(for: screenSize)
        let dividerLine3TopPadding = WatchGlobalUIConfig.CountdownActivatedScreen.dividerLine3TopPadding(for: screenSize)
        let dividerLine3BottomPadding = WatchGlobalUIConfig.CountdownActivatedScreen.dividerLine3BottomPadding(for: screenSize)
        let paddingBetweenHeartRateAndBarChart = WatchGlobalUIConfig.CountdownActivatedScreen.paddingBetweenHeartRateAndBarChart(for: screenSize)

        GeometryReader { geo in
            ZStack(alignment: .top) {
                // Single solid black background
                Color.black

                // Foreground content
                VStack(spacing: 0) {
                    // Timer (Countup Mode)
                    Text(formatTimer(Int(workoutManager.elapsedTime), isCountup: true))
                        .font(.system(size: timerFontSize, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, topPaddingTimer)

                    // First divider line
                    Rectangle()
                        .fill(Color.white)
                        .frame(height: 1)
                        .padding(.bottom, dividerLine1BottomPadding)
                        .padding(.top, dividerLine1TopPadding)

                    // Temperature Section
                    VStack(spacing: 4) {
                        Text("Temp.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        HStack(spacing: 6) {
                            Image(systemName: activityIcon)
                                .foregroundColor(activityColor)
                                .font(.system(size: temperatureIconSize, weight: .regular))
                            Text(sessionTemperatureString)
                                .font(.system(size: temperatureFontSize, weight: .semibold))
                                .foregroundColor(activityColor)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, topPaddingTempText)
                    
                    // Second divider line
                    Rectangle()
                        .fill(Color.white)
                        .frame(height: 1)
                        .padding(.top, dividerLine2TopPadding)
                        .padding(.bottom, dividerLine2BottomPadding)
                    
                    // Heart Rate Section (matching CountdownActivatedScreen exactly)
                    HStack(spacing: 8) {
                        if healthKitManager.isHeartRatePermissionGranted, let hr = heartRate, hr > 0 {
                            if #available(watchOS 11.0, *) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                    .symbolEffect(.breathe.pulse.byLayer, options: .repeat(.continuous))
                            } else {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                            }
                            Text("\(hr) BPM")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "heart.slash")
                                .foregroundColor(.gray)
                            Text("-- BPM")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, paddingBetweenHeartRateAndBarChart)
                    
                    // Heart Rate Bar Chart (matching CountdownActivatedScreen exactly)
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(0..<5, id: \.self) { idx in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(hrBoxColors[idx])
                                .frame(
                                    width: 22,
                                    height: hrBoxIndex(for: heartRate) == idx ? 28 : 8,
                                    alignment: .bottom
                                )
                                .animation(.easeInOut(duration: 0.4), value: hrBoxIndex(for: heartRate))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    Spacer()
                }
                .frame(width: geo.size.width, height: geo.size.height)
                
                // Stop button overlay in top-left corner (matching CountdownActivatedScreen)
                VStack {
                    HStack {
                        Button(action: {
                            #if DEBUG
                            print("Stop button tapped")
                            #endif
                            handleStopActivity()
                        }) {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: stopIconSize, weight: .medium))
                                .foregroundColor(waterLockManager.shouldDisableStopButton ? .gray : .red)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(waterLockManager.shouldDisableStopButton)
                        .padding(.top, stopIconTopCornerPadding)
                        .padding(.leading, stopIconTopCornerPadding)
                        
                        Spacer()
                    }
                    Spacer()
                }
            }
            .ignoresSafeArea()
        }
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
        .onAppear {
            setupActivityScreen()
        }
        .onDisappear {
            cleanupActivityScreen()
        }
    }
    
    // MARK: - Setup
    private func setupActivityScreen() {
        #if DEBUG
        print("🎬 ActivityStartedScreen: Setting up for \(sessionDataManager.activityType)")
        print("Workout manager isActive: \(workoutManager.isActive)")
        print("Workout elapsed time: \(workoutManager.elapsedTime)")
        print("HRArray count: \(sessionDataManager.HRArray.count)")
        #endif
        
        // Determine if this is a new session or resuming from pause
        let isResumingSession = workoutManager.isActive && workoutManager.elapsedTime > 0
        let plannedStartDate = sessionDataManager.activityStartDate ?? Date()
        
        // Start workout session if not already active
        if !workoutManager.isActive {
            #if DEBUG
            print("=== ACTIVITY STARTED SCREEN: Starting new workout session ===")
            #endif
            workoutManager.startWorkout(startDate: plannedStartDate)
            
            // Wait for workout session to be active before enabling Water Lock
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                #if DEBUG
                print("=== ACTIVITY STARTED SCREEN: Enabling Water Lock mode (delayed) ===")
                print("Workout manager isActive: \(self.workoutManager.isActive)")
                print("Workout state: \(self.workoutManager.workoutState)")
                #endif
                self.waterLockManager.enableWaterLock()
            }
        } else {
            // Workout session is already active, enable Water Lock immediately
            #if DEBUG
            print("=== ACTIVITY STARTED SCREEN: Workout already active, enabling Water Lock immediately ===")
            #endif
            waterLockManager.enableWaterLock()
        }
        
        // Only reset session tracking for brand new sessions, not when resuming
        if !isResumingSession {
            #if DEBUG
            print("=== ACTIVITY STARTED SCREEN: New session - resetting tracking ===")
            #endif
            // Preserve temp/time from Set Temperature / Use Last before reset clears them
            let preservedTimeSeconds = sessionDataManager.sessionTimeSeconds
            let preservedTempF = sessionDataManager.sessionTempF
            let preservedStartDate = sessionDataManager.activityStartDate ?? plannedStartDate
            sessionDataManager.resetSessionTracking()
            sessionDataManager.sessionTimeSeconds = preservedTimeSeconds
            sessionDataManager.sessionTempF = preservedTempF
            sessionDataManager.activityStartDate = preservedStartDate
            #if DEBUG
            print("Preserved sessionTempF: \(preservedTempF), sessionTimeSeconds: \(preservedTimeSeconds)")
            #endif
        } else {
            #if DEBUG
            print("=== ACTIVITY STARTED SCREEN: Resuming session - preserving data ===")
            print("Preserved HRArray count: \(sessionDataManager.HRArray.count)")
            print("Preserved elapsed time: \(workoutManager.elapsedTime)")
            #endif
        }

        // Always countup mode for stopwatch activities (set after reset so it is not overwritten)
        sessionDataManager.currentTimerMode = "Countup"
        sessionDataManager.originalCountdownTimeSeconds = 0
        
        // Start heart rate monitoring
        startHeartRateMonitoring()
        
        #if DEBUG
        print("✅ ActivityStartedScreen setup complete")
        #endif
    }
    
    // MARK: - Cleanup
    private func cleanupActivityScreen() {
        #if DEBUG
        print("🧹 ActivityStartedScreen: Cleaning up")
        #endif
        
        // Stop heart rate monitoring
        stopHeartRateMonitoring()
        
        // FORCE stop ALL HealthKit monitoring
        healthKitManager.forceStopAllHealthKitQueries()
        
        // End active session tracking
        backgroundTimerManager.endActiveSession()
        
        // Disable water lock
        waterLockManager.disableWaterLock()
        
        #if DEBUG
        print("✅ ActivityStartedScreen cleanup complete")
        #endif
    }
    
    // MARK: - Heart Rate Monitoring (every 5 seconds)
    private func startHeartRateMonitoring() {
        // Stop any existing timer
        heartRateTimer?.invalidate()
        heartRateSecondCounter = 0
        
        // Start new timer (fires every 1 second, but we only query HR every 5 seconds)
        heartRateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            heartRateSecondCounter += 1
            
            if heartRateSecondCounter >= 5 {
                heartRateSecondCounter = 0
                queryHeartRate()
            }
        }
        
        // Query immediately on start
        queryHeartRate()
        
        #if DEBUG
        print("❤️ Heart rate monitoring started (every 5 seconds)")
        #endif
    }
    
    private func stopHeartRateMonitoring() {
        heartRateTimer?.invalidate()
        heartRateTimer = nil
        
        #if DEBUG
        print("❤️ Heart rate monitoring stopped")
        #endif
    }
    
    private func queryHeartRate() {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: hrType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, error in
            guard let sample = results?.first as? HKQuantitySample else { return }
            
            let hr = Int(sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
            
            DispatchQueue.main.async {
                self.heartRate = hr
                
                // Store heart rate in session data
                self.sessionDataManager.addHeartRate(hr)
                
                #if DEBUG
                print("❤️ Heart rate: \(hr) BPM, Total samples: \(self.sessionDataManager.HRArray.count)")
                #endif
            }
        }
        
        HKHealthStore().execute(query)
    }
    
    // MARK: - Stop Activity
    private func handleStopActivity() {
        #if DEBUG
        print("⏹️ Stop button pressed")
        #endif
        
        // IMMEDIATELY clean up all timers
        stopHeartRateMonitoring()
        backgroundTimerManager.completelyStopAllTimers()
        
        // Set both epic time and accumulated time (they're the same for Sauna/Cold Shower)
        let elapsedTime = Int(workoutManager.elapsedTime)
        sessionDataManager.epicTime = max(0, elapsedTime)
        sessionDataManager.accumulatedSessionTime = max(0, elapsedTime)
        
        #if DEBUG
        print("✅ Set epicTime and accumulatedSessionTime to: \(elapsedTime) seconds")
        #endif
        
        // Pause workout session
        if workoutManager.isActive && !workoutManager.isPaused {
            workoutManager.pauseWorkout()
        }
        
        // Navigate to pause screen
        navigationManager.goToScreen(.activityStoppedOrPaused)
    }
    
    // MARK: - Format Time
    private func formatTimer(_ totalSeconds: Int, isCountup: Bool) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    ActivityStartedScreen(navigationManager: NavigationManager())
        .environmentObject(SessionDataManager())
        .environmentObject(BackgroundTimerManager.shared)
        .environmentObject(WorkoutManager())
}
