//
//  CountdownActivatedScreen.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import SwiftUI
import WatchKit

struct CountdownActivatedScreen: View {
    // MARK: - Navigation
    @ObservedObject var navigationManager: NavigationManager
    let navigationSource: NavigationSource
    
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
    @State private var didPlayNotification: Bool = false
    
    // MARK: - Heart Rate State
    @State private var heartRate: Int?
    @State private var heartRateTimer: Timer?
    
    // MARK: - Progress Bar State
    @State private var showFlagBounce: [Bool] = [false, false, false, false, false]

    // Add navigation source tracking
    enum NavigationSource {
        case selectSession
        case setTemperature
    }

    // Progress Bar
    private let flagCheckpoints: [CGFloat] = [0.25, 0.5, 0.75, 1.0]
    private let flagIcons: [String] = ["flag", "flag", "flag", "flag.checkered"]

    // Colors
    private let progressGreen = Color(red: 50/255, green: 222/255, blue: 132/255)
    private let progressGray = Color(red: 165/255, green: 165/255, blue: 165/255)
    private let hrBoxColors: [Color] = [
        Color(hex: "#A5A5A5"),
        Color(hex: "#95E4FF"),
        Color(hex: "#32DE84"),
        Color(hex: "#F1A100"),
        Color(hex: "#FF6E65")
    ]

    // Heart Rate Bar Chart
    private func hrBoxIndex(for hr: Int?) -> Int {
        guard let hr = hr else { return 0 }
        switch hr {
        case ...60: return 0
        case 61...80: return 1
        case 81...100: return 2
        case 101...120: return 3
        default: return 4
        }
    }

    // MARK: - Timer/Temperature Sourcing
    private func getInitialTimerValue() -> Int {
        let seconds = sessionDataManager.sessionTimeSeconds
        return seconds > 0 ? seconds : 500
    }

    private func getTemperatureString() -> String {
        let tempF = sessionDataManager.sessionTempF
        guard tempF > 0 else { return "--" }
        return sessionDataManager.formatTempDisplayWithUnit(tempF: tempF)
    }

    private func parseTimeStringToSeconds(_ str: String) -> Int? {
        let parts = str.split(separator: ":")
        guard parts.count == 2,
              let min = Int(parts[0]),
              let sec = Int(parts[1]) else { return nil }
        return min * 60 + sec
    }
    
    // MARK: - Timer Display Logic
    private func getCurrentTimerDisplay() -> (value: Int, isCountup: Bool) {
        let elapsedTime = Int(workoutManager.elapsedTime)
        let countdownDuration = sessionDataManager.originalCountdownTimeSeconds
        
        if elapsedTime < countdownDuration {
            // Still in countdown phase
            let remainingTime = countdownDuration - elapsedTime
            return (remainingTime, false)
        } else {
            // In countup phase
            let countupTime = elapsedTime - countdownDuration
            return (countupTime, true)
        }
    }
    
    // Separate function to update timer mode without causing view update issues
    private func updateTimerMode() {
        let elapsedTime = Int(workoutManager.elapsedTime)
        let countdownDuration = sessionDataManager.originalCountdownTimeSeconds
        
        DispatchQueue.main.async {
            if elapsedTime < countdownDuration {
                self.workoutManager.timerMode = "countdown"
            } else {
                self.workoutManager.timerMode = "countup"
            }
        }
    }
    
    // Separate function to update session data
    private func updateSessionData() {
        DispatchQueue.main.async {
            self.sessionDataManager.accumulatedSessionTime = Int(self.workoutManager.elapsedTime)
        }
    }
    
    // Separate function to handle countdown to countup transition
    private func handleCountdownToCountupTransition() {
        let countdownDuration = sessionDataManager.originalCountdownTimeSeconds
        let elapsedTime = Int(workoutManager.elapsedTime)
        
        if elapsedTime == countdownDuration && !didPlayNotification {
            // Just transitioned to countup mode - play notification
            WKInterfaceDevice.current().play(.notification)
            WKInterfaceDevice.current().play(.success)
            didPlayNotification = true
            
            DispatchQueue.main.async {
                self.sessionDataManager.currentTimerMode = "Countup"
            }
        }
    }
    
    private func formatTimer(_ value: Int, isCountup: Bool) -> String {
        let absVal = abs(value)
        let min = absVal / 60
        let sec = absVal % 60
        let sign = isCountup ? "+" : "-"
        return String(format: "%@%d:%02d", sign, min, sec)
    }

    // MARK: - Progress
    private func progressFraction() -> CGFloat {
        let (_, isCountup) = getCurrentTimerDisplay()
        if isCountup { return 1.0 }
        
        let elapsedTime = Int(workoutManager.elapsedTime)
        let countdownDuration = sessionDataManager.originalCountdownTimeSeconds
        return CGFloat(elapsedTime) / CGFloat(countdownDuration)
    }
    
    private func handleStopSession() {
        #if DEBUG
        print("Session stopped via gesture")
        #endif
        
        // IMMEDIATELY clean up all timers
        cleanupAllTimers()
        backgroundTimerManager.completelyStopAllTimers()
        
        // Set epic time based on current timer state
        let (_, isCountup) = getCurrentTimerDisplay()
        if isCountup {
            let elapsedTime = Int(workoutManager.elapsedTime)
            let countdownDuration = sessionDataManager.originalCountdownTimeSeconds
            let epicTime = elapsedTime - countdownDuration
            sessionDataManager.epicTime = max(0, epicTime)
        } else {
            sessionDataManager.epicTime = 0
        }
        
        // Pause workout session
        if workoutManager.isActive && !workoutManager.isPaused {
            workoutManager.pauseWorkout()
        }
        
        // Navigate to pause screen
        navigationManager.goToScreen(.activityStoppedOrPaused)
    }

    // MARK: - Body
    var body: some View {
        // UI Config
        let screenSize = screenManager.currentScreenSize
        let screenHeight = WKInterfaceDevice.current().screenBounds.height

        // UI Config Variables
        let stopIconTopCornerPadding = WatchGlobalUIConfig.CountdownActivatedScreen.stopIconTopCornerPadding(for: screenSize)
        let stopIconSize = WatchGlobalUIConfig.CountdownActivatedScreen.stopIconSize(for: screenSize)
        let topPaddingTimer = WatchGlobalUIConfig.CountdownActivatedScreen.topPaddingTimer(for: screenSize)
        let topPaddingTempText = WatchGlobalUIConfig.CountdownActivatedScreen.topPaddingTempText(for: screenSize)
        let topPaddingForProgressContainer = WatchGlobalUIConfig.CountdownActivatedScreen.topPaddingForProgressContainer(for: screenSize)
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
                Color.black.ignoresSafeArea()

                // Foreground content
                VStack(spacing: 0) {
                    // Timer
                    let (timerValue, isCountup) = getCurrentTimerDisplay()
                    Text(formatTimer(timerValue, isCountup: isCountup))
                        .font(.system(size: timerFontSize, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, topPaddingTimer)

                    // Add a thin white line between the timer and the temperature
                    Rectangle()
                        .fill(Color.white)
                        .frame(height: 1)
                        .padding(.bottom, dividerLine1BottomPadding)
                        .padding(.top, dividerLine1TopPadding)

                    // Temperature
                    HStack() {
                        Image(systemName: "thermometer.snowflake")
                            .foregroundColor(Color(hex: "#7cddfc"))    // Blue
                            .font(.system(size: temperatureIconSize, weight: .regular))
                        Text(getTemperatureString())
                            .font(.system(size: temperatureFontSize, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, topPaddingTempText)

                    // Add a thin white line between the timer and the temperature
                    Rectangle()
                        .fill(Color.white)
                        .frame(height: 1)
                        .padding(.bottom, dividerLine2BottomPadding)
                        .padding(.top, dividerLine2TopPadding)

                    // Flags above Progress Bar
                    VStack(spacing: 2) {
                        let barWidth = geo.size.width * 0.95
                        // Progress Bar with overlayed flags
                        ZStack(alignment: .leading) {
                            // Gray bar
                            RoundedRectangle(cornerRadius: 4)
                                .fill(progressGray)
                                .frame(width: barWidth, height: 8)
                            // Green progress
                            RoundedRectangle(cornerRadius: 4)
                                .fill(progressGreen)
                                .frame(width: barWidth * progressFraction(), height: 8)
                                .animation(.linear(duration: 0.5), value: progressFraction())
                        }
                        .frame(width: barWidth, height: 8)
                        .overlay(
                            ZStack {
                                ForEach(0..<flagCheckpoints.count, id: \ .self) { idx in
                                    let icon = flagIcons[idx]
                                    let customValue: CGFloat = (icon == "flag") ? 2 : (icon == "flag.checkered" ? -1 : 0)
                                    let x = barWidth * flagCheckpoints[idx] + customValue
                                    if #available(watchOS 10.0, *) {
                                        Image(systemName: icon)
                                            .foregroundColor(progressFraction() >= flagCheckpoints[idx] ? progressGreen : progressGray)
                                            .symbolEffect(
                                                .bounce.up.byLayer,
                                                options: .nonRepeating,
                                                value: showFlagBounce[idx]
                                            )
                                            .frame(width: 20, height: 20)
                                            .offset(x: x - 10, y: -16)
                                    } else {
                                        Image(systemName: icon)
                                            .foregroundColor(progressFraction() >= flagCheckpoints[idx] ? progressGreen : progressGray)
                                            .frame(width: 20, height: 20)
                                            .offset(x: x - 10, y: -16)
                                    }
                                }
                            }, alignment: .leading
                        )
                        .padding(.bottom, 4)
                        .padding(.top, topPaddingForProgressContainer)   // Add "Adaptive" variable here
                    }
                    //.padding(.top, topPaddingForProgressContainer)   // Add "Adaptive" variable here

                    // Add a thin white line between the progress bar and the heart rate
                    Rectangle()
                        .fill(Color.white)
                        .frame(height: 1)
                        .padding(.bottom, dividerLine3BottomPadding)
                        .padding(.top, dividerLine3TopPadding)

                    // Heart Rate
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

                    // Add a thin white line between the heart rate and the heart rate bar chart
                    // Heart Rate Bar Chart
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(0..<5, id: \ .self) { idx in
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

                // Stop button overlay in top-left corner
                VStack {
                    HStack {
                        Button(action: {
                            #if DEBUG
                            print("Stop button tapped")
                            #endif
                            handleStopSession()
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
            .onAppear {
                #if DEBUG
                print("=== COUNTDOWN ACTIVATED SCREEN: onAppear started ===")
                print("Navigation source: \(navigationSource)")
                print("Workout manager isActive: \(workoutManager.isActive)")
                print("Session data manager accumulated time: \(sessionDataManager.accumulatedSessionTime)")
                print("Session data manager HR array count: \(sessionDataManager.HRArray.count)")
                #endif
                
                // Start workout session if not already active
                if !workoutManager.isActive {
                    #if DEBUG
                    print("=== COUNTDOWN ACTIVATED SCREEN: Starting workout session ===")
                    #endif
                    workoutManager.startWorkout()
                    
                    // Wait for workout session to be active before enabling Water Lock
                    // Use a small delay to ensure the workout session is fully started
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        #if DEBUG
                        print("=== COUNTDOWN ACTIVATED SCREEN: Enabling Water Lock mode (delayed) ===")
                        print("Workout manager isActive: \(self.workoutManager.isActive)")
                        print("Workout state: \(self.workoutManager.workoutState)")
                        #endif
                        self.waterLockManager.enableWaterLock()
                    }
                } else {
                    // Workout session is already active, enable Water Lock immediately
                    #if DEBUG
                    print("=== COUNTDOWN ACTIVATED SCREEN: Workout already active, enabling Water Lock immediately ===")
                    #endif
                    waterLockManager.enableWaterLock()
                }
                
                // Determine if this is a new session or continuing from pause
                // A new session is when we have no original countdown time set
                let isNewSession = sessionDataManager.originalCountdownTimeSeconds == 0
                
                #if DEBUG
                print("=== COUNTDOWN ACTIVATED SCREEN: Session Detection ===")
                print("HRArray.isEmpty: \(sessionDataManager.HRArray.isEmpty)")
                print("HRArray.count: \(sessionDataManager.HRArray.count)")
                print("originalCountdownTimeSeconds: \(sessionDataManager.originalCountdownTimeSeconds)")
                print("isNewSession: \(isNewSession)")
                print("=============================================")
                #endif
                
                if isNewSession {
                    #if DEBUG
                    print("=== COUNTDOWN ACTIVATED SCREEN: Resetting session tracking (new session) ===")
                    #endif
                    // This is a completely new session
                    sessionDataManager.resetSessionTracking()
                    // Set the original countdown time for new sessions
                    sessionDataManager.originalCountdownTimeSeconds = getInitialTimerValue()
                    #if DEBUG
                    print("=== COUNTDOWN ACTIVATED SCREEN: Set original countdown time: \(sessionDataManager.originalCountdownTimeSeconds) ===")
                    #endif
                } else {
                    #if DEBUG
                    print("=== COUNTDOWN ACTIVATED SCREEN: Continuing existing session ===")
                    print("Accumulated time: \(sessionDataManager.accumulatedSessionTime)")
                    print("HR array count: \(sessionDataManager.HRArray.count)")
                    print("Original countdown time: \(sessionDataManager.originalCountdownTimeSeconds)")
                    #endif
                    
                    // When continuing a session, preserve HRArray but reset epicTime for the new session
                    sessionDataManager.epicTime = 0
                }
                
                // Set the countdown duration if not already set
                if sessionDataManager.originalCountdownTimeSeconds == 0 {
                    sessionDataManager.originalCountdownTimeSeconds = getInitialTimerValue()
                }
                
                // Debug logging for timer state
                #if DEBUG
                print("=== COUNTDOWN ACTIVATED SCREEN TIMER SETUP ===")
                print("originalCountdownTimeSeconds: \(sessionDataManager.originalCountdownTimeSeconds)")
                print("workoutManager.elapsedTime: \(workoutManager.elapsedTime)")
                let (displayValue, isCountup) = getCurrentTimerDisplay()
                print("displayValue: \(displayValue), isCountup: \(isCountup)")
                print("=============================================")
                #endif
                
                let (_, isCurrentlyCountingUp) = getCurrentTimerDisplay()
                didPlayNotification = isCurrentlyCountingUp
                startTimer()
                // Start heart rate monitoring using shared manager
                startHeartRateMonitoring()
            }
            .onDisappear {
                #if DEBUG
                print("=== COUNTDOWN ACTIVATED: onDisappear triggered ===")
                #endif
                
                // Always cleanup when leaving screen
                cleanupAllTimers()
            }
            .onChange(of: backgroundTimerManager.isInBackground) { isInBackground in
                if !isInBackground {
                    // Screen has woken up, update timer display
                    updateTimerDisplayFromBackground()
                }
            }
        }
    }

    // MARK: - Timer Logic
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Update session data to match workout manager
            updateSessionData()
            
            // Update timer mode separately to avoid view update issues
            updateTimerMode()
            
            // Check if we just transitioned from countdown to countup
            handleCountdownToCountupTransition()
            
            self.checkFlagBounce()
        }
    }
    
    private func updateTimerDisplayFromBackground() {
        // Update session data to match workout manager
        updateSessionData()
        
        let (displayValue, isCountup) = getCurrentTimerDisplay()
        
        #if DEBUG
        print("🔄 Timer display updated from background - value: \(displayValue), mode: \(isCountup ? "countup" : "countdown")")
        #endif
    }
    
    private func checkFlagBounce() {
        let progress = progressFraction()
        for idx in 0..<flagCheckpoints.count {
            if !showFlagBounce[idx] && progress >= flagCheckpoints[idx] {
                DispatchQueue.main.async {
                    self.showFlagBounce[idx] = true
                }
            }
        }
    }

    // MARK: - Heart Rate Monitoring
    private func getAverageHeartRate() -> Int {
        let hrArray = sessionDataManager.HRArray
        
        // If we have 3 or more recent values, calculate average of the last 3
        if hrArray.count >= 3 {
            let lastThree = Array(hrArray.suffix(3))
            let validReadings = lastThree.filter { $0 > 0 } // Only count valid readings (> 0)
            
            if validReadings.count > 0 {
                let average = validReadings.reduce(0, +) / validReadings.count
                return average
            }
        }
        
        // If we have 1-2 recent values, use the most recent valid one
        if hrArray.count >= 1 {
            let lastValid = hrArray.reversed().first { $0 > 0 }
            if let valid = lastValid {
                return valid
            }
        }
        
        // Default to 80 BPM if no valid readings available
        return 80
    }
    
    private func startHeartRateMonitoring() {
        // Always use a timer-based approach to ensure consistent 1-second intervals
        heartRateTimer?.invalidate()
        heartRateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.healthKitManager.isHeartRatePermissionGranted {
                    // If we have a current heart rate reading, use it
                    if let currentHR = self.heartRate, currentHR > 0 {
                        self.sessionDataManager.HRArray.append(currentHR)
                        #if DEBUG
                        print("=== HEART RATE MONITORING: Added current HR value \(currentHR), total count: \(self.sessionDataManager.HRArray.count) ===")
                        #endif
                    } else {
                        // No current reading available, use average of recent values
                        let avgHR = self.getAverageHeartRate()
                        self.sessionDataManager.HRArray.append(avgHR)
                        #if DEBUG
                        print("=== HEART RATE MONITORING: Added average HR value \(avgHR), total count: \(self.sessionDataManager.HRArray.count) ===")
                        #endif
                    }
                } else {
                    // Permission denied - use average of recent values or default
                    let avgHR = self.getAverageHeartRate()
                    self.sessionDataManager.HRArray.append(avgHR)
                    #if DEBUG
                    print("=== FALLBACK HEART RATE: Added average HR value \(avgHR), total count: \(self.sessionDataManager.HRArray.count) ===")
                    #endif
                }
            }
        }
        
        // Start HealthKit monitoring to update the current heart rate value
        if healthKitManager.isHeartRatePermissionGranted {
                healthKitManager.startHeartRateMonitoring { heartRateValue in
                    DispatchQueue.main.async {
                        // Update the UI
                        self.heartRate = heartRateValue
                        
                        // ✅ CORRECTED CODE:
                        // No 'if let' is needed.
                        // We add a check for > 0 to avoid saving invalid data.
                        if heartRateValue > 0 {
                            self.workoutManager.addHeartRateData(heartRateValue, timestamp: Date())
                        }
                    }
                }
            }
    }

    // Add to CountdownActivatedScreen.swift
    private func cleanupAllTimers() {
        #if DEBUG
        print("=== COUNTDOWN ACTIVATED: Cleaning up all timers and background processes ===")
        #endif
        
        // Stop UI timer
        timer?.invalidate()
        timer = nil
        
        // CRITICAL: Stop heart rate timer explicitly
        heartRateTimer?.invalidate()
        heartRateTimer = nil
        #if DEBUG
        print("=== COUNTDOWN ACTIVATED: Heart rate timer stopped ===")
        #endif
        
        // FORCE stop ALL HealthKit monitoring
        healthKitManager.forceStopAllHealthKitQueries()
        
        // End active session tracking
        backgroundTimerManager.endActiveSession()
        
        // Disable water lock
        waterLockManager.disableWaterLock()
        
        #if DEBUG
        print("=== COUNTDOWN ACTIVATED: All timers and background processes cleaned up ===")
        #endif
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    CountdownActivatedScreen(navigationManager: NavigationManager(), navigationSource: .selectSession)
        .environmentObject(SessionDataManager())
        .environmentObject(BackgroundTimerManager.shared)
} 