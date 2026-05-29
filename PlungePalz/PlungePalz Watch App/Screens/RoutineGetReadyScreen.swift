//
//  RoutineGetReadyScreen.swift
//  PlungePalz Watch App
//
//  Pre-step countdown before each routine step (Modality or Transition).
//

import SwiftUI
import Combine

struct RoutineGetReadyScreen: View {
    @ObservedObject var navigationManager: NavigationManager
    @EnvironmentObject var sessionDataManager: SessionDataManager
    @StateObject private var screenManager = WatchScreenManager()
    @StateObject private var backgroundTimerManager = BackgroundTimerManager.shared

    @State private var countdown: Double = 5.0
    @State private var totalTime: Double = 5.0
    @State private var timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    @State private var didNavigate: Bool = false
    @State private var isCancelled: Bool = false
    @State private var plannedStepStartDate: Date?

    // MARK: - Body

    var body: some View {
        let screenSize = screenManager.currentScreenSize

        let titleTopPadding    = WatchGlobalUIConfig.GetReadyCountdownTimer.titleTopPadding(for: screenSize)
        let titleFontSize      = WatchGlobalUIConfig.GetReadyCountdownTimer.titleFontSize(for: screenSize)
        let circleTopPadding   = WatchGlobalUIConfig.GetReadyCountdownTimer.circleTopPadding(for: screenSize)
        let circleSize         = WatchGlobalUIConfig.GetReadyCountdownTimer.circleSize(for: screenSize)
        let countdownFontSize  = WatchGlobalUIConfig.GetReadyCountdownTimer.countdownFontSize(for: screenSize)
        let buttonTopPadding   = WatchGlobalUIConfig.GetReadyCountdownTimer.buttonTopPadding(for: screenSize)
        let buttonFontSize     = WatchGlobalUIConfig.GetReadyCountdownTimer.buttonFontSize(for: screenSize)
        let buttonWidth        = WatchGlobalUIConfig.GetReadyCountdownTimer.buttonWidth(for: screenSize)
        let buttonHeight       = WatchGlobalUIConfig.GetReadyCountdownTimer.buttonHeight(for: screenSize)

        let isFirstStep = sessionDataManager.currentRoutineStepIndex == 0
        let stepLabel = sessionDataManager.currentRoutineStep.map { "Step \($0.step)" } ?? "Get Ready"

        VStack {
            Text(stepLabel)
                .font(.system(size: titleFontSize, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, titleTopPadding)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                    .frame(width: circleSize, height: circleSize)

                Circle()
                    .trim(from: 0, to: CGFloat(countdown / totalTime))
                    .stroke(Color(hex: "#00A8FF"), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: circleSize, height: circleSize)
                    .animation(.linear, value: countdown)

                Text("\(Int(ceil(countdown)))")
                    .font(.system(size: countdownFontSize, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.top, circleTopPadding)
            .padding(.bottom, buttonTopPadding)

            // Back is only allowed on the very first step
            if isFirstStep {
                Button(action: handleBack) {
                    Text("Go Back")
                        .font(.system(size: buttonFontSize, weight: .bold))
                        .foregroundStyle(countdown <= 1.0 ? .gray : .white)
                }
                .frame(width: buttonWidth, height: buttonHeight)
                .background(countdown <= 1.0 ? Color.gray.opacity(0.2) : Color.gray.opacity(0.5))
                .cornerRadius(50)
                .disabled(countdown <= 1.0)
            } else {
                // Placeholder to keep layout consistent
                Spacer().frame(width: buttonWidth, height: buttonHeight)
            }
        }
        .onReceive(timer) { _ in
            handleTick()
        }
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
        .onAppear {
            let stored = UserDefaults.standard.integer(forKey: "get_ready_timer_seconds")
            let duration = stored > 0 ? stored : 5
            countdown = Double(duration)
            totalTime = Double(duration)
            didNavigate = false
            isCancelled = false
            plannedStepStartDate = Date().addingTimeInterval(Double(duration))
            backgroundTimerManager.startGetReadyTimer(duration: Double(duration)) {
                DispatchQueue.main.async {
                    navigateToStep()
                }
            }
            startTimer()
        }
        .onDisappear {
            stopTimer()
            if !isCancelled {
                backgroundTimerManager.stopGetReadyTimer()
            }
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    }

    private func stopTimer() {
        timer.upstream.connect().cancel()
    }

    private func handleTick() {
        guard !isCancelled, let plannedStepStartDate else { return }
        countdown = max(0, plannedStepStartDate.timeIntervalSinceNow)
        if countdown <= 0.05 && !didNavigate {
            navigateToStep()
        }
    }

    // MARK: - Navigation

    private func navigateToStep() {
        guard !didNavigate else { return }
        didNavigate = true
        stopTimer()
        backgroundTimerManager.stopGetReadyTimer()
        sessionDataManager.currentRoutineStepPlannedStartDate = plannedStepStartDate ?? Date()

        guard let step = sessionDataManager.currentRoutineStep else {
            navigationManager.goToHome()
            return
        }
        if step.type == "Transition" {
            navigationManager.goToScreen(.routineTransition)
        } else {
            navigationManager.goToScreen(.routineModality)
        }
    }

    private func handleBack() {
        isCancelled = true
        backgroundTimerManager.stopGetReadyTimer()
        sessionDataManager.currentRoutineStepPlannedStartDate = nil
        stopTimer()
        navigationManager.goToScreen(.routineView)
    }
}

#Preview {
    RoutineGetReadyScreen(navigationManager: NavigationManager())
        .environmentObject(SessionDataManager())
}
