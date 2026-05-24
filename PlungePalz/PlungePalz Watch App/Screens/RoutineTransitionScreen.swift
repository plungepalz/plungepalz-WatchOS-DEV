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

    // MARK: - Computed

    private var currentStep: RoutineStepModel? { sessionDataManager.currentRoutineStep }

    private var nextStepLabel: String {
        guard let routine = sessionDataManager.activeRoutine else { return "" }
        let nextIdx = sessionDataManager.currentRoutineStepIndex + 1
        guard nextIdx < routine.routineList.count else { return "Routine Complete" }
        let next = routine.routineList[nextIdx]
        return next.type == "Modality" ? (next.activityType ?? "Activity") : (next.stepNickname ?? "Transition")
    }

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

        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Title — step nickname in accent blue
                Text(currentStep?.stepNickname ?? "Transition")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "#00A8FF"))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .padding(.horizontal, 8)

                Spacer()

                // Countdown timer
                Text(timeString)
                    .font(.system(size: 38, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)

                Spacer()

                // Next step label
                VStack(spacing: 2) {
                    Text("NEXT UP")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.gray)
                    Text(nextStepLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.bottom, 4)

                // Pause button
                Button(action: handlePauseButton) {
                    Text("PAUSE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#00A8FF"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 10)
            }

            // Paused overlay
            if isPaused {
                Color.black.opacity(0.7).ignoresSafeArea()
                Text("PAUSED")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
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
                // Resumed from pause — restart timer
                isPaused = false
                startTimer()
            }
        }
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
