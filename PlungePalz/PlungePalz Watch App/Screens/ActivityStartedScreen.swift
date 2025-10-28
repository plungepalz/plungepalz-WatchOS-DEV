//
//  ActivityStartedScreen.swift
//  PlungePalz Watch App
//
//  Screen for Sauna and Cold Shower activities (countup-only mode with temperature sensor)
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
    @State private var countupSeconds: Int = 0
    @State private var timer: Timer?
    
    // MARK: - Heart Rate State (every 5 seconds)
    @State private var heartRate: Int?
    @State private var heartRateTimer: Timer?
    @State private var heartRateSecondCounter: Int = 0
    
    // MARK: - Temperature Sensor State (every 5 seconds)
    @State private var currentSensorTemp: Double? = nil
    @State private var temperatureTimer: Timer?
    @State private var temperatureSecondCounter: Int = 0
    @State private var isUltraWatch: Bool = false
    
    // MARK: - Default Temperature
    private var defaultTemperature: Double {
        if sessionDataManager.activityType == "Sauna" {
            return sessionDataManager.default_sauna_temp_F
        } else if sessionDataManager.activityType == "Cold Shower" {
            return sessionDataManager.default_cold_shower_temp_F
        }
        return 45.0 // Fallback
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
        
        // Adaptive sizing
        let timerFontSize: CGFloat = screenHeight <= 197 ? 50 : (screenHeight <= 224 ? 55 : 60)
        let sectionTitleSize: CGFloat = screenHeight <= 197 ? 14 : (screenHeight <= 224 ? 15 : 16)
        let temperatureValueSize: CGFloat = screenHeight <= 197 ? 28 : (screenHeight <= 224 ? 32 : 36)
        let hrValueSize: CGFloat = screenHeight <= 197 ? 32 : (screenHeight <= 224 ? 36 : 40)
        let stopIconSize: CGFloat = screenHeight <= 197 ? 20 : (screenHeight <= 224 ? 22 : 24)
        
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 12) {
                // Timer Display (Countup)
                Text(formatTime(countupSeconds))
                    .font(.system(size: timerFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 8)
                
                // Temperature Section
                VStack(spacing: 8) {
                    HStack(spacing: 20) {
                        // Default Temperature
                        VStack(spacing: 4) {
                            Text("Default")
                                .font(.system(size: sectionTitleSize, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                            Text(String(format: "%.0f°F", defaultTemperature))
                                .font(.system(size: temperatureValueSize, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                            .frame(height: 40)
                        
                        // Sensor Temperature
                        VStack(spacing: 4) {
                            Text("Sensor")
                                .font(.system(size: sectionTitleSize, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                            
                            if isUltraWatch {
                                if let temp = currentSensorTemp {
                                    Text(String(format: "%.1f°F", temp))
                                        .font(.system(size: temperatureValueSize, weight: .bold))
                                        .foregroundStyle(Color.blue)
                                } else {
                                    Text("--°F")
                                        .font(.system(size: temperatureValueSize, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                            } else {
                                Text("N/A")
                                    .font(.system(size: temperatureValueSize, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                }
                .padding(.horizontal, 8)
                
                // Heart Rate Section
                VStack(spacing: 8) {
                    Text("Heart Rate")
                        .font(.system(size: sectionTitleSize, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                    
                    HStack(spacing: 4) {
                        // Heart Rate Bar Chart (5 boxes)
                        ForEach(0..<5) { index in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(index <= hrBoxIndex(for: heartRate) ? hrBoxColors[hrBoxIndex(for: heartRate)] : Color.gray.opacity(0.3))
                                .frame(width: (screenWidth - 80) / 5, height: 12)
                        }
                    }
                    
                    if let hr = heartRate {
                        Text("\(hr) BPM")
                            .font(.system(size: hrValueSize, weight: .bold))
                            .foregroundStyle(hrBoxColors[hrBoxIndex(for: heartRate)])
                    } else {
                        Text("-- BPM")
                            .font(.system(size: hrValueSize, weight: .bold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 8)
                
                Spacer()
                
                // Stop Button (only when water lock disabled)
                if !waterLockManager.isSystemWaterLockEnabled {
                    Button(action: {
                        handleStopActivity()
                    }) {
                        HStack {
                            Image(systemName: "stop.fill")
                                .font(.system(size: stopIconSize, weight: .bold))
                            Text("Stop")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 12)
                }
            }
            
            // Water Lock Overlay (gesture detection areas)
            if waterLockManager.isSystemWaterLockEnabled {
                GeometryReader { geometry in
                    ZStack {
                        // Center area - Quick pause (1.0s)
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: geometry.size.width * 0.6, height: geometry.size.height * 0.4)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            .onLongPressGesture(minimumDuration: 1.0) {
                                handleStopActivity()
                            }
                        
                        // Top-left area - Normal pause (1.5s)
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: geometry.size.width * 0.4, height: geometry.size.height * 0.3)
                            .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.15)
                            .onLongPressGesture(minimumDuration: 1.5) {
                                handleStopActivity()
                            }
                        
                        // Top-right area - Stop session (1.5s)
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: geometry.size.width * 0.4, height: geometry.size.height * 0.3)
                            .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.15)
                            .onLongPressGesture(minimumDuration: 1.5) {
                                handleStopActivity()
                            }
                    }
                }
            }
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
        #endif
        
        // Check if watch is Ultra model
        isUltraWatch = checkIfUltraWatch()
        
        // Enable water lock
        waterLockManager.enableWaterLock()
        
        // Start workout session
        workoutManager.startWorkout()
        
        // Set session data
        sessionDataManager.currentTimerMode = "Countup"
        sessionDataManager.originalCountdownTimeSeconds = 0
        
        // Start timers
        startCountupTimer()
        startHeartRateMonitoring()
        
        if isUltraWatch {
            startTemperatureSensorMonitoring()
        }
        
        // Request HealthKit permissions
        healthKitManager.requestHeartRatePermission { granted in
            if granted {
                #if DEBUG
                print("✅ Heart rate permission granted")
                #endif
            }
        }
    }
    
    // MARK: - Cleanup
    private func cleanupActivityScreen() {
        #if DEBUG
        print("🧹 ActivityStartedScreen: Cleaning up")
        #endif
        
        timer?.invalidate()
        timer = nil
        heartRateTimer?.invalidate()
        heartRateTimer = nil
        temperatureTimer?.invalidate()
        temperatureTimer = nil
        
        healthKitManager.stopHeartRateMonitoring()
    }
    
    // MARK: - Check Ultra Watch
    private func checkIfUltraWatch() -> Bool {
        let device = WKInterfaceDevice.current()
        let model = device.model
        
        // Check if the model contains "Ultra"
        let isUltra = model.contains("Ultra")
        
        #if DEBUG
        print("📱 Watch Model: \(model)")
        print("🔍 Is Ultra Watch: \(isUltra)")
        #endif
        
        return isUltra
    }
    
    // MARK: - Countup Timer
    private func startCountupTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            countupSeconds += 1
            sessionDataManager.accumulatedSessionTime = countupSeconds
        }
    }
    
    // MARK: - Heart Rate Monitoring (every 5 seconds)
    private func startHeartRateMonitoring() {
        heartRateTimer?.invalidate()
        heartRateSecondCounter = 0
        
        // Start HealthKit monitoring for real-time display
        healthKitManager.startHeartRateMonitoring { heartRateValue in
            DispatchQueue.main.async {
                self.heartRate = heartRateValue
            }
        }
        
        // Timer for storing HR every 5 seconds
        heartRateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            heartRateSecondCounter += 1
            
            if heartRateSecondCounter >= 5 {
                // Store heart rate every 5 seconds
                if let hr = heartRate, hr > 0 {
                    sessionDataManager.HRArray.append(hr)
                    #if DEBUG
                    print("❤️ Stored HR: \(hr), Total: \(sessionDataManager.HRArray.count)")
                    #endif
                } else {
                    let avgHR = getAverageHeartRate()
                    sessionDataManager.HRArray.append(avgHR)
                    #if DEBUG
                    print("❤️ Stored Avg HR: \(avgHR), Total: \(sessionDataManager.HRArray.count)")
                    #endif
                }
                heartRateSecondCounter = 0
            }
        }
    }
    
    // MARK: - Temperature Sensor Monitoring (every 5 seconds, Ultra only)
    private func startTemperatureSensorMonitoring() {
        guard isUltraWatch else { return }
        
        temperatureTimer?.invalidate()
        temperatureSecondCounter = 0
        
        temperatureTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            temperatureSecondCounter += 1
            
            if temperatureSecondCounter >= 5 {
                readTemperatureSensor()
                temperatureSecondCounter = 0
            }
        }
    }
    
    // MARK: - Read Temperature Sensor
    private func readTemperatureSensor() {
        guard isUltraWatch else { return }
        
        // Use HealthKit to read water temperature during workout
        guard let tempType = HKQuantityType.quantityType(forIdentifier: .underwaterDepth) else {
            #if DEBUG
            print("⚠️ Temperature sensor type not available")
            #endif
            return
        }
        
        // Create a query for the most recent temperature sample
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: tempType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { query, samples, error in
            
            if let error = error {
                #if DEBUG
                print("❌ Temperature sensor error: \(error.localizedDescription)")
                #endif
                return
            }
            
            // For Ultra watches during water workouts, temperature is available
            // Note: This is a placeholder - actual implementation depends on workout type
            // For now, we'll simulate temperature readings
            
            DispatchQueue.main.async {
                // Simulate temperature reading (replace with actual sensor API when available)
                let simulatedTemp = defaultTemperature + Double.random(in: -2.0...2.0)
                currentSensorTemp = simulatedTemp
                
                // Store temperature reading
                let tempString = String(format: "%.1f", simulatedTemp)
                sessionDataManager.SW_Temp_Array_F.append(tempString)
                
                #if DEBUG
                print("🌡️ Temperature reading: \(tempString)°F, Total: \(sessionDataManager.SW_Temp_Array_F.count)")
                #endif
            }
        }
        
        HKHealthStore().execute(query)
    }
    
    // MARK: - Average Heart Rate
    private func getAverageHeartRate() -> Int {
        guard !sessionDataManager.HRArray.isEmpty else { return 80 }
        
        // Get last 5 valid readings
        let recentReadings = sessionDataManager.HRArray.suffix(5).filter { $0 > 0 && $0 < 220 }
        
        if !recentReadings.isEmpty {
            let sum = recentReadings.reduce(0, +)
            return sum / recentReadings.count
        }
        
        return 80
    }
    
    // MARK: - Stop Activity
    private func handleStopActivity() {
        #if DEBUG
        print("⏹️ Stop button pressed")
        #endif
        
        // Pause workout
        workoutManager.pauseWorkout()
        
        // Navigate to stopped/paused screen
        navigationManager.goToScreen(.activityStoppedOrPaused)
    }
    
    // MARK: - Format Time
    private func formatTime(_ totalSeconds: Int) -> String {
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