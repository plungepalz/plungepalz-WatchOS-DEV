//
//  ConnectDeviceScreen.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import SwiftUI
import WatchKit

struct ConnectDeviceScreen: View {
    @StateObject private var screenManager = WatchScreenManager()
    @ObservedObject var navigationManager: NavigationManager
    
    // Timer state
    @State private var countdown_1: Double = 45.0
    @State private var countdown_2: Double = 5.0
    @State private var totalTime_1: Double = 45.0
    @State private var totalTime_2: Double = 5.0
    @State private var timer: Timer?
    
    // Screen states
    @State private var isConnectedMode = false
    
    // Generate a random 6 digit number
    @State private var randomSixDigitNumber: String = "495-103"
    
    var body: some View {
        
        // Get the current device's screen width/height
        let screenWidth = WKInterfaceDevice.current().screenBounds.width
        let screenHeight = WKInterfaceDevice.current().screenBounds.height
        
        // Ge the Global UI Constants
        let progressHeightRatio = WatchGlobalUIConfig.ConnectDeviceScreen.progressHeightRatio(for: screenManager.currentScreenSize)
        let progressWidthRatio = WatchGlobalUIConfig.ConnectDeviceScreen.progressWidthRatio(for: screenManager.currentScreenSize)
        let outerProgressContainerBorderRadius = WatchGlobalUIConfig.ConnectDeviceScreen.outerProgressContainerBorderRadius(for: screenManager.currentScreenSize)
        let innerProgressContainerBorderRadius = WatchGlobalUIConfig.ConnectDeviceScreen.innerProgressContainerBorderRadius(for: screenManager.currentScreenSize)
        let six_digit_font_size = WatchGlobalUIConfig.ConnectDeviceScreen.six_digit_font_size(for: screenManager.currentScreenSize)
        let status_text_font_size = WatchGlobalUIConfig.ConnectDeviceScreen.status_text_font_size(for: screenManager.currentScreenSize)
        let skipButtonTextPaddingHorizontal = WatchGlobalUIConfig.ConnectDeviceScreen.skipButtonTextPaddingHorizontal(for: screenManager.currentScreenSize)
        let skipButtonTextPaddingVertical = WatchGlobalUIConfig.ConnectDeviceScreen.skipButtonTextPaddingVertical(for: screenManager.currentScreenSize)
        let buttonFontSize = WatchGlobalUIConfig.ConnectDeviceScreen.skipButtonFontSize(for: screenManager.currentScreenSize)
        let buttonTopPadding = WatchGlobalUIConfig.ConnectDeviceScreen.skipButtonTopPadding(for: screenManager.currentScreenSize)

        // Calculate the progress ring dimensions based on the screen size
        let progressHeight = screenHeight * progressHeightRatio
        let progressWidth = screenWidth * progressWidthRatio

        // Calculate Height and Width for Progress Containers
        let progressContainerHeight_outer = progressHeight - 20
        let progressContainerWidth_outer = progressWidth - 20

        let progressContainerHeight_inner = progressHeight - 40
        let progressContainerWidth_inner = progressWidth - 40
        
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Outer Rectangular progress ring
            RectangularProgressRing(
                progress: countdown_1 / totalTime_1,
                screenSize: screenManager.currentScreenSize.screenDimensions,
                pillHeight: progressContainerHeight_outer,
                pillWidth: progressContainerWidth_outer,
                pillCornerRadius: outerProgressContainerBorderRadius,
                bottomPadding: 20,
                strokeWidth: 8,
                progressColor: isConnectedMode ? .green : .white
            )
            
            // Inner Rectangular progress ring
            RectangularProgressRing(
                progress: countdown_2 / totalTime_2,
                screenSize: screenManager.currentScreenSize.screenDimensions,
                pillHeight: progressContainerHeight_inner,
                pillWidth: progressContainerWidth_inner,
                pillCornerRadius: innerProgressContainerBorderRadius,
                bottomPadding: 20,
                strokeWidth: 8,
                progressColor: isConnectedMode ? .green : .blue
            )
            
            // Content
            Text(randomSixDigitNumber)
                .font(.system(size: six_digit_font_size, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .foregroundStyle(.white)
        }
        .overlay(
            VStack(spacing: 0) {
                if !isConnectedMode {
                    Text("New code in:")
                        .font(.system(size: status_text_font_size, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                
                    Text("\(Int(max(countdown_1, 0))) sec")
                        .font(.system(size: status_text_font_size, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                } else {
                    Text("Connected")
                        .font(.system(size: status_text_font_size, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
            .padding(.leading, 20)
            .padding(.trailing, 20),
            alignment: .top
        )
        .overlay(
            // Skip button positioned at the bottom
            VStack {
            Button(action: {
                if isConnectedMode {
                    navigationManager.goToScreen(.home)
                } else {
                    navigationManager.goToScreen(.setTimer)
                }
            }) {
                isConnectedMode ? Text("Next") : Text("Skip")
            }
            .font(.system(size: buttonFontSize, weight: .bold, design: .rounded))
            .padding(.top, skipButtonTextPaddingVertical)
            .padding(.bottom, skipButtonTextPaddingVertical)
            .padding(.leading, skipButtonTextPaddingHorizontal)
            .padding(.trailing, skipButtonTextPaddingHorizontal)
            .foregroundColor(isConnectedMode ? .white : .white)
            .background(isConnectedMode ? .green : .blue)
            .cornerRadius(100)
            }
            .padding(.top, buttonTopPadding)
        )
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
        .onAppear {
            let screenSize = screenManager.currentScreenSize
            print("--- Watch Screen Debug Info ---")
            print("Screen Size Category: \(screenSize.rawValue)")
            print("Screen Dimensions: \(screenSize.screenDimensions)")
            print("-----------------------------")
            randomSixDigitNumber = generate_random_6_digit_code()
            startTimer_1()
            startTimer_2()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - Timer Functions
    private func startTimer_1() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if !isConnectedMode {
                if countdown_1 > 0 {
                    countdown_1 -= 0.1
                } else {
                    countdown_1 = 0
                    // Generate new code and restart timer
                    randomSixDigitNumber = generate_random_6_digit_code()
                    countdown_1 = totalTime_1
                }
            }
        }
    }
    
    private func startTimer_2() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if !isConnectedMode {
                if countdown_2 > 0 {
                    countdown_2 -= 0.1
                } else {
                    countdown_2 = 0
                    // Make API request and restart timer
                    makePairingAPIRequest()
                    countdown_2 = totalTime_2
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - API Functions
    private func makePairingAPIRequest() {
        // Create the URL with the pairing code as a query parameter
        // Strip the hyphen from the randomSixDigitNumber for the API call
        let pairingCode = randomSixDigitNumber.replacingOccurrences(of: "-", with: "")
        
        let baseURL = "https://d76hjali51.execute-api.us-east-1.amazonaws.com/SmartWatchActivitySaved_mvp_production/AppleWatch/VerifyPairingCode_AppleWatchSide"
        let urlString = "\(baseURL)?pairingCode=\(pairingCode)"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            return
        }
        
        print("Making API request to: \(urlString)")
        print("Display code: \(randomSixDigitNumber), API code: \(pairingCode)")
        
        // Create the URL request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Make the API call
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("API request failed with error: \(error)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response type")
                    return
                }
                
                print("API response status code: \(httpResponse.statusCode)")
                
                guard let data = data else {
                    print("No data received from API")
                    return
                }
                
                do {
                    // Parse the JSON response
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("API response: \(json)")
                        
                        // Check if the response contains a status field
                        if let status = json["status"] as? String {
                            if status == "connected" {
                                // Device successfully paired
                                if let userID = json["userID"] as? String {
                                    print("Device paired successfully! User ID: \(userID)")
                                    
                                    // Store the userID in local storage
                                    UserDefaults.standard.set(userID, forKey: "userId")
                                    print("User ID stored in local storage: \(userID)")
                                    
                                    self.switchToConnectedMode()
                                } else {
                                    print("Connected status received but no userID found")
                                }
                            } else if status == "created" {
                                // No matching device found, continue polling
                                print("No matching device found with pairing code: \(self.randomSixDigitNumber)")
                            } else {
                                print("Unexpected status received: \(status)")
                            }
                        } else if let errorMessage = json["error"] as? String {
                            // API returned an error
                            print("API error: \(errorMessage)")
                        } else {
                            print("Unexpected response format: \(json)")
                        }
                    } else {
                        print("Failed to parse JSON response")
                    }
                } catch {
                    print("JSON parsing error: \(error)")
                }
            }
        }.resume()
    }
    
    private func switchToConnectedMode() {
        isConnectedMode = true
        
        // Stop both timers by setting them to full
        countdown_1 = totalTime_1
        countdown_2 = totalTime_2
        
        // Progress rings will now show 100% and green color
        print("Device connected! Timers stopped, progress rings filled and green.")
    }
    
    // Generates a random 6 digit code in the format "{###}-{###}"
    private func generate_random_6_digit_code() -> String {
        let first = Int.random(in: 100...999)
        let second = Int.random(in: 100...999)
        return "\(first)-\(second)"
    }
}

// MARK: - Rectangular Progress Ring
struct RectangularProgressRing: View {
    
    // UI parameters
    let progress: Double
    let screenSize: CGSize
    let pillHeight: CGFloat
    let pillWidth: CGFloat
    let pillCornerRadius: CGFloat
    let bottomPadding: CGFloat
    let strokeWidth: CGFloat
    let progressColor: Color
    
    private let animationDuration: Double = 0.1
    
    var body: some View {
        
        ZStack {
            // Background rectangle, rotated to match the progress bar
            RoundedRectangle(cornerRadius: pillCornerRadius)
                .stroke(Color.gray.opacity(0.3), lineWidth: strokeWidth)

            // Progress rectangle, rotated to start the trim from the top
            RoundedRectangle(cornerRadius: pillCornerRadius)
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .animation(.linear(duration: animationDuration), value: progress)
        }
        .rotationEffect(.degrees(-90)) // Rotate the shapes to change the trim start point
        .frame(width: pillHeight, height: pillWidth) // Swap width and height to maintain orientation
        .padding(.bottom, bottomPadding)
    }
}

#Preview {
    ConnectDeviceScreen(navigationManager: NavigationManager())
} 
