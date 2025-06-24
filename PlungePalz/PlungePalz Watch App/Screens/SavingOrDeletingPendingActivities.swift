//
//  SavingOrDeletingPendingActivities.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/12/24.
//

import SwiftUI

struct SavingOrDeletingPendingActivities: View {
    
    enum ActivityMode {
        case saving, deleting
    }
    
    @ObservedObject var navigationManager: NavigationManager
    let mode: ActivityMode
    
    // API Status Management
    @StateObject private var apiManager = APIs.shared
    @State private var apiStatus: String = "Calling" // "Calling", "Success", "Retrying", "Failed"
    @State private var apiTimer: Timer?
    @State private var retryAttempt: Int = 0
    @State private var retryProgress: CGFloat = 1.0
    @State private var retryProgressTimer: Timer?
    
    enum CountdownState {
        case initialCountdown, apiCalling, successCountdown, failed
    }
    
    @State private var currentState: CountdownState = .initialCountdown
    @StateObject private var screenManager = WatchScreenManager()
    @State private var countdown: Double = 10
    @State private var totalTime: Double = 10
    @State private var timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    // Get pending requests from UserDefaults
    private var pendingRequests: [[String: Any]] {
        return UserDefaults.standard.array(forKey: "pending_requests") as? [[String: Any]] ?? []
    }
    
    private var title: String {
        switch currentState {
        case .initialCountdown:
            return mode == .saving ? "Saving in..." : "Deleting in..."
        case .apiCalling:
            return mode == .saving ? "Saving..." : "Deleting..."
        case .successCountdown:
            return mode == .saving ? "Successful" : "Deleted"
        case .failed:
            return "Check WiFi"
        }
    }
    
    private var progressBarColor: Color {
        switch currentState {
        case .initialCountdown:
            return mode == .saving ? .blue : .red
        case .apiCalling:
            return .blue
        case .successCountdown:
            return .green
        case .failed:
            return .red
        }
    }
    
    var body: some View {

        // Screen Size
        let screenSize = screenManager.currentScreenSize
        
        // UI Configs
        let titleTopPadding = WatchGlobalUIConfig.SavingOrDeletingPendingActivities.titleTopPadding(for: screenSize)
        let titleFontSize = WatchGlobalUIConfig.SavingOrDeletingPendingActivities.titleFontSize(for: screenSize)
        let circleTopPadding = WatchGlobalUIConfig.SavingOrDeletingPendingActivities.circleTopPadding(for: screenSize)
        let circleSize = WatchGlobalUIConfig.SavingOrDeletingPendingActivities.circleSize(for: screenSize)
        let countdownFontSize = WatchGlobalUIConfig.SavingOrDeletingPendingActivities.countdownFontSize(for: screenSize)
        let buttonTopPadding = WatchGlobalUIConfig.SavingOrDeletingPendingActivities.buttonTopPadding(for: screenSize)
        let buttonFontSize = WatchGlobalUIConfig.SavingOrDeletingPendingActivities.buttonFontSize(for: screenSize)
        let buttonWidth = WatchGlobalUIConfig.SavingOrDeletingPendingActivities.buttonWidth(for: screenSize)
        let buttonHeight = WatchGlobalUIConfig.SavingOrDeletingPendingActivities.buttonHeight(for: screenSize)

        // UI
        VStack {
            Text(title)
                .font(.system(size: titleFontSize, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, titleTopPadding)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                    .frame(width: circleSize, height: circleSize)
                
                Circle()
                    .trim(from: 0, to: CGFloat(countdown / totalTime))
                    .stroke(progressBarColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: circleSize, height: circleSize)
                    .animation(.linear, value: countdown)
                
                if currentState == .apiCalling {
                    let iconName = mode == .deleting ? "document.on.trash" : "wifi"
                    let apiIcon = Image(systemName: iconName)
                        .font(.system(size: countdownFontSize, weight: .bold))
                        .foregroundColor(.white)
                    
                    if #available(watchOS 10.0, *) {
                        apiIcon
                            .symbolEffect(.pulse)
                    } else {
                        apiIcon
                    }
                } else if currentState == .successCountdown {
                    let iconName = mode == .deleting ? "trash" : "square.and.arrow.up.badge.checkmark"
                    Image(systemName: iconName)
                        .font(.system(size: countdownFontSize, weight: .bold))
                        .foregroundColor(progressBarColor)
                } else if currentState == .failed {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: countdownFontSize, weight: .bold))
                        .foregroundColor(.red)
                } else {
                    Text("\(Int(ceil(countdown)))")
                        .font(.system(size: countdownFontSize, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.top, circleTopPadding)
            .padding(.bottom, buttonTopPadding)
            
            Button(action: handleButtonTap) {
                Text(buttonText)
                    .font(.system(size: buttonFontSize, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: buttonWidth, height: buttonHeight)
            .background(Color.gray.opacity(0.5))
            .cornerRadius(50)
            .disabled(currentState == .apiCalling)
        }
        .onReceive(timer) { _ in
            handleTimerTick()
        }
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
        .onAppear {
            print("=== SAVING/DELETING PENDING ACTIVITIES SCREEN DEBUG ===")
            print("Mode: \(mode)")
            print("=====================================================")
            startTimer()
        }
        .onDisappear {
            stopTimer()
            // Clean up API timer when leaving screen
            apiTimer?.invalidate()
            apiTimer = nil
            retryProgressTimer?.invalidate()
        }
    }
    
    private var buttonText: String {
        switch currentState {
        case .initialCountdown:
            return "Cancel"
        case .successCountdown:
            return "Go Home"
        case .failed:
            return "Try Again"
        case .apiCalling:
            return "Waiting..."
        }
    }
    
    private func handleButtonTap() {
        switch currentState {
        case .initialCountdown:
            navigationManager.goToScreen(.pendingSaveSessions)
        case .successCountdown:
            navigationManager.goToHome()
        case .failed:
            // Reset for another attempt
            currentState = .initialCountdown
            countdown = 10
            totalTime = 10
            startTimer()
        case .apiCalling:
            // No action needed during apiCalling state
            break
        }
    }
    
    private func handleTimerTick() {
        if countdown > 0.05 {
            countdown -= 0.05
        } else {
            countdown = 0
            stopTimer()
            
            if currentState == .initialCountdown {
                if mode == .deleting {
                    // Clear the pending requests from UserDefaults
                    UserDefaults.standard.removeObject(forKey: "pending_requests")
                    print("Pending requests deleted.")
                    
                    // Immediately transition to success state
                    countdown = totalTime
                    currentState = .successCountdown
                } else { // mode is .saving
                    currentState = .apiCalling
                    
                    // Make actual API call to save pending requests
                    makeAPIPostRequest()
                }
            }
        }
    }
    
    private func startTimer() {
        self.timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    }

    private func stopTimer() {
        self.timer.upstream.connect().cancel()
    }
    
    // API Functions
    private func makeAPIPostRequest() {
        print("=== STARTING PENDING REQUESTS API POST ===")
        apiStatus = "Calling"
        retryAttempt = 0
        retryProgress = 1.0
        retryProgressTimer?.invalidate()
        
        // Check if there are pending requests
        if pendingRequests.isEmpty {
            print("No pending requests to save")
            apiStatus = "Success"
            currentState = .successCountdown
            countdown = totalTime
            return
        }
        
        performAPICall()
    }
    
    private func performAPICall() {
        // Create request using APIs helper for array of dictionaries
        guard let request = apiManager.createRequest(
            url: apiManager.savePendingSessionsEndpoint,
            method: "POST",
            bodyArray: pendingRequests
        ) else {
            print("Failed to create request")
            apiStatus = "Failed"
            currentState = .failed
            return
        }
        
        // Make the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                let result = self.apiManager.handleAPIResponse(response as? HTTPURLResponse, data: data, error: error)
                
                if result.success {
                    // Success - clear pending requests
                    UserDefaults.standard.removeObject(forKey: "pending_requests")
                    print("=== PENDING REQUESTS API POST SUCCESS ===")
                    self.apiStatus = "Success"
                    self.currentState = .successCountdown
                    self.countdown = self.totalTime
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
            print("=== PENDING REQUESTS API POST RETRYING (\(retryAttempt)) ===")
            
            // Retry after 5 seconds
            apiTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                DispatchQueue.main.async {
                    self.performAPICall()
                }
            }
        } else {
            apiStatus = "Failed"
            print("=== PENDING REQUESTS API POST FAILED AFTER 3 RETRIES ===")
            currentState = .failed
        }
    }
}

#Preview {
    SavingOrDeletingPendingActivities(navigationManager: NavigationManager(), mode: .saving)
} 