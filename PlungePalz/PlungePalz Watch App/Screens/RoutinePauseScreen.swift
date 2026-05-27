//
//  RoutinePauseScreen.swift
//  PlungePalz Watch App
//
//  Pause menu shown during a routine Modality or Transition step.
//  Options: Save (Modality only) | Continue | Skip This Step
//

import SwiftUI
import WatchKit

struct RoutinePauseScreen: View {
    @ObservedObject var navigationManager: NavigationManager
    @EnvironmentObject var sessionDataManager: SessionDataManager
    @EnvironmentObject var workoutManager: WorkoutManager
    @StateObject private var screenManager = WatchScreenManager()

    // MARK: - Computed helpers

    private var isModality: Bool { navigationManager.routinePauseSource == "Modality" }

    private func getTimeString() -> String {
        let secs = sessionDataManager.accumulatedSessionTime
        return String(format: "%d:%02d", secs / 60, secs % 60)
    }

    private func getTempString() -> String {
        guard let tf = sessionDataManager.currentRoutineStep?.tempF else { return "--" }
        let unit = sessionDataManager.unitOfMeasure
        if unit == "Metric" {
            let c = (tf - 32) * 5 / 9
            return String(format: "%.1f°C", c)
        }
        return String(format: "%.1f°F", tf)
    }

    // MARK: - Actions

    private func handleSave() {
        navigationManager.routinePauseAction = "save"
        navigationManager.goToScreen(.routineModality)
    }

    private func handleContinue() {
        navigationManager.routinePauseAction = ""
        if isModality {
            navigationManager.goToScreen(.routineModality)
        } else {
            navigationManager.goToScreen(.routineTransition)
        }
    }

    private func handleSkip() {
        navigationManager.routinePauseAction = "skip"
        if isModality {
            navigationManager.goToScreen(.routineModality)
        } else {
            navigationManager.goToScreen(.routineTransition)
        }
    }

    // MARK: - Body

    var body: some View {
        let screenSize  = screenManager.currentScreenSize
        let screenWidth  = WKInterfaceDevice.current().screenBounds.width
        let screenHeight = WKInterfaceDevice.current().screenBounds.height

        let optionIconSize            = WatchGlobalUIConfig.ActivityStoppedOrPausedScreen.optionIconSize(for: screenSize)
        let optionTitleFontSize       = WatchGlobalUIConfig.ActivityStoppedOrPausedScreen.optionTitleFontSize(for: screenSize)
        let optionSubtitleFontSize    = WatchGlobalUIConfig.ActivityStoppedOrPausedScreen.optionSubtitleFontSize(for: screenSize)
        let iconTitleGap              = WatchGlobalUIConfig.ActivityStoppedOrPausedScreen.iconTitleGap(for: screenSize)
        let optionContainerTopPadding = WatchGlobalUIConfig.ActivityStoppedOrPausedScreen.optionContainerTopPadding(for: screenSize)
        let optionContainerWidthRatio = WatchGlobalUIConfig.ActivityStoppedOrPausedScreen.optionContainerWidthRatio(for: screenSize)
        let optionContainerHeightRatio = WatchGlobalUIConfig.ActivityStoppedOrPausedScreen.optionContainerHeightRatio(for: screenSize)
        let optionContainerWidth  = screenWidth  * optionContainerWidthRatio
        let optionContainerHeight = screenHeight * optionContainerHeightRatio

        let optionContainerCornerRadius: CGFloat = 12
        let bg   = Color.black
        let subtitle = "\(getTimeString()) | \(getTempString())"

        ZStack {
            Color(red: 0/255, green: 116/255, blue: 255/255).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {

                    // MARK: Save (Modality only)
                    if isModality {
                        RoutinePauseOptionContainer(
                            iconName: "square.and.arrow.down",
                            iconSize: optionIconSize,
                            iconTitleGap: iconTitleGap,
                            title: "Save",
                            subtitle: subtitle,
                            titleColor: .white,
                            iconColor: .white,
                            backgroundColor: bg,
                            height: optionContainerHeight,
                            width: optionContainerWidth,
                            titleFontSize: optionTitleFontSize,
                            subtitleFontSize: optionSubtitleFontSize,
                            cornerRadius: optionContainerCornerRadius
                        ) {
                            handleSave()
                        }
                    }

                    // MARK: Continue
                    RoutinePauseOptionContainer(
                        iconName: "arrow.uturn.backward.square",
                        iconSize: optionIconSize,
                        iconTitleGap: iconTitleGap,
                        title: "Continue",
                        subtitle: subtitle,
                        titleColor: .white,
                        iconColor: .green,
                        backgroundColor: bg,
                        height: optionContainerHeight,
                        width: optionContainerWidth,
                        titleFontSize: optionTitleFontSize,
                        subtitleFontSize: optionSubtitleFontSize,
                        cornerRadius: optionContainerCornerRadius
                    ) {
                        handleContinue()
                    }

                    // MARK: Skip This Step
                    RoutinePauseOptionContainer(
                        iconName: "forward.end.fill",
                        iconSize: optionIconSize,
                        iconTitleGap: iconTitleGap,
                        title: "Skip This Step",
                        subtitle: "",
                        titleColor: .white,
                        iconColor: Color(red: 1.0, green: 0.36, blue: 0.36),
                        backgroundColor: bg,
                        height: optionContainerHeight,
                        width: optionContainerWidth,
                        titleFontSize: optionTitleFontSize,
                        subtitleFontSize: optionSubtitleFontSize,
                        cornerRadius: optionContainerCornerRadius
                    ) {
                        handleSkip()
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .padding(.top, optionContainerTopPadding)
            }
        }
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
    }
}

// MARK: - Option Container (private to this file)

private struct RoutinePauseOptionContainer: View {
    let iconName: String
    let iconSize: CGFloat
    let iconTitleGap: CGFloat
    let title: String
    let subtitle: String
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
            VStack(spacing: iconTitleGap) {
                Image(systemName: iconName)
                    .font(.system(size: iconSize, weight: .bold))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.system(size: titleFontSize, weight: .bold))
                    .foregroundStyle(titleColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: subtitleFontSize))
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(width: width, height: height)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RoutinePauseScreen(navigationManager: NavigationManager())
        .environmentObject(SessionDataManager())
        .environmentObject(WorkoutManager())
}
