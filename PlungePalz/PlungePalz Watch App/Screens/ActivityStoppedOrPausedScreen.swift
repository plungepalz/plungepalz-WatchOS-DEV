//
//  ActivityStoppedOrPausedScreen.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import SwiftUI

struct ActivityStoppedOrPausedScreen: View {
    @EnvironmentObject var sessionDataManager: SessionDataManager
    @EnvironmentObject var workoutManager: WorkoutManager
    @StateObject private var screenManager = WatchScreenManager()
    @ObservedObject var navigationManager: NavigationManager
    
    // Helper to get formatted time string from sessionDataManager
    private func getTimeString() -> String {
        let totalSeconds = Int(workoutManager.elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    // Helper to get formatted temperature string from sessionDataManager
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
    
    var body: some View {
                
        // Screen Size
        let screenSize = screenManager.currentScreenSize
        let screenWidth = WKInterfaceDevice.current().screenBounds.width
        let screenHeight = WKInterfaceDevice.current().screenBounds.height

        // Global UI Config Variables
        let optionIconSize = WatchGlobalUIConfig.ActivityStoppedOrPausedScreen.optionIconSize(for: screenSize)
        let optionTitleFontSize = WatchGlobalUIConfig.ActivityStoppedOrPausedScreen.optionTitleFontSize(for: screenSize)
        let optionSubtitleFontSize = WatchGlobalUIConfig.ActivityStoppedOrPausedScreen.optionSubtitleFontSize(for: screenSize)
        let iconTitleGap = WatchGlobalUIConfig.ActivityStoppedOrPausedScreen.iconTitleGap(for: screenSize)

        // Option Container Width and Height Ratios
        let optionContainerTopPadding = WatchGlobalUIConfig.ActivityStoppedOrPausedScreen.optionContainerTopPadding(for: screenSize)
        let optionContainerWidthRatio = WatchGlobalUIConfig.ActivityStoppedOrPausedScreen.optionContainerWidthRatio(for: screenSize)
        let optionContainerHeightRatio = WatchGlobalUIConfig.ActivityStoppedOrPausedScreen.optionContainerHeightRatio(for: screenSize)

        // Calculate Option Container Width
        let optionContainerWidth = screenWidth * optionContainerWidthRatio
        let optionContainerHeight = screenHeight * optionContainerHeightRatio

        // Option Container Constants
        let optionContainerCornerRadius: CGFloat = 12
        let optionContainerBackground = Color.black
        let deleteRed = Color(red: 1.0, green: 0.36, blue: 0.36)
        let subtitle = "\(getTimeString()) | \(getTemperatureString())"

        ZStack {
            Color(red: 0/255, green: 116/255, blue: 255/255)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    ActionOptionContainer(
                        iconName: "icloud.and.arrow.up",
                        iconSize: optionIconSize,
                        iconTitleGap: iconTitleGap,
                        title: "Save",
                        subtitle: subtitle,
                        titleColor: Color.white,
                        iconColor: Color.white,
                        backgroundColor: optionContainerBackground,
                        height: optionContainerHeight,
                        width: optionContainerWidth,
                        titleFontSize: optionTitleFontSize,
                        subtitleFontSize: optionSubtitleFontSize,
                        cornerRadius: optionContainerCornerRadius
                    ) {
                        // print("Save option clicked. Stopping workout and navigating to SessionRecapScreen.")
                        if workoutManager.isActive {
                            workoutManager.stopWorkout()
                        }
                        navigationManager.goToScreen(.sessionRecap)
                    }
                    ActionOptionContainer(
                        iconName: "play.square",
                        iconSize: optionIconSize,
                        iconTitleGap: iconTitleGap,
                        title: "Continue",
                        subtitle: subtitle,
                        titleColor: Color.white,
                        iconColor: Color.white,
                        backgroundColor: optionContainerBackground,
                        height: optionContainerHeight,
                        width: optionContainerWidth,
                        titleFontSize: optionTitleFontSize,
                        subtitleFontSize: optionSubtitleFontSize,
                        cornerRadius: optionContainerCornerRadius
                    ) {
                        // print("Continue option clicked. Resuming workout and navigating to CountdownActivatedScreen.")
                        if workoutManager.isActive && workoutManager.isPaused {
                            workoutManager.resumeWorkout()
                        }
                        navigationManager.goToScreen(.countdownActivated)
                    }
                    ActionOptionContainer(
                        iconName: "trash",
                        iconSize: optionIconSize,
                        iconTitleGap: iconTitleGap,
                        title: "DELETE",
                        subtitle: nil,
                        titleColor: deleteRed,
                        iconColor: deleteRed,
                        backgroundColor: optionContainerBackground,
                        height: optionContainerHeight,
                        width: optionContainerWidth,
                        titleFontSize: optionTitleFontSize,
                        subtitleFontSize: optionSubtitleFontSize,
                        cornerRadius: optionContainerCornerRadius
                    ) {
                        // print("Delete option clicked. Discarding workout and navigating to SessionDeletedScreen.")
                        if workoutManager.isActive {
                            workoutManager.discardWorkout()
                        }
                        navigationManager.goToScreen(.sessionDeleted)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .padding(.top, optionContainerTopPadding)
            }
        }
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
        .onAppear {
            // Debug logging for ActivityStoppedOrPausedScreen
            // print("=== ACTIVITY STOPPED/PAUSED SCREEN DEBUG ===")
            // print("HRArray: \(sessionDataManager.HRArray)")
            // print("HRArray count: \(sessionDataManager.HRArray.count)")
            // print("epicTime: \(sessionDataManager.epicTime ?? -1)")
            // print("accumulatedSessionTime: \(sessionDataManager.accumulatedSessionTime)")
            // print("============================================")
        }
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
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: iconTitleGap) {
                    Image(systemName: iconName)
                        .font(.system(size: iconSize, weight: .bold))
                        .foregroundColor(iconColor)
                    Text(title)
                        .font(.system(size: titleFontSize, weight: .bold))
                        .foregroundColor(titleColor)
                    Spacer()
                }
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: subtitleFontSize, weight: .regular))
                        .foregroundColor(Color.white)
                        .padding(.top, 2)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: width, minHeight: height, alignment: .leading)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let previewManager: SessionDataManager = {
        let manager = SessionDataManager()
        manager.lastSessionData = [
            "lastSessionTimeSet": "3:31",
            "lastSessionWaterTemp": "45.1",
            "unitOfMeasure": "Imperial"
        ]
        return manager
    }()
    return ActivityStoppedOrPausedScreen(navigationManager: NavigationManager())
        .environmentObject(previewManager)
} 
