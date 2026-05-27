//
//  RoutineTransitionScreen.swift
//  PlungePalz Watch App
//
//  Timed rest/bridge period between routine steps. No HealthKit session.
//

import SwiftUI
import Combine

struct RoutineTransitionScreen: View {
    @ObservedObject var navigationManager: NavigationManager
    @EnvironmentObject var sessionDataManager: SessionDataManager
    @StateObject private var screenManager = WatchScreenManager()

    @State private var isPaused: Bool = false
    @State private var timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    @State private var didComplete: Bool = false

    // Add this near the top of your view with your other state variables
    @State private var displayRemainingSeconds: Double = 0.0

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

    private var remainingSeconds: Double {
        guard let endDate = sessionDataManager.routineTransitionEndDate else { return 0 }
        return max(0, endDate.timeIntervalSinceNow)
    }

    private var totalSeconds: Int {
        sessionDataManager.routineTransitionTotalSeconds
    }

    private var timeString: String {
        // Format the newly created @State variable instead of the old computed property
        let totalSeconds = Int(displayRemainingSeconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        let elapsed = Double(totalSeconds) - remainingSeconds
        return min(1, max(0, elapsed / Double(totalSeconds)))
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
                    VStack(spacing: 2) {
                        Text(currentStep?.stepNickname ?? "Transition")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(accentBlue)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 36)
                    .frame(maxWidth: .infinity)

                    Text(timeString)
                        .font(.system(size: 38, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .padding(.top, 4)

                    nextUpSection
                        .padding(.top, 8)
                        .padding(.horizontal, 10)

                    Spacer(minLength: 0)
                }
                .frame(width: geo.size.width, height: geo.size.height)

                VStack {
                    HStack {
                        Button(action: handlePauseButton) {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: stopIconSize, weight: .medium))
                                .foregroundStyle(.red)
                                .background(Color.black.clipShape(Circle()))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, stopIconTopCornerPadding)
                        .padding(.leading, stopIconTopCornerPadding)

                        Spacer()
                    }
                    Spacer()
                }
                .ignoresSafeArea()
            }
        }
        .onReceive(timer) { _ in
            handleTick()
        }
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
        .onAppear {
            if sessionDataManager.hasTransitionSnapshotForCurrentStep {
                didComplete = false
                isPaused = false
            } else if let step = currentStep {
                didComplete = false
                sessionDataManager.beginTransitionStep(totalSeconds: step.sLength)
            }
            
            // Initialize the starting value for the UI immediately
            if let endDate = sessionDataManager.routineTransitionEndDate {
                self.displayRemainingSeconds = max(0, endDate.timeIntervalSinceNow)
            }
            
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - Next Up

    private var nextUpSection: some View {
        VStack(spacing: 4) {
            Text("NEXT UP")
                .font(.system(size: 14, weight: .bold, design: .rounded))
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
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else if let step = nextStep {
                nextStepRow(for: step)
            }
        }
    }

    private func nextStepRow(for step: RoutineStepModel) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: stepIcon(for: step))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(stepIconColor(for: step))
                    .frame(width: 16, alignment: .center)

                Text(stepLabel(for: step))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 4)

            HStack {
                Text(formatDuration(step.sLength))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer()

                if let temp = tempString(for: step) {
                    Text(temp)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(ActivityTypes.temperatureTextColor(for: step.activityType))
                }
            }
            .padding(.horizontal, 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
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

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    }

    private func stopTimer() {
        timer.upstream.connect().cancel()
    }

    private func handleTick() {
        guard !isPaused, !didComplete else { return }
        
        guard let endDate = sessionDataManager.routineTransitionEndDate else { return }
        
        // 1. Calculate the actual time left
        let calculatedRemaining = max(0, endDate.timeIntervalSinceNow)
        
        // 2. Update the @State variable (Triggers the SwiftUI screen refresh!)
        self.displayRemainingSeconds = calculatedRemaining
        
        // 3. Check for completion
        if displayRemainingSeconds <= 0 {
            didComplete = true
            stopTimer()
            // Whatever your completion function is:
            onTransitionComplete() 
        }
    }

    // MARK: - Actions

    private func handlePauseButton() {
        stopTimer()
        isPaused = true
        navigationManager.routinePauseSource = "Transition"
        navigationManager.goToScreen(.routinePause)
    }

    private func onTransitionComplete() {
        sessionDataManager.routineTransitionEndDate = nil
        sessionDataManager.routineTransitionStepIndex = -1
        sessionDataManager.addRoutineStepResult(status: "")
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
