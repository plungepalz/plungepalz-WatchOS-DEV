//
//  SessionRecapScreen.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import SwiftUI

struct SessionRecapScreen: View {
    @EnvironmentObject var sessionDataManager: SessionDataManager
    @StateObject private var screenManager = WatchScreenManager()
    @ObservedObject var navigationManager: NavigationManager
    
    // API Status Management
    @StateObject private var apiManager = APIs.shared
    @State private var apiStatus: String = "Calling" // "Calling", "Success", "Retrying", "Failed"
    @State private var apiTimer: Timer?
    // Test variables for simulating API results
    @State private var API_Success: Bool = false
    @State private var RetryingResultSuccess_1: Bool = false
    @State private var RetryingResultSuccess_2: Bool = false
    @State private var RetryingResultSuccess_3: Bool = false
    @State private var retryAttempt: Int = 0
    @State private var retryProgress: CGFloat = 1.0
    @State private var retryProgressTimer: Timer?
    
    // Global payload for API request
    private var apiPayload: [String: Any] {
        let userId = UserDefaults.standard.string(forKey: "userId") ?? "unknown"
        let originalSetTime = sessionDataManager.originalCountdownTimeSeconds
        let totalTime = calculateTotalTime()
        let epicTime = sessionDataManager.epicTime ?? 0
        let temp_F = getSessionTemperature()
        let hr_array = sessionDataManager.HRArray
        let localTime = getFormattedTimeLocal()
        let d_id = getDeviceName()
        let d_mv = getDeviceModelVersion()
        let d_fv = getDeviceFirmwareVersion()
        let d_i = getDeviceIdentifier()
        let timestamp_utc = getFormattedTimeUTC()

        return [
            "d_id": d_id,
            "d_fv": d_fv,
            "d_mv": d_mv,
            "d_i": d_i,
            "user_id": userId,
            "original_set_time": originalSetTime,
            "total_time": totalTime,
            "epic_time": epicTime,
            "temp_f": temp_F,
            "hr_array": hr_array,
            "timestamp_utc": timestamp_utc,
            "localTime": localTime
        ]
    }
    
    // Helper functions
    private func getTimeString() -> String {
        let totalSeconds = sessionDataManager.accumulatedSessionTime
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    private func getTemperatureString() -> String {
        if let last = sessionDataManager.lastSessionData,
           let tempStr = last["lastSessionWaterTemp"],
           let temp = Double(tempStr),
           let unit = last["unitOfMeasure"] {
            if unit == "Metric" {
                let celsius = (temp - 32) * 5 / 9
                return String(format: "%.1f °C", celsius)
            }
            return String(format: "%.1f °F", temp)
        }
        return "--"
    }
    private func getMaxHR() -> String {
        if let max = sessionDataManager.HRArray.max() {
            return "\(max) BPM"
        }
        return "--"
    }
    private func getMinHR() -> String {
        if let min = sessionDataManager.HRArray.min() {
            return "\(min) BPM"
        }
        return "--"
    }
    private func getAvgHR() -> String {
        let arr = sessionDataManager.HRArray
        if !arr.isEmpty {
            let avg = Double(arr.reduce(0, +)) / Double(arr.count)
            return String(format: "%.0f BPM", avg)
        }
        return "--"
    }
    private func getEpicTime() -> String {
        if let epic = sessionDataManager.epicTime, epic > 0 {
            let min = epic / 60
            let sec = epic % 60
            return String(format: "+%d:%02d", min, sec)
        }
        return "+0:00"
    }
    
    // API Functions
    private func makeAPIPostRequest() {
        print("=== STARTING API POST REQUEST ===")
        apiStatus = "Calling"
        retryAttempt = 0
        retryProgress = 1.0
        retryProgressTimer?.invalidate()
        
        performAPICall()
    }
    
    private func performAPICall() {
        // Create request using APIs helper
        guard let request = apiManager.createRequest(
            url: apiManager.saveSessionEndpoint,
            method: "POST",
            body: apiPayload
        ) else {
            print("Failed to create request")
            apiStatus = "Failed"
            savePendingRequest()
            return
        }
        
        // Make the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                let result = self.apiManager.handleAPIResponse(response as? HTTPURLResponse, data: data, error: error)
                
                if result.success {
                    // Success
                    self.apiStatus = "Success"
                    print("=== API POST SUCCESS ===")
                } else {
                    // Failure
                    print("API Error: \(result.message)")
                    self.handleAPIFailure()
                }
            }
        }.resume()
    }
    
    private func handleAPIFailure() {
        retryAttempt += 1
        print("Retry attempt: \(retryAttempt)")
        
        if retryAttempt < 3 {
            apiStatus = "Retrying"
            startRetryProgressBar()
            print("=== API POST RETRYING (\(retryAttempt)) ===")
            
            // Retry after 15 seconds
            apiTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { _ in
                DispatchQueue.main.async {
                    self.performAPICall()
                }
            }
        } else {
            apiStatus = "Failed"
            retryProgressTimer?.invalidate()
            print("=== API POST FAILED AFTER 3 RETRIES ===")
            savePendingRequest()
        }
    }

    private func startRetryProgressBar() {
        retryProgress = 1.0
        retryProgressTimer?.invalidate()
        let totalDuration: CGFloat = 15.0
        let interval: CGFloat = 0.05
        var elapsed: CGFloat = 0.0
        retryProgressTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            elapsed += interval
            let progress = max(0.0, 1.0 - (elapsed / totalDuration))
            DispatchQueue.main.async {
                self.retryProgress = progress
            }
            if elapsed >= totalDuration || self.apiStatus != "Retrying" {
                timer.invalidate()
            }
        }
    }

    private var isAPIBusy: Bool {
        apiStatus == "Calling" || apiStatus == "Retrying"
    }

    private func getBorderColor() -> Color {
        switch apiStatus {
        case "Calling":
            return Color.yellow
        case "Success":
            return Color.green
        case "Retrying":
            return Color.orange
        case "Failed":
            return Color.red
        default:
            return Color.clear
        }
    }

    var body: some View {
        // Screen Size
        let screenSize = screenManager.currentScreenSize
        let screenWidth = WKInterfaceDevice.current().screenBounds.width
        let screenHeight = WKInterfaceDevice.current().screenBounds.height

        // Global UI Config Variables
        let optionIconSize = WatchGlobalUIConfig.SessionRecapScreen.optionIconSize(for: screenSize)
        let optionTitleFontSize = WatchGlobalUIConfig.SessionRecapScreen.optionTitleFontSize(for: screenSize)
        let optionSubtitleFontSize = WatchGlobalUIConfig.SessionRecapScreen.optionSubtitleFontSize(for: screenSize)
        let iconTitleGap = WatchGlobalUIConfig.SessionRecapScreen.iconTitleGap(for: screenSize)
        let optionContainerTopPadding = WatchGlobalUIConfig.SessionRecapScreen.optionContainerTopPadding(for: screenSize)
        let optionContainerWidthRatio = WatchGlobalUIConfig.SessionRecapScreen.optionContainerWidthRatio(for: screenSize)
        let optionContainerHeightRatio = WatchGlobalUIConfig.SessionRecapScreen.optionContainerHeightRatio(for: screenSize)
        let optionContainerWidth = screenWidth * optionContainerWidthRatio
        let optionContainerHeight = screenHeight * optionContainerHeightRatio
        let optionContainerHorizontalPadding = WatchGlobalUIConfig.SessionRecapScreen.optionContainerHorizontalPadding(for: screenSize)
        let optionContainerVerticalPadding = WatchGlobalUIConfig.SessionRecapScreen.optionContainerVerticalPadding(for: screenSize)
        let retryingProgressBarPaddingVerticalOffsetRatio = WatchGlobalUIConfig.SessionRecapScreen.retryingProgressBarPaddingVerticalOffsetRatio(for: screenSize)

        // Hardcoded UI Constants
        let optionContainerCornerRadius: CGFloat = 12
        let optionContainerBackground = Color.black
        let titleColor = Color.white
        let iconColor = Color.white
        let waterTempColor = Color(hex: "#8EC2FF")
        let epicTimeColor = Color.yellow

        // Conditionally calculate the ideal border radius for the rounded rectangle
        let borderRadius: CGFloat = screenHeight <= 197
            ? screenWidth * 0.18
            : (screenHeight <= 223 ? screenWidth * 0.25 
            : (screenHeight <= 224 ? screenWidth * 0.2 
            : (screenHeight <= 248 ? screenWidth * 0.25 : screenWidth * 0.27)))

        ZStack {
            Color(red: 0/255, green: 116/255, blue: 255/255)
                .ignoresSafeArea()
            
            // Rounded border based on API status
            RoundedRectangle(cornerRadius: borderRadius, style: .continuous)
                .stroke(getBorderColor(), lineWidth: 10)
                .ignoresSafeArea()
            
            // Retrying progress bar (absolute top overlay)
            if apiStatus == "Retrying" {
                GeometryReader { geo in
                    let barHeight: CGFloat = 6
                    let barWidth = geo.size.width * retryProgress
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: barWidth, height: barHeight)
                        .cornerRadius(3)
                        .position(x: geo.size.width / 2, y: barHeight / 2)
                }
                .frame(height: 6)
                .padding(.top, -(screenHeight * retryingProgressBarPaddingVerticalOffsetRatio))
                //.ignoresSafeArea(edges: .top)
            }
            
            ScrollView {
                VStack(spacing: 14) {
                    ActionOptionContainer(
                        iconName: "timer",
                        iconSize: optionIconSize,
                        iconTitleGap: iconTitleGap,
                        title: "Total Time",
                        subtitle: getTimeString(),
                        titleColor: titleColor,
                        iconColor: iconColor,
                        backgroundColor: optionContainerBackground,
                        height: optionContainerHeight,
                        width: optionContainerWidth,
                        titleFontSize: optionTitleFontSize,
                        subtitleFontSize: optionSubtitleFontSize,
                        cornerRadius: optionContainerCornerRadius,
                        horizontalPadding: optionContainerHorizontalPadding,
                        verticalPadding: optionContainerVerticalPadding
                    ) {
                        navigationManager.goToHome()
                    }
                    ActionOptionContainer(
                        iconName: "thermometer.and.liquid.waves.snowflake",
                        iconSize: optionIconSize,
                        iconTitleGap: iconTitleGap,
                        title: "Water Temp",
                        subtitle: getTemperatureString(),
                        titleColor: waterTempColor,
                        iconColor: waterTempColor,
                        backgroundColor: optionContainerBackground,
                        height: optionContainerHeight,
                        width: optionContainerWidth,
                        titleFontSize: optionTitleFontSize,
                        subtitleFontSize: optionSubtitleFontSize,
                        cornerRadius: optionContainerCornerRadius,
                        horizontalPadding: optionContainerHorizontalPadding,
                        verticalPadding: optionContainerVerticalPadding
                    ) {
                        navigationManager.goToHome()
                    }
                    ActionOptionContainer(
                        iconName: "arrow.up.heart",
                        iconSize: optionIconSize,
                        iconTitleGap: iconTitleGap,
                        title: "Max HR",
                        subtitle: getMaxHR(),
                        titleColor: Color(red: 1.0, green: 0.36, blue: 0.36),
                        iconColor: Color(red: 1.0, green: 0.36, blue: 0.36),
                        backgroundColor: optionContainerBackground,
                        height: optionContainerHeight,
                        width: optionContainerWidth,
                        titleFontSize: optionTitleFontSize,
                        subtitleFontSize: optionSubtitleFontSize,
                        cornerRadius: optionContainerCornerRadius,
                        horizontalPadding: optionContainerHorizontalPadding,
                        verticalPadding: optionContainerVerticalPadding
                    ) {
                        navigationManager.goToHome()
                    }
                    ActionOptionContainer(
                        iconName: "arrow.down.heart",
                        iconSize: optionIconSize,
                        iconTitleGap: iconTitleGap,
                        title: "Min HR",
                        subtitle: getMinHR(),
                        titleColor: Color(red: 1.0, green: 0.36, blue: 0.36),
                        iconColor: Color(red: 1.0, green: 0.36, blue: 0.36),
                        backgroundColor: optionContainerBackground,
                        height: optionContainerHeight,
                        width: optionContainerWidth,
                        titleFontSize: optionTitleFontSize,
                        subtitleFontSize: optionSubtitleFontSize,
                        cornerRadius: optionContainerCornerRadius,
                        horizontalPadding: optionContainerHorizontalPadding,
                        verticalPadding: optionContainerVerticalPadding
                    ) {
                        navigationManager.goToHome()
                    }
                    ActionOptionContainer(
                        iconName: "heart",
                        iconSize: optionIconSize,
                        iconTitleGap: iconTitleGap,
                        title: "Avg. HR",
                        subtitle: getAvgHR(),
                        titleColor: Color(red: 1.0, green: 0.36, blue: 0.36),
                        iconColor: Color(red: 1.0, green: 0.36, blue: 0.36),
                        backgroundColor: optionContainerBackground,
                        height: optionContainerHeight,
                        width: optionContainerWidth,
                        titleFontSize: optionTitleFontSize,
                        subtitleFontSize: optionSubtitleFontSize,
                        cornerRadius: optionContainerCornerRadius,
                        horizontalPadding: optionContainerHorizontalPadding,
                        verticalPadding: optionContainerVerticalPadding
                    ) {
                        navigationManager.goToHome()
                    }
                    ActionOptionContainer(
                        iconName: "hourglass.badge.plus",
                        iconSize: optionIconSize,
                        iconTitleGap: iconTitleGap,
                        title: "Epic Time",
                        subtitle: getEpicTime(),
                        titleColor: epicTimeColor,
                        iconColor: epicTimeColor,
                        backgroundColor: optionContainerBackground,
                        height: optionContainerHeight,
                        width: optionContainerWidth,
                        titleFontSize: optionTitleFontSize,
                        subtitleFontSize: optionSubtitleFontSize,
                        cornerRadius: optionContainerCornerRadius,
                        horizontalPadding: optionContainerHorizontalPadding,
                        verticalPadding: optionContainerVerticalPadding
                    ) {
                        navigationManager.goToHome()
                    }
                    ActionOptionContainer(
                        iconName: "house",
                        iconSize: optionIconSize,
                        iconTitleGap: iconTitleGap,
                        title: "Click To",
                        subtitle: "Go Home",
                        titleColor: Color.white,
                        iconColor: Color.white,
                        backgroundColor: optionContainerBackground,
                        height: optionContainerHeight,
                        width: optionContainerWidth,
                        titleFontSize: optionTitleFontSize,
                        subtitleFontSize: optionSubtitleFontSize,
                        cornerRadius: optionContainerCornerRadius,
                        horizontalPadding: optionContainerHorizontalPadding,
                        verticalPadding: optionContainerVerticalPadding
                    ) {
                        navigationManager.goToHome()
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .padding(.top, optionContainerTopPadding)
            }
            .disabled(isAPIBusy)
        }
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
        .onAppear {
            // Debug logging for SessionRecapScreen
            print("screenWidth: \(screenWidth)")
            print("=== SESSION RECAP SCREEN DEBUG ===")
            print("HRArray: \(sessionDataManager.HRArray)")
            print("HRArray count: \(sessionDataManager.HRArray.count)")
            print("epicTime: \(sessionDataManager.epicTime ?? -1)")
            print("accumulatedSessionTime: \(sessionDataManager.accumulatedSessionTime)")
            print("================================")
            
            // Start API POST request
            makeAPIPostRequest()
        }
        .onDisappear {
            // Clean up timer when leaving screen
            apiTimer?.invalidate()
            apiTimer = nil
            retryProgressTimer?.invalidate()
        }
    }

    private func getDeviceIdentifier() -> String {
        let identifier = WKInterfaceDevice.current().identifierForVendor?.uuidString ?? "unknown"
        print("Device Identifier: \(identifier)")
        return identifier
    }
    
    // Save failed session to UserDefaults for later upload
    private func savePendingRequest() {
        var pending = UserDefaults.standard.array(forKey: "pending_requests") as? [[String: Any]] ?? []
        pending.append(apiPayload)
        UserDefaults.standard.set(pending, forKey: "pending_requests")
        print("=== SAVED PENDING REQUEST ===")
        print(apiPayload)
    }

    // Helper: Calculate total time (in seconds)
    private func calculateTotalTime() -> Int {
        // For now, just use accumulatedSessionTime
        return sessionDataManager.accumulatedSessionTime
    }

    // Helper: Get session temperature (Fahrenheit)
    private func getSessionTemperature() -> Double {
        // Replace with your actual temperature property if needed
        if let last = sessionDataManager.lastSessionData,
           let tempStr = last["lastSessionWaterTemp"],
           let temp = Double(tempStr) {
            return temp
        }
        return 0.0
    }

    // Helper: Get formatted UTC time string
    private func getFormattedTimeUTC() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.string(from: Date())
    }

    // Helper: Get formatted local time string
    private func getFormattedTimeLocal() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }

    // Device info stubs

    // Will return the device name (e.g. "Apple Watch Ultra 2 (49mm)")
    private func getDeviceName() -> String {
        let model = WKInterfaceDevice.current().name
        print("Device ID (Model): \(model)")
        return model
    }
    
    // Will return the device version (e.g. "8.1")
    private func getDeviceModelVersion() -> String {
        let version = WKInterfaceDevice.current().localizedModel
        print("Device Model Version: \(version)")
        return version
    }
    
    // Will return the device firmware version (e.g. "8.1")
    private func getDeviceFirmwareVersion() -> String {
        let fw_version = WKInterfaceDevice.current().systemVersion
        print("Device Firmware Version: \(fw_version)")
        return "WatchOS \(fw_version)"
    }
}

private struct ActionOptionContainer: View {
    let iconName: String
    let iconSize: CGFloat
    let iconTitleGap: CGFloat
    let title: String
    let subtitle: String?
    let titleColor: Color
    let iconColor: Color
    let backgroundColor: Color
    let height: CGFloat
    let width: CGFloat
    let titleFontSize: CGFloat
    let subtitleFontSize: CGFloat
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .center, spacing: 0) {
                HStack(alignment: .center, spacing: iconTitleGap) {
                    Image(systemName: iconName)
                        .font(.system(size: iconSize, weight: .bold))
                        .foregroundColor(iconColor)
                    Text(title)
                        .font(.system(size: titleFontSize, weight: .bold))
                        .foregroundColor(titleColor)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: subtitleFontSize, weight: .regular))
                        .foregroundColor(Color.white)
                        .padding(.top, 2)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: width, minHeight: height, alignment: .center)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SessionRecapScreen(navigationManager: NavigationManager())
        .environmentObject(SessionDataManager())
} 