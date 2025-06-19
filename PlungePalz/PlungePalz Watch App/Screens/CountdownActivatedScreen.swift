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
    
    // MARK: - Screen Management
    @StateObject private var screenManager = WatchScreenManager()
    
    // MARK: - Water Lock Management
    @StateObject private var waterLockManager = WaterLockManager.shared
    
    // MARK: - Timer State
    @State private var timer: Timer?
    @State private var timerValue: Int = 0
    @State private var totalDuration: Int = 0
    @State private var isCountingUp: Bool = false
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
        switch navigationSource {
        case .selectSession:
            // Use last session time from API
            if let last = sessionDataManager.lastSessionData,
               let timeStr = last["lastSessionTimeSet"],
               let seconds = parseTimeStringToSeconds(timeStr) {
                return seconds
            }
            return 500 // Default fallback
        case .setTemperature:
            // Use time set in SetTimerScreen
            if let last = sessionDataManager.lastSessionData,
               let timeStr = last["lastSessionTimeSet"],
               let seconds = parseTimeStringToSeconds(timeStr) {
                return seconds
            }
            return 500 // Default fallback
        }
    }

    private func getTemperatureString() -> String {
        if let last = sessionDataManager.lastSessionData,
           let tempStr = last["lastSessionWaterTemp"],
           let temp = Double(tempStr),
           let unit = last["unitOfMeasure"] {
            
            // If unit is Metric, convert from stored Fahrenheit to Celsius
            if unit == "Metric" {
                let celsius = (temp - 32) * 5 / 9
                return String(format: "%.1f °C", celsius)
            }
            
            // Otherwise display as Fahrenheit
            return String(format: "%.1f °F", temp)
        }
        return "45.4 °F" // Default fallback
    }

    private func parseTimeStringToSeconds(_ str: String) -> Int? {
        let parts = str.split(separator: ":")
        guard parts.count == 2,
              let min = Int(parts[0]),
              let sec = Int(parts[1]) else { return nil }
        return min * 60 + sec
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
        if isCountingUp { return 1.0 }
        return 1.0 - CGFloat(timerValue) / CGFloat(totalDuration)
    }
    
    private func handleStopSession() {
        print("Session stopped via gesture")
        // Set epic time (if in countup mode, it's timerValue; else 0)
        sessionDataManager.epicTime = isCountingUp ? timerValue : 0
        // Stop timers
        timer?.invalidate()
        heartRateTimer?.invalidate()
        // Navigate to pause screen (same as pause for now)
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
                    Text(formatTimer(timerValue, isCountup: isCountingUp))
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
                        if let hr = heartRate {
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
                            Text("No HR")
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
                            print("Stop button tapped")
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
                // Only reset session tracking if we don't have any existing session data
                // This prevents resetting when continuing from a paused session
                if sessionDataManager.accumulatedSessionTime == 0 && sessionDataManager.HRArray.isEmpty {
                    // This is a completely new session
                    sessionDataManager.resetSessionTracking()
                    // Set the original countdown time for new sessions
                    sessionDataManager.originalCountdownTimeSeconds = getInitialTimerValue()
                }
                
                // Timer setup
                totalDuration = sessionDataManager.originalCountdownTimeSeconds > 0 ? 
                    sessionDataManager.originalCountdownTimeSeconds : getInitialTimerValue()
                
                // Restore timer state from global properties
                let elapsed = sessionDataManager.accumulatedSessionTime
                if sessionDataManager.currentTimerMode == "Countdown" && elapsed < totalDuration {
                    // Still in countdown mode
                    timerValue = totalDuration - elapsed
                    isCountingUp = false
                } else {
                    // In countup mode or countdown finished
                    timerValue = elapsed - totalDuration
                    isCountingUp = true
                    sessionDataManager.currentTimerMode = "Countup"
                }
                
                // Debug logging for timer state restoration
                print("=== COUNTDOWN ACTIVATED SCREEN TIMER RESTORATION ===")
                print("originalCountdownTimeSeconds: \(sessionDataManager.originalCountdownTimeSeconds)")
                print("currentTimerMode: \(sessionDataManager.currentTimerMode)")
                print("accumulatedSessionTime: \(sessionDataManager.accumulatedSessionTime)")
                print("totalDuration: \(totalDuration)")
                print("timerValue: \(timerValue)")
                print("isCountingUp: \(isCountingUp)")
                print("==================================================")
                
                didPlayNotification = isCountingUp
                startTimer()
                // Heart rate setup
                startHeartRateUpdates()
                // Check system water lock state
                waterLockManager.checkSystemWaterLockState()
                // Set up periodic water lock state checking
                Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                    waterLockManager.checkSystemWaterLockState()
                }
            }
            .onDisappear {
                // Stop timers
                timer?.invalidate()
                heartRateTimer?.invalidate()
            }
        }
    }

    // MARK: - Timer Logic
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if !isCountingUp {
                if timerValue > 0 {
                    timerValue -= 1
                    sessionDataManager.accumulatedSessionTime += 1
                    checkFlagBounce()
                } else if !didPlayNotification {
                    isCountingUp = true
                    timerValue = 0
                    sessionDataManager.currentTimerMode = "Countup"
                    WKInterfaceDevice.current().play(.notification)
                    didPlayNotification = true
                }
            } else {
                timerValue += 1
                sessionDataManager.accumulatedSessionTime += 1
                checkFlagBounce()
            }
        }
    }
    private func checkFlagBounce() {
        let progress = progressFraction()
        for idx in 0..<flagCheckpoints.count {
            if !showFlagBounce[idx] && progress >= flagCheckpoints[idx] {
                showFlagBounce[idx] = true
            }
        }
    }

    // MARK: - Heart Rate Logic (Simulated)
    private func startHeartRateUpdates() {
        heartRateTimer?.invalidate()
        heartRateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Simulate heart rate update (replace with HealthKit in real app)
            let hr = Int.random(in: 55...130)
            heartRate = hr
            sessionDataManager.HRArray.append(hr)
        }
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
} 
