//
//  RoutineModalityScreen.swift
//  PlungePalz Watch App
//
//  Full activity timer with HealthKit for one Modality step in a routine.
//  Adapted from CountdownActivatedScreen.swift.
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
    @State private var countdown: Int = 0      // counts down from sLength
    @State private var epicTime: Int = 0       // counts up after countdown hits 0
    @State private var isEpicMode: Bool = false
    @State private var hrArray: [Int] = []
    @State private var currentHR: Int? = nil
    @State private var didAutoSave: Bool = false
    @State private var isSaving: Bool = false

    // Sub-page
    @State private var subPageIndex: Int = 0

    // MARK: - Computed

    private var step: RoutineStepModel? { sessionDataManager.currentRoutineStep }
    private var routine: RoutineModel? { sessionDataManager.activeRoutine }

    private var timerDisplay: String {
        if isEpicMode {
            let m = epicTime / 60; let s = epicTime % 60
            return String(format: "+%d:%02d", m, s)
        } else {
            let m = countdown / 60; let s = countdown % 60
            return String(format: "-%d:%02d", m, s)
        }
    }

    private var temperatureDisplay: String {
        guard let tf = step?.tempF else { return "--" }
        let unit = sessionDataManager.unitOfMeasure
        if unit == "Metric" {
            let c = (tf - 32) * 5 / 9
            return String(format: "%.1f°C", c)
        }
        return String(format: "%.1f°F", tf)
    }

    private var nextStepLabel: String {
        guard let routine = routine else { return "" }
        let nextIdx = sessionDataManager.currentRoutineStepIndex + 1
        guard nextIdx < routine.routineList.count else { return "Routine Complete" }
        let next = routine.routineList[nextIdx]
        return next.type == "Modality" ? (next.activityType ?? "Activity") : (next.stepNickname ?? "Transition")
    }

    private var progress: Double {
        guard let step = step, step.sLength > 0 else { return 0 }
        let elapsed = step.sLength - countdown
        return Double(elapsed) / Double(step.sLength)
    }

    private var hrBoxIndex: Int {
        guard let hr = currentHR else { return 0 }
        switch hr {
        case ...60: return 0
        case 61...80: return 1
        case 81...100: return 2
        case 101...120: return 3
        default: return 4
        }
    }

    private let hrBoxColors: [Color] = [
        Color(hex: "#A5A5A5"),
        Color(hex: "#95E4FF"),
        Color(hex: "#32DE84"),
        Color(hex: "#F1A100"),
        Color(hex: "#FF6E65")
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if subPageIndex == 0 {
                mainTimerPage
            } else {
                nextUpPage
            }

            // Sub-page dots (left edge)
            VStack(spacing: 6) {
                Circle()
                    .fill(subPageIndex == 0 ? Color.white : Color.gray.opacity(0.4))
                    .frame(width: 6, height: 6)
                Circle()
                    .fill(subPageIndex == 1 ? Color.white : Color.gray.opacity(0.4))
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.leading, 4)
        }
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.width < -30 {
                        withAnimation { subPageIndex = 1 }
                    } else if value.translation.width > 30 {
                        withAnimation { subPageIndex = 0 }
                    }
                }
        )
        .onAppear {
            guard let step = step else { return }
            countdown = step.sLength
            sessionDataManager.accumulatedSessionTime = 0
            didAutoSave = false
            isSaving = false
            hrArray = []
            isEpicMode = false
            epicTime = 0
            workoutManager.startWorkout()
            startTimers()
        }
        .onDisappear {
            stopTimers()
        }
        .onChange(of: navigationManager.routinePauseAction) { action in
            guard !action.isEmpty else { return }
            navigationManager.routinePauseAction = ""
            if action == "save" {
                commitAndSave()
            } else if action == "skip" {
                discardAndSkip()
            }
        }
    }

    // MARK: - Sub-pages

    private var mainTimerPage: some View {
        VStack(spacing: 4) {
            // Activity label
            Text(step?.activityType ?? "Activity")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: "#00A8FF"))
                .lineLimit(1)
                .padding(.top, 10)

            // Big timer
            Text(timerDisplay)
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .foregroundStyle(isEpicMode ? .yellow : .white)

            // Temperature
            Text(temperatureDisplay)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: "#8EC2FF"))

            // HR bar chart
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i <= hrBoxIndex ? hrBoxColors[hrBoxIndex] : Color.gray.opacity(0.2))
                        .frame(width: 12, height: CGFloat(8 + i * 4))
                }
                if let hr = currentHR {
                    Text("\(hr)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.leading, 2)
                }
            }
            .padding(.top, 2)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.3))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isEpicMode ? Color.yellow : Color(hex: "#00A8FF"))
                        .frame(width: isEpicMode ? geo.size.width : geo.size.width * progress)
                }
                .frame(height: 6)
            }
            .frame(height: 6)
            .padding(.horizontal, 16)

            // Pause button
            Button(action: handlePauseButton) {
                Text(isSaving ? "Saving..." : "PAUSE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 5)
                    .background(isSaving ? Color.gray : Color(hex: "#00A8FF"))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
            .padding(.bottom, 8)
        }
    }

    private var nextUpPage: some View {
        VStack(spacing: 8) {
            Text("NEXT UP")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.gray)
                .padding(.top, 20)

            Text(nextStepLabel)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            Spacer()

            // Step indicator
            if let routine = routine {
                let stepIdx = sessionDataManager.currentRoutineStepIndex
                Text("Step \(stepIdx + 1) of \(routine.stepsCount)")
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
            }

            Button(action: handlePauseButton) {
                Text("PAUSE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 5)
                    .background(Color(hex: "#00A8FF"))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 10)
        }
    }

    // MARK: - Timers

    private func startTimers() {
        // 1-second main timer
        secondsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            onSecondTick()
        }

        // HR sample timer: record current HR value every 5 seconds
        hrSampleTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            if let hr = currentHR, hr > 0 {
                hrArray.append(hr)
            }
        }

        // Start continuous HR monitoring via HealthKit
        if healthKitManager.isHeartRatePermissionGranted {
            healthKitManager.startHeartRateMonitoring { hrValue in
                DispatchQueue.main.async {
                    currentHR = hrValue
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
        sessionDataManager.accumulatedSessionTime += 1
        if isEpicMode {
            epicTime += 1
        } else if countdown > 0 {
            countdown -= 1
            if countdown == 0 {
                onCountdownComplete()
            }
        }
    }

    private func onCountdownComplete() {
        guard let routine = routine else { return }
        if routine.autoSaveOnModalityCompletion {
            guard !didAutoSave else { return }
            didAutoSave = true
            // Small delay so the "-0:00" frame renders
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                commitAndSave()
            }
        } else {
            isEpicMode = true
        }
    }

    // MARK: - Actions

    private func handlePauseButton() {
        stopTimers()
        navigationManager.routinePauseSource = "Modality"
        navigationManager.routinePauseAction = ""
        navigationManager.goToScreen(.routinePause)
    }

    func commitAndSave() {
        guard !isSaving else { return }
        isSaving = true
        stopTimers()
        sessionDataManager.storeStepStats(hrArray: hrArray)
        workoutManager.stopWorkout()
        postStepToAPI { success in
            sessionDataManager.addRoutineStepResult(status: success ? "Saved" : "Pending")
            advanceAfterSave()
        }
    }

    func discardAndSkip() {
        stopTimers()
        workoutManager.discardWorkout()
        sessionDataManager.addRoutineStepResult(status: "Skipped")
        if sessionDataManager.isLastRoutineStep {
            navigationManager.goToScreen(.routineRecap)
        } else {
            sessionDataManager.currentRoutineStepIndex += 1
            navigationManager.goToScreen(.routineGetReady)
        }
    }

    private func advanceAfterSave() {
        isSaving = false
        if sessionDataManager.isLastRoutineStep {
            navigationManager.goToScreen(.routineRecap)
        } else {
            sessionDataManager.currentRoutineStepIndex += 1
            sessionDataManager.resetSessionTracking()
            navigationManager.goToScreen(.routineGetReady)
        }
    }

    // MARK: - API

    private func postStepToAPI(completion: @escaping (Bool) -> Void) {
        guard let step = step, let routine = routine else {
            completion(false)
            return
        }

        let userId       = UserDefaults.standard.string(forKey: "userId") ?? "unknown"
        let d_id         = WKInterfaceDevice.current().name
        let d_mv         = WKInterfaceDevice.current().localizedModel
        let d_fv         = "WatchOS \(WKInterfaceDevice.current().systemVersion)"
        let d_i          = WKInterfaceDevice.current().identifierForVendor?.uuidString ?? "unknown"
        let tempF        = step.tempF ?? 0.0
        let totalTime    = sessionDataManager.accumulatedSessionTime
        let epicSecs     = isEpicMode ? epicTime : 0
        let latitude     = sessionDataManager.sessionLatitude
        let longitude    = sessionDataManager.sessionLongitude
        let hasGps       = (latitude != nil && longitude != nil)

        let formatter    = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        let timestampUTC = formatter.string(from: Date())
        formatter.timeZone = TimeZone.current
        let localTime    = formatter.string(from: Date())

        let payload: [String: Any] = [
            "d_id": d_id,
            "d_fv": d_fv,
            "d_mv": d_mv,
            "d_i": d_i,
            "user_id": userId,
            "original_set_time": step.sLength,
            "total_time": totalTime,
            "epic_time": epicSecs,
            "temp_f": tempF,
            "hr_array": hrArray,
            "timestamp_utc": timestampUTC,
            "localTime": localTime,
            "sessionLatitude": latitude ?? "",
            "sessionLongitude": longitude ?? "",
            "hasGpsData": hasGps,
            "activityType": step.activityType ?? "Activity",
            "routine_id": routine.routineId,
            "routine_line_id": step.routineLineId,
            "step_number": step.step
        ]

        // Save to pending_requests first
        savePendingRequest(payload: payload, timestampUTC: timestampUTC)

        let apiManager = APIs.shared
        guard let request = apiManager.createRequest(
            url: apiManager.saveSessionEndpoint,
            method: "POST",
            body: payload
        ) else {
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                let result = apiManager.handleAPIResponse(response as? HTTPURLResponse, data: data, error: error)
                if result.success {
                    removePendingRequest(timestampUTC: timestampUTC)
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }.resume()
    }

    private func savePendingRequest(payload: [String: Any], timestampUTC: String) {
        var pending = UserDefaults.standard.array(forKey: "pending_requests") as? [[String: Any]] ?? []
        let alreadyExists = pending.contains { ($0["timestamp_utc"] as? String) == timestampUTC }
        if !alreadyExists {
            pending.insert(payload, at: 0)
            UserDefaults.standard.set(pending, forKey: "pending_requests")
        }
    }

    private func removePendingRequest(timestampUTC: String) {
        var pending = UserDefaults.standard.array(forKey: "pending_requests") as? [[String: Any]] ?? []
        pending.removeAll { ($0["timestamp_utc"] as? String) == timestampUTC }
        UserDefaults.standard.set(pending, forKey: "pending_requests")
    }
}

#Preview {
    RoutineModalityScreen(navigationManager: NavigationManager())
        .environmentObject(SessionDataManager())
        .environmentObject(WorkoutManager())
}
