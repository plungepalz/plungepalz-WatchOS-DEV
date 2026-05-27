//
//  RoutineTransitionScreen.swift
//  PlungePalz Watch App
//
//  Timed rest/bridge period between routine steps. No HealthKit session.
//

import SwiftUI

struct RoutineTransitionScreen: View {
    @ObservedObject var navigationManager: NavigationManager
    @EnvironmentObject var sessionDataManager: SessionDataManager
    @StateObject private var screenManager = WatchScreenManager()

    @State private var remainingSeconds: Int = 60
    @State private var totalSeconds: Int = 60
    @State private var isPaused: Bool = false
    @State private var timer: Timer? = nil
    @State private var didComplete: Bool = false

    private let accentBlue = Color(hex: "#00A8FF")
    private let progressGray = Color(red: 165 / 255, green: 165 / 255, blue: 165 / 255)

    // MARK: - Computed

    private var currentStep: RoutineStepModel? { sessionDataManager.currentRoutineStep }

    private var nextStep: RoutineStepModel? {
        guard let routine = sessionDataManager.activeRoutine else { return nil }
        let nextIdx = sessionDataManager.currentRoutineStepIndex + 1
        guard nextIdx < routine.routineList.count else { return nil }
        return routine.routineList[nextIdx]
    }

    private var isRoutineComplete: Bool { nextStep == nil }

    private var timeString: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    // MARK: - Body

    var body: some View {
        let screenSize = screenManager.currentScreenSize
        let stopIconTopCornerPadding = WatchGlobalUIConfig.CountdownActivatedScreen.stopIconTopCornerPadding(for: screenSize)
        let stopIconSize = WatchGlobalUIConfig.CountdownActivatedScreen.stopIconSize(for: screenSize)

        GeometryReader { geo in
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    Text(currentStep?.stepNickname ?? "Transition")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(accentBlue)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .padding(.top, stopIconSize + stopIconTopCornerPadding - 4)
                        .padding(.horizontal, 12)

                    Text(timeString)
                        .font(.system(size: 38, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .padding(.top, 6)

                    progressBar(width: geo.size.width * 0.88)
                        .padding(.top, 8)

                    nextUpSection
                        .padding(.top, 10)
                        .padding(.horizontal, 10)

                    Spacer(minLength: 0)
                }
                .frame(width: geo.size.width, height: geo.size.height)

                // Stop button overlay in top-left corner
                VStack {
                    HStack {
                        Button(action: handlePauseButton) {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: stopIconSize, weight: .medium))
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, stopIconTopCornerPadding)
                        .padding(.leading, stopIconTopCornerPadding)

                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
        .onAppear {
            if let step = currentStep {
                remainingSeconds = step.sLength
                totalSeconds = step.sLength
            }
            didComplete = false
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: navigationManager.routinePauseAction) { action in
            if action == "skip" {
                navigationManager.routinePauseAction = ""
                skipAndAdvance()
            } else if action == "" {
                isPaused = false
                startTimer()
            }
        }
    }

    // MARK: - Progress Bar

    private func progressBar(width: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(progressGray)
                .frame(width: width, height: 8)
            RoundedRectangle(cornerRadius: 4)
                .fill(accentBlue)
                .frame(width: width * progress, height: 8)
                .animation(.linear(duration: 0.35), value: progress)
        }
        .frame(width: width, height: 8)
    }

    // MARK: - Next Up

    private var nextUpSection: some View {
        VStack(spacing: 5) {
            Text("NEXT UP")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.gray)
                .tracking(0.6)

            if isRoutineComplete {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accentBlue)
                    Text("Routine Complete")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else if let step = nextStep {
                nextStepRow(for: step)
            }
        }
    }

    private func nextStepRow(for step: RoutineStepModel) -> some View {
        HStack(spacing: 5) {
            Image(systemName: stepIcon(for: step))
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(stepIconColor(for: step))
                .frame(width: 16)

            Text(nextStepDetailText(for: step))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Formatting

    private func stepLabel(for step: RoutineStepModel) -> String {
        step.type == "Modality"
            ? (step.activityType ?? "Activity")
            : (step.stepNickname ?? "Transition")
    }

    private func stepIcon(for step: RoutineStepModel) -> String {
        step.type == "Modality"
            ? ActivityTypes.systemIcon(for: step.activityType)
            : "arrow.right.circle"
    }

    private func stepIconColor(for step: RoutineStepModel) -> Color {
        step.type == "Modality"
            ? ActivityTypes.iconColor(for: step.activityType)
            : Color.green.opacity(0.85)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func tempString(for step: RoutineStepModel) -> String? {
        guard step.type == "Modality", let tf = step.tempF else { return nil }
        return sessionDataManager.formatTempDisplayWithUnit(tempF: tf)
    }

    private func nextStepDetailText(for step: RoutineStepModel) -> AttributedString {
        let label = stepLabel(for: step)
        let duration = formatDuration(step.sLength)
        var result = AttributedString("\(label): \(duration)")

        if let temp = tempString(for: step) {
            result.append(AttributedString(" | "))
            var tempPart = AttributedString(temp)
            tempPart.foregroundColor = ActivityTypes.temperatureTextColor(for: step.activityType)
            result.append(tempPart)
        }

        return result
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard !isPaused, !didComplete else { return }
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            }
            if remainingSeconds == 0 {
                didComplete = true
                stopTimer()
                onTransitionComplete()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Actions

    private func handlePauseButton() {
        stopTimer()
        isPaused = true
        navigationManager.routinePauseSource = "Transition"
        navigationManager.routinePauseAction = ""
        navigationManager.goToScreen(.routinePause)
    }

    private func onTransitionComplete() {
        sessionDataManager.addRoutineStepResult(status: "")
        if sessionDataManager.isLastRoutineStep {
            navigationManager.goToScreen(.routineRecap)
        } else {
            sessionDataManager.currentRoutineStepIndex += 1
            navigationManager.goToScreen(.routineGetReady)
        }
    }

    private func skipAndAdvance() {
        stopTimer()
        sessionDataManager.addRoutineStepResult(status: "Skipped")
        if sessionDataManager.isLastRoutineStep {
            navigationManager.goToScreen(.routineRecap)
        } else {
            sessionDataManager.currentRoutineStepIndex += 1
            navigationManager.goToScreen(.routineGetReady)
        }
    }
}

#Preview {
    RoutineTransitionScreen(navigationManager: NavigationManager())
        .environmentObject(SessionDataManager())
}
