//
//  RoutineModalityScreen.swift
//  PlungePalz Watch App
//
//  Full activity timer with HealthKit for one Modality step in a routine.
//  UI mirrors CountdownActivatedScreen exactly; stop button routes to RoutinePauseScreen.
//

import SwiftUI
import WatchKit
import HealthKit

struct RoutineModalityScreen: View {
    // MARK: - Dependencies
    @ObservedObject var navigationManager: NavigationManager
    @EnvironmentObject var sessionDataManager: SessionDataManager
    @EnvironmentObject var workoutManager: WorkoutManager
    @StateObject private var screenManager = WatchScreenManager()
    @StateObject private var healthKitManager = HealthKitManager.shared

    // MARK: - Timer State
    @State private var secondsTimer: Timer? = nil
    @State private var hrSampleTimer: Timer? = nil
    @State private var hrArray: [Int] = []
    @State private var currentHR: Int? = nil
    @State private var isSaving: Bool = false

    // Progress bar flag bounce
    @State private var showFlagBounce: [Bool] = [false, false, false, false, false]

    // Sub-page (crown snaps between timer and next-up)
    @State private var subPageIndex: Int = 0
    @State private var crownPage: Double = 0

    // MARK: - Constants (matching CountdownActivatedScreen)
    private let flagCheckpoints: [CGFloat] = [0.25, 0.5, 0.75, 1.0]
    private let flagIcons: [String] = ["flag", "flag", "flag", "flag.checkered"]
    private let progressGreen = Color(red: 50/255, green: 222/255, blue: 132/255)
    private let progressGray = Color(red: 165/255, green: 165/255, blue: 165/255)
    private let hrBoxColors: [Color] = [
        Color(hex: "#A5A5A5"),
        Color(hex: "#95E4FF"),
        Color(hex: "#32DE84"),
        Color(hex: "#F1A100"),
        Color(hex: "#FF6E65")
    ]

    // MARK: - Computed

    private var step: RoutineStepModel? { sessionDataManager.currentRoutineStep }
    private var routine: RoutineModel? { sessionDataManager.activeRoutine }

    private var isEpicMode: Bool { sessionDataManager.routineModalityIsEpicMode }

    private var timerDisplay: String {
        if isEpicMode {
            let epicTime = sessionDataManager.modalityEpicElapsedSeconds
            let m = epicTime / 60
            let s = epicTime % 60
            return String(format: "+%d:%02d", m, s)
        } else {
            let countdown = Int(ceil(sessionDataManager.modalityCountdownRemainingSeconds))
            let m = countdown / 60
            let s = countdown % 60
            return String(format: "-%d:%02d", m, s)
        }
    }

    private var temperatureDisplay: String {
        guard let tf = step?.tempF else { return "--" }
        return sessionDataManager.formatTempDisplayWithUnit(tempF: tf)
    }

    private var activityTemperatureIcon: String {
        ActivityTypes.thermometerIcon(for: step?.activityType)
    }

    private var activityTemperatureColor: Color {
        ActivityTypes.iconColor(for: step?.activityType)
    }

    private func formatDuration(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    private var nextStepLabel: String {
        guard let routine = routine else { return "" }
        let nextIdx = sessionDataManager.currentRoutineStepIndex + 1
        guard nextIdx < routine.routineList.count else { return "Routine Complete" }
        let next = routine.routineList[nextIdx]
        return next.type == "Modality" ? (next.activityType ?? "Activity") : (next.stepNickname ?? "Transition")
    }

    private var nextStepDuration: Int? {
        guard let routine = routine else { return nil }
        let nextIdx = sessionDataManager.currentRoutineStepIndex + 1
        guard nextIdx < routine.routineList.count else { return nil }
        return routine.routineList[nextIdx].sLength
    }

    private var progressFraction: CGFloat {
        guard let step = step, step.sLength > 0, !isEpicMode else {
            return isEpicMode ? 1.0 : 0.0
        }
        let remaining = sessionDataManager.modalityCountdownRemainingSeconds
        let elapsed = Double(step.sLength) - remaining
        return CGFloat(min(1, max(0, elapsed / Double(step.sLength))))
    }

    private func hrBoxIndex(for hr: Int?) -> Int {
        guard let hr = hr else { return 0 }
        switch hr {
        case ...60: return 0
        case 61...80: return 1
        case 81...100: return 2
        case 101...120: return 3
        default: return 4
        }
    }

    // MARK: - Body

    var body: some View {
        let screenSize = screenManager.currentScreenSize

        let stopIconTopCornerPadding = WatchGlobalUIConfig.CountdownActivatedScreen.stopIconTopCornerPadding(for: screenSize)
        let stopIconSize = WatchGlobalUIConfig.CountdownActivatedScreen.stopIconSize(for: screenSize)
        let topPaddingTimer = WatchGlobalUIConfig.CountdownActivatedScreen.topPaddingTimer(for: screenSize)
        let topPaddingTempText = WatchGlobalUIConfig.CountdownActivatedScreen.topPaddingTempText(for: screenSize)
        let topPaddingForProgressContainer = WatchGlobalUIConfig.CountdownActivatedScreen.topPaddingForProgressContainer(for: screenSize)
        let timerFontSize = WatchGlobalUIConfig.CountdownActivatedScreen.timerFontSize(for: screenSize)
        let temperatureFontSize = WatchGlobalUIConfig.CountdownActivatedScreen.temperatureFontSize(for: screenSize)
        let temperatureIconSize = WatchGlobalUIConfig.CountdownActivatedScreen.temperatureIconSize(for: screenSize)
        let dividerLine1TopPadding = WatchGlobalUIConfig.CountdownActivatedScreen.dividerLine1TopPadding(for: screenSize)
        let dividerLine1BottomPadding = WatchGlobalUIConfig.CountdownActivatedScreen.dividerLine1BottomPadding(for: screenSize)
        let dividerLine2TopPadding = WatchGlobalUIConfig.CountdownActivatedScreen.dividerLine2TopPadding(for: screenSize)
        let dividerLine2BottomPadding = WatchGlobalUIConfig.CountdownActivatedScreen.dividerLine2BottomPadding(for: screenSize)
        let dividerLine3TopPadding = WatchGlobalUIConfig.CountdownActivatedScreen.dividerLine3TopPadding(for: screenSize)
        let dividerLine3BottomPadding = WatchGlobalUIConfig.CountdownActivatedScreen.dividerLine3BottomPadding(for: screenSize)
        let paddingBetweenHeartRateAndBarChart = WatchGlobalUIConfig.CountdownActivatedScreen.paddingBetweenHeartRateAndBarChart(for: screenSize)

        GeometryReader { geo in
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()

                if subPageIndex == 0 {
                    VStack(spacing: 0) {
                        Text(timerDisplay)
                            .font(.system(size: timerFontSize, weight: .bold, design: .rounded))
                            .foregroundColor(isEpicMode ? .yellow : .white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, topPaddingTimer)

                        Rectangle()
                            .fill(Color.white)
                            .frame(height: 1)
                            .padding(.top, dividerLine1TopPadding)
                            .padding(.bottom, dividerLine1BottomPadding)

                        HStack {
                            Image(systemName: activityTemperatureIcon)
                                .foregroundColor(activityTemperatureColor)
                                .font(.system(size: temperatureIconSize, weight: .regular))
                            Text(temperatureDisplay)
                                .font(.system(size: temperatureFontSize, weight: .semibold))
                                .foregroundColor(activityTemperatureColor)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, topPaddingTempText)

                        Rectangle()
                            .fill(Color.white)
                            .frame(height: 1)
                            .padding(.top, dividerLine2TopPadding)
                            .padding(.bottom, dividerLine2BottomPadding)

                        let barWidth = geo.size.width * 0.95
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(progressGray)
                                .frame(width: barWidth, height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(progressGreen)
                                .frame(width: barWidth * progressFraction, height: 8)
                                .animation(.linear(duration: 0.5), value: progressFraction)
                        }
                        .frame(width: barWidth, height: 8)
                        .overlay(
                            ZStack {
                                ForEach(0..<flagCheckpoints.count, id: \.self) { idx in
                                    let icon = flagIcons[idx]
                                    let nudge: CGFloat = (icon == "flag") ? 2 : (icon == "flag.checkered" ? -1 : 0)
                                    let x = barWidth * flagCheckpoints[idx] + nudge
                                    if #available(watchOS 10.0, *) {
                                        Image(systemName: icon)
                                            .foregroundColor(progressFraction >= flagCheckpoints[idx] ? progressGreen : progressGray)
                                            .symbolEffect(
                                                .bounce.up.byLayer,
                                                options: .nonRepeating,
                                                value: showFlagBounce[idx]
                                            )
                                            .frame(width: 20, height: 20)
                                            .offset(x: x - 10, y: -16)
                                    } else {
                                        Image(systemName: icon)
                                            .foregroundColor(progressFraction >= flagCheckpoints[idx] ? progressGreen : progressGray)
                                            .frame(width: 20, height: 20)
                                            .offset(x: x - 10, y: -16)
                                    }
                                }
                            }, alignment: .leading
                        )
                        .padding(.bottom, 4)
                        .padding(.top, topPaddingForProgressContainer)

                        Rectangle()
                            .fill(Color.white)
                            .frame(height: 1)
                            .padding(.top, dividerLine3TopPadding)
                            .padding(.bottom, dividerLine3BottomPadding)

                        HStack(spacing: 8) {
                            if healthKitManager.isHeartRatePermissionGranted, let hr = currentHR, hr > 0 {
                                if #available(watchOS 11.0, *) {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.red)
                                        .symbolEffect(.breathe.pulse.byLayer, options: .repeat(.continuous))
                                } else {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.red)
                                }
                                Text("\(hr) BPM")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "heart.slash")
                                    .foregroundColor(.gray)
                                Text("-- BPM")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, paddingBetweenHeartRateAndBarChart)

                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(0..<5, id: \.self) { idx in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(hrBoxColors[idx])
                                    .frame(
                                        width: 22,
                                        height: hrBoxIndex(for: currentHR) == idx ? 28 : 8,
                                        alignment: .bottom
                                    )
                                    .animation(.easeInOut(duration: 0.4), value: hrBoxIndex(for: currentHR))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)

                        Spacer()
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                } else {
                    nextUpPage(geo: geo)
                }

                VStack {
                    HStack {
                        Button(action: handlePauseButton) {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: stopIconSize, weight: .medium))
                                .foregroundColor(isSaving ? .gray : .red)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isSaving)
                        .padding(.top, stopIconTopCornerPadding)
                        .padding(.leading, stopIconTopCornerPadding)

                        Spacer()
                    }
                    Spacer()
                }

                pageIndicatorOverlay(in: geo)
            }
            .ignoresSafeArea()
        }
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
        .focusable(true)
        .digitalCrownRotation(
            $crownPage,
            from: 0,
            through: 1,
            by: 1,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: crownPage) { _, newValue in
            let targetPage = Int(round(newValue))
            guard targetPage != subPageIndex else { return }
            withAnimation(.easeInOut(duration: 0.15)) {
                subPageIndex = targetPage
            }
        }
        .onChange(of: subPageIndex) { _, newValue in
            let crownTarget = Double(newValue)
            if abs(crownPage - crownTarget) > 0.01 {
                crownPage = crownTarget
            }
        }
        .onAppear {
            if sessionDataManager.hasModalitySnapshotForCurrentStep {
                restoreFromSnapshot()
                if workoutManager.isPaused {
                    workoutManager.resumeWorkout()
                }
                startTimers()
            } else {
                guard let step = step else { return }
                sessionDataManager.beginModalityStep(countdownSeconds: step.sLength)
                sessionDataManager.accumulatedSessionTime = 0
                hrArray = []
                showFlagBounce = [false, false, false, false, false]
                subPageIndex = 0
                crownPage = 0
                isSaving = false
                workoutManager.startWorkout()
                startTimers()
            }
        }
        .onDisappear {
            stopTimers()
        }
    }

    // MARK: - Next Up Page

    private func nextUpPage(geo: GeometryProxy) -> some View {
        let topInset: CGFloat = 44
        let horizontalInset: CGFloat = 28

        let screenSize = screenManager.currentScreenSize
        let nextUpPageTransitionTextFontSize = WatchGlobalUIConfig.RoutineModalityScreen.nextUpPageTransitionTextFontSize(for: screenSize)
        let nextUpPageTopPadding = WatchGlobalUIConfig.RoutineModalityScreen.nextUpPageTopPadding(for: screenSize)

        return VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: 12) {
                Text("NEXT UP")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.gray)
                    .tracking(0.6)

                VStack(spacing: 6) {
                    Text(nextStepLabel)
                        .font(.system(size: nextUpPageTransitionTextFontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    if let duration = nextStepDuration {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Color.green.opacity(0.8))
                            Text(formatDuration(seconds: duration))
                                .font(.system(size: 22, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.green.opacity(0.8))
                        }
                    }
                }

                if let routine = routine {
                    let nextIdx = sessionDataManager.currentRoutineStepIndex + 1
                    Text(nextIdx < routine.routineList.count
                         ? "Step \(nextIdx + 1) of \(routine.stepsCount)"
                         : "Final step")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.gray)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, horizontalInset)
            .padding(.top, nextUpPageTopPadding)

            Spacer(minLength: 0)
        }
        .padding(.top, topInset)
        .frame(width: geo.size.width, height: geo.size.height)
    }

    // MARK: - Page Indicator

    private func pageIndicatorOverlay(in geo: GeometryProxy) -> some View {
        let screenSize = screenManager.currentScreenSize
        let dotSize: CGFloat = 6
        let dotSpacing: CGFloat = 6
        let leading: CGFloat = WatchGlobalUIConfig.RoutineModalityScreen.pageIndicatorOverlayXPositionLeading(for: screenSize)
        let bottom: CGFloat = WatchGlobalUIConfig.RoutineModalityScreen.pageIndicatorOverlayYPositionBottom(for: screenSize)
        let stackHeight = dotSize * 2 + dotSpacing
        let centerX = leading + dotSize / 2
        let centerY = geo.size.height - bottom - stackHeight / 2

        return VStack(spacing: dotSpacing) {
            pageIndicatorDot(isActive: subPageIndex == 0)
            pageIndicatorDot(isActive: subPageIndex == 1)
        }
        .position(x: centerX, y: centerY)
    }

    private func pageIndicatorDot(isActive: Bool) -> some View {
        Circle()
            .fill(isActive ? Color.white : Color.gray.opacity(0.4))
            .frame(width: 6, height: 6)
    }

    // MARK: - Snapshot Helpers

    private func restoreFromSnapshot() {
        hrArray = sessionDataManager.routineModalityHRArray
        showFlagBounce = sessionDataManager.routineModalityShowFlagBounce
        subPageIndex = sessionDataManager.routineModalitySubPageIndex
        crownPage = Double(subPageIndex)
        isSaving = false
    }

    private func syncSnapshotToSession() {
        sessionDataManager.routineModalityHRArray = hrArray
        sessionDataManager.routineModalityShowFlagBounce = showFlagBounce
        sessionDataManager.routineModalitySubPageIndex = subPageIndex
    }

    // MARK: - Timers

    private func startTimers() {
        secondsTimer?.invalidate()
        secondsTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            onSecondTick()
        }

        hrSampleTimer?.invalidate()
        hrSampleTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            if let hr = currentHR, hr > 0 {
                hrArray.append(hr)
                sessionDataManager.routineModalityHRArray = hrArray
            }
        }

        if healthKitManager.isHeartRatePermissionGranted {
            healthKitManager.startHeartRateMonitoring { hrValue in
                DispatchQueue.main.async {
                    self.currentHR = hrValue
                    if hrValue > 0 {
                        self.workoutManager.addHeartRateData(hrValue, timestamp: Date())
                    }
                }
            }
        }
    }

    private func stopTimers() {
        secondsTimer?.invalidate(); secondsTimer = nil
        hrSampleTimer?.invalidate(); hrSampleTimer = nil
        healthKitManager.forceStopAllHealthKitQueries()
    }

    private func onSecondTick() {
        guard !isSaving else { return }
        sessionDataManager.accumulatedSessionTime = sessionDataManager.modalityAccumulatedSessionTime

        if !sessionDataManager.routineModalityIsEpicMode,
           !sessionDataManager.routineModalityDidAutoSave,
           sessionDataManager.modalityCountdownRemainingSeconds <= 0 {
            onCountdownComplete()
        }
        checkFlagBounce()
    }

    private func checkFlagBounce() {
        for idx in 0..<flagCheckpoints.count {
            if !showFlagBounce[idx] && progressFraction >= flagCheckpoints[idx] {
                DispatchQueue.main.async {
                    self.showFlagBounce[idx] = true
                    self.sessionDataManager.routineModalityShowFlagBounce = self.showFlagBounce
                }
            }
        }
    }

    private func onCountdownComplete() {
        guard let routine = routine else { return }
        if routine.autoSaveOnModalityCompletion {
            guard !sessionDataManager.routineModalityDidAutoSave else { return }
            sessionDataManager.routineModalityDidAutoSave = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                commitAndSave()
            }
        } else {
            sessionDataManager.routineModalityDidAutoSave = true
            sessionDataManager.enterModalityEpicMode()
        }
    }

    // MARK: - Actions

    private func handlePauseButton() {
        syncSnapshotToSession()
        stopTimers()
        if workoutManager.isActive && !workoutManager.isPaused {
            workoutManager.pauseWorkout()
        }
        navigationManager.routinePauseSource = "Modality"
        navigationManager.goToScreen(.routinePause)
    }

    func commitAndSave() {
        guard !isSaving else { return }
        isSaving = true
        stopTimers()
        syncSnapshotToSession()
        sessionDataManager.performOptimisticModalitySave(
            workoutManager: workoutManager,
            navigationManager: navigationManager
        )
    }
}

#Preview {
    RoutineModalityScreen(navigationManager: NavigationManager())
        .environmentObject(SessionDataManager())
        .environmentObject(WorkoutManager())
}
