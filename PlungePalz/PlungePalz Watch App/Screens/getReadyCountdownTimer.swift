//
//  getReadyCountdownTimer.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/12/24.
//

import SwiftUI
import Combine

struct GetReadyCountdownTimer: View {
    @ObservedObject var navigationManager: NavigationManager
    
    @StateObject private var screenManager = WatchScreenManager()
    @StateObject private var backgroundTimerManager = BackgroundTimerManager.shared
    @State private var countdown: Double = 5.0
    @State private var totalTime: Double = 5.0
    @State private var timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    @State private var isCancelled: Bool = false
    
    private var title: String {
        return "Get Ready!"
    }
    
    private var progressBarColor: Color {
        return .blue
    }
    
    var body: some View {
        // Screen Size
        let screenSize = screenManager.currentScreenSize
        
        // UI Configs
        let titleTopPadding = WatchGlobalUIConfig.GetReadyCountdownTimer.titleTopPadding(for: screenSize)
        let titleFontSize = WatchGlobalUIConfig.GetReadyCountdownTimer.titleFontSize(for: screenSize)
        let circleTopPadding = WatchGlobalUIConfig.GetReadyCountdownTimer.circleTopPadding(for: screenSize)
        let circleSize = WatchGlobalUIConfig.GetReadyCountdownTimer.circleSize(for: screenSize)
        let countdownFontSize = WatchGlobalUIConfig.GetReadyCountdownTimer.countdownFontSize(for: screenSize)
        let buttonTopPadding = WatchGlobalUIConfig.GetReadyCountdownTimer.buttonTopPadding(for: screenSize)
        let buttonFontSize = WatchGlobalUIConfig.GetReadyCountdownTimer.buttonFontSize(for: screenSize)
        let buttonWidth = WatchGlobalUIConfig.GetReadyCountdownTimer.buttonWidth(for: screenSize)
        let buttonHeight = WatchGlobalUIConfig.GetReadyCountdownTimer.buttonHeight(for: screenSize)

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
                
                Text("\(Int(ceil(countdown)))")
                    .font(.system(size: countdownFontSize, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.top, circleTopPadding)
            .padding(.bottom, buttonTopPadding)
            
            Button(action: handleCancelButtonTap) {
                Text("Go Back")
                    .font(.system(size: buttonFontSize, weight: .bold))
                    .foregroundColor(countdown <= 1.0 ? .gray : .white)
            }
            .frame(width: buttonWidth, height: buttonHeight)
            .background(countdown <= 1.0 ? Color.gray.opacity(0.2) : Color.gray.opacity(0.5))
            .cornerRadius(50)
            .disabled(countdown <= 1.0)
        }
        .onReceive(timer) { _ in
            handleTimerTick()
        }
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
        .onAppear {
            // Get get ready timer value from UserDefaults, default to 5 seconds if not found
            let getReadySeconds = UserDefaults.standard.integer(forKey: "get_ready_timer_seconds")
            let finalGetReadySeconds = getReadySeconds > 0 ? getReadySeconds : 5
            
            // Initialize countdown and total time
            countdown = Double(finalGetReadySeconds)
            totalTime = Double(finalGetReadySeconds)
            
            #if DEBUG
            print("GetReadyCountdownTimer using stored value: \(finalGetReadySeconds) seconds")
            #endif
            
            // Start background timer to ensure countdown continues even if screen sleeps
            backgroundTimerManager.startGetReadyTimer(duration: Double(finalGetReadySeconds)) {
                // This completion will be called when timer completes (even in background)
                DispatchQueue.main.async {
                    self.navigationManager.goToScreen(.countdownActivated)
                }
            }
            
            startTimer()
        }
        .onDisappear {
            stopTimer()
            // Stop background timer when leaving the screen (unless cancelled)
            if !isCancelled {
                backgroundTimerManager.stopGetReadyTimer()
            }
        }
    }
    
    private func handleCancelButtonTap() {
        // Set cancel flag to prevent automatic navigation
        isCancelled = true
        
        // Stop background timer
        backgroundTimerManager.stopGetReadyTimer()
        
        // Stop the UI timer
        stopTimer()
        
        // Go back to the previous screen (either SetTemperatureScreen or SelectSessionScreen)
        navigationManager.goToPreviousScreen()
    }
    
    private func handleTimerTick() {
        // Don't process timer ticks if cancelled
        guard !isCancelled else { return }
        
        // Sync with background timer
        let backgroundRemaining = backgroundTimerManager.getGetReadyTimerRemainingTime()
        countdown = backgroundRemaining
        
        if countdown <= 0.05 {
            countdown = 0
            stopTimer()
            
            // Automatically transition to CountdownActivatedScreen
            navigationManager.goToScreen(.countdownActivated)
        }
    }
    
    private func startTimer() {
        self.timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    }

    private func stopTimer() {
        self.timer.upstream.connect().cancel()
    }
}

#Preview {
    GetReadyCountdownTimer(navigationManager: NavigationManager())
} 