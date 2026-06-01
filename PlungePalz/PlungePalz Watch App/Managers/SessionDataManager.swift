//
//  SessionDataManager.swift
//  PlungePalz Watch App
//
//  Updated to include activityType and temperature sensor support
//

import Foundation
import SwiftUI
import Combine
import WatchKit

class SessionDataManager: ObservableObject {
    @Published var HRArray: [Int] = []
    @Published var epicTime: Int? = nil
    @Published var accumulatedSessionTime: Int = 0
    @Published var originalCountdownTimeSeconds: Int = 0
    @Published var currentTimerMode: String = "Countdown" // "Countdown" or "Countup"
    @Published var activityStartDate: Date?

    // Activity Type - Default to "Cold Plunge"
    @Published var activityType: String = "Cold Plunge"

    // Per-activity settings from startup API
    @Published var activityTypeSettings: [ActivityTypeSetting] = []
    @Published var unitOfMeasure: String = "Imperial"

    // Working session values for the current activity flow (temp always stored in °F)
    @Published var sessionTimeSeconds: Int = 0
    @Published var sessionTempF: Double = 0

    // Temperature Sensor Data (Ultra Watch only)
    @Published var SW_Temp_Array_F: [String] = []

    // Settings from API
    @Published var useSmartwatchTempSensor: Bool = false
    @Published var allowSmartwatchGPSlocator: Bool = true

    // GPS Location Data
    @Published var sessionLongitude: Double? = nil
    @Published var sessionLatitude: Double? = nil

    // MARK: - Routine Data (parsed from startup API)
    @Published var routineData: [RoutineModel] = []

    // MARK: - Active Routine Execution State
    @Published var activeRoutine: RoutineModel? = nil
    @Published var currentRoutineStepIndex: Int = 0
    @Published var routineStepResults: [RoutineStepResult] = []
    @Published var routineStepStats: [Int: RoutineStepStats] = [:]
    @Published var routineStartISO: String?
    @Published var currentRoutineStepPlannedStartDate: Date?

    // MARK: - Routine Step Execution Snapshots (survive pause navigation)
    @Published var routineTransitionEndDate: Date?
    @Published var routineTransitionTotalSeconds: Int = 0
    @Published var routineTransitionStepIndex: Int = -1
    @Published var routineTransitionPausedRemainingSeconds: Double?

    @Published var routineModalityHasSnapshot: Bool = false
    @Published var routineModalityStepIndex: Int = -1
    @Published var routineModalityCountdownEndDate: Date?
    @Published var routineModalityEpicStartDate: Date?
    @Published var routineModalityInitialCountdown: Int = 0
    @Published var routineModalityIsEpicMode: Bool = false
    @Published var routineModalityHRArray: [Int] = []
    @Published var routineModalityShowFlagBounce: [Bool] = [false, false, false, false, false]
    @Published var routineModalitySubPageIndex: Int = 0
    @Published var routineModalityDidAutoSave: Bool = false
    @Published var routineModalitySessionStartDate: Date?
    @Published var routineModalityActivityStartDate: Date?
    @Published var routineModalityAccumulatedActiveSeconds: Double = 0
    @Published var routineModalityPausedCountdownRemainingSeconds: Double?
    @Published var routineModalityPausedEpicElapsedSeconds: Double?

    // MARK: - Activity Type Settings Helpers

    func settings(for activityType: String) -> ActivityTypeSetting? {
        activityTypeSettings.first { $0.activityType == activityType }
    }

    var currentActivitySettings: ActivityTypeSetting? {
        settings(for: activityType)
    }

    var hasUseLastForCurrentActivity: Bool {
        currentActivitySettings?.hasUseLast ?? false
    }

    var isCurrentActivityCountdown: Bool {
        currentActivitySettings?.isCountdown ?? true
    }

    func applyUseLastSession() {
        guard let params = currentActivitySettings?.latestSessionParams else { return }
        if currentActivitySettings?.isCountdown == true {
            // Countdown: use configured set time (e.g. 2:00), not elapsed total from last session
            sessionTimeSeconds = params.setTimeS > 0 ? params.setTimeS : params.totalTimeS
        } else {
            sessionTimeSeconds = params.totalTimeS
        }
        sessionTempF = params.tempF
    }

    /// Seconds to show for "Use Last" subtitle and countdown preset (set time for countdown activities).
    func useLastDisplayTimeSeconds(for params: LatestSessionParams) -> Int {
        if isCurrentActivityCountdown {
            return params.setTimeS > 0 ? params.setTimeS : params.totalTimeS
        }
        return params.totalTimeS
    }

    static func formatTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    func formattedLocalTime(for date: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date ?? Date())
    }

    func formattedRoutineStartISO(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.string(from: date)
    }

    func formatTempDisplay(tempF: Double) -> String {
        if unitOfMeasure == "Metric" {
            let celsius = (tempF - 32) * 5 / 9
            return String(format: "%.1f ℃", celsius)
        }
        return String(format: "%.1f ℉", tempF)
    }

    func formatTempDisplayWithUnit(tempF: Double) -> String {
        if unitOfMeasure == "Metric" {
            let celsius = (tempF - 32) * 5 / 9
            return String(format: "%.1f °C", celsius)
        }
        return String(format: "%.1f °F", tempF)
    }

    // MARK: - Routine Computed Helpers
    var currentRoutineStep: RoutineStepModel? {
        guard let r = activeRoutine,
              currentRoutineStepIndex < r.routineList.count else { return nil }
        return r.routineList[currentRoutineStepIndex]
    }

    var isLastRoutineStep: Bool {
        guard let r = activeRoutine else { return false }
        return currentRoutineStepIndex >= r.stepsCount - 1
    }

    // MARK: - Routine State Methods
    func resetRoutineState() {
        activeRoutine = nil
        currentRoutineStepIndex = 0
        routineStepResults = []
        routineStepStats = [:]
        routineStartISO = nil
        currentRoutineStepPlannedStartDate = nil
        clearRoutineExecutionSnapshots()
    }

    func clearRoutineExecutionSnapshots() {
        routineTransitionEndDate = nil
        routineTransitionTotalSeconds = 0
        routineTransitionStepIndex = -1
        routineTransitionPausedRemainingSeconds = nil
        clearRoutineModalitySnapshot()
    }

    func clearRoutineModalitySnapshot() {
        routineModalityHasSnapshot = false
        routineModalityStepIndex = -1
        routineModalityCountdownEndDate = nil
        routineModalityEpicStartDate = nil
        routineModalityInitialCountdown = 0
        routineModalityIsEpicMode = false
        routineModalityHRArray = []
        routineModalityShowFlagBounce = [false, false, false, false, false]
        routineModalitySubPageIndex = 0
        routineModalityDidAutoSave = false
        routineModalitySessionStartDate = nil
        routineModalityActivityStartDate = nil
        routineModalityAccumulatedActiveSeconds = 0
        routineModalityPausedCountdownRemainingSeconds = nil
        routineModalityPausedEpicElapsedSeconds = nil
    }

    var hasTransitionSnapshotForCurrentStep: Bool {
        routineTransitionStepIndex == currentRoutineStepIndex
            && (routineTransitionEndDate != nil || routineTransitionPausedRemainingSeconds != nil)
    }

    var hasModalitySnapshotForCurrentStep: Bool {
        routineModalityHasSnapshot && routineModalityStepIndex == currentRoutineStepIndex
    }

    var modalityAccumulatedSessionTime: Int {
        let currentActiveSegment = routineModalitySessionStartDate.map { Date().timeIntervalSince($0) } ?? 0
        return max(0, Int(routineModalityAccumulatedActiveSeconds + currentActiveSegment))
    }

    var modalityEpicElapsedSeconds: Int {
        if let pausedEpicElapsed = routineModalityPausedEpicElapsedSeconds {
            return max(0, Int(pausedEpicElapsed))
        }
        guard routineModalityIsEpicMode, let start = routineModalityEpicStartDate else { return 0 }
        return max(0, Int(Date().timeIntervalSince(start)))
    }

    var modalityCountdownRemainingSeconds: Double {
        if let pausedRemaining = routineModalityPausedCountdownRemainingSeconds {
            return max(0, pausedRemaining)
        }
        guard !routineModalityIsEpicMode, let endDate = routineModalityCountdownEndDate else { return 0 }
        return max(0, endDate.timeIntervalSinceNow)
    }

    var transitionRemainingSeconds: Double {
        if let pausedRemaining = routineTransitionPausedRemainingSeconds {
            return max(0, pausedRemaining)
        }
        guard let endDate = routineTransitionEndDate else { return 0 }
        return max(0, endDate.timeIntervalSinceNow)
    }

    func beginTransitionStep(totalSeconds: Int, startDate: Date = Date()) {
        routineTransitionStepIndex = currentRoutineStepIndex
        routineTransitionTotalSeconds = totalSeconds
        routineTransitionEndDate = startDate.addingTimeInterval(TimeInterval(totalSeconds))
        routineTransitionPausedRemainingSeconds = nil
    }

    func beginModalityStep(countdownSeconds: Int, startDate: Date = Date()) {
        routineModalityHasSnapshot = true
        routineModalityStepIndex = currentRoutineStepIndex
        routineModalityInitialCountdown = countdownSeconds
        routineModalityCountdownEndDate = startDate.addingTimeInterval(TimeInterval(countdownSeconds))
        routineModalityEpicStartDate = nil
        routineModalityIsEpicMode = false
        routineModalityHRArray = []
        routineModalityShowFlagBounce = [false, false, false, false, false]
        routineModalitySubPageIndex = 0
        routineModalityDidAutoSave = false
        routineModalitySessionStartDate = startDate
        routineModalityActivityStartDate = startDate
        routineModalityAccumulatedActiveSeconds = 0
        routineModalityPausedCountdownRemainingSeconds = nil
        routineModalityPausedEpicElapsedSeconds = nil
    }

    func enterModalityEpicMode() {
        routineModalityIsEpicMode = true
        routineModalityEpicStartDate = Date()
        routineModalityCountdownEndDate = nil
        routineModalityPausedCountdownRemainingSeconds = nil
        routineModalityPausedEpicElapsedSeconds = nil
    }

    func pauseTransitionStep() {
        guard hasTransitionSnapshotForCurrentStep,
              routineTransitionPausedRemainingSeconds == nil else { return }
        routineTransitionPausedRemainingSeconds = transitionRemainingSeconds
    }

    func resumeTransitionStep() {
        guard hasTransitionSnapshotForCurrentStep,
              let pausedRemaining = routineTransitionPausedRemainingSeconds else { return }
        routineTransitionEndDate = Date().addingTimeInterval(pausedRemaining)
        routineTransitionPausedRemainingSeconds = nil
    }

    func pauseModalityStep() {
        guard hasModalitySnapshotForCurrentStep,
              routineModalityPausedCountdownRemainingSeconds == nil,
              routineModalityPausedEpicElapsedSeconds == nil else { return }

        routineModalityAccumulatedActiveSeconds = Double(modalityAccumulatedSessionTime)
        routineModalitySessionStartDate = nil

        if routineModalityIsEpicMode {
            routineModalityPausedEpicElapsedSeconds = Double(modalityEpicElapsedSeconds)
        } else {
            routineModalityPausedCountdownRemainingSeconds = modalityCountdownRemainingSeconds
        }
    }

    func resumeModalityStep() {
        guard hasModalitySnapshotForCurrentStep else { return }

        if routineModalityIsEpicMode {
            if let pausedEpicElapsed = routineModalityPausedEpicElapsedSeconds {
                routineModalityEpicStartDate = Date().addingTimeInterval(-pausedEpicElapsed)
                routineModalityPausedEpicElapsedSeconds = nil
                routineModalitySessionStartDate = Date()
            }
        } else if let pausedRemaining = routineModalityPausedCountdownRemainingSeconds {
            routineModalityCountdownEndDate = Date().addingTimeInterval(pausedRemaining)
            routineModalityPausedCountdownRemainingSeconds = nil
            routineModalitySessionStartDate = Date()
        } else if routineModalitySessionStartDate == nil {
            routineModalitySessionStartDate = Date()
        }
    }

    func skipCurrentTransitionStep(navigationManager: NavigationManager) {
        routineTransitionEndDate = nil
        routineTransitionStepIndex = -1
        routineTransitionPausedRemainingSeconds = nil
        addRoutineStepResult(status: "Skipped")
        if isLastRoutineStep {
            navigationManager.goToScreen(.routineRecap)
        } else {
            currentRoutineStepIndex += 1
            navigationManager.goToScreen(.routineGetReady)
        }
    }

    func skipCurrentModalityStep(workoutManager: WorkoutManager, navigationManager: NavigationManager) {
        clearRoutineModalitySnapshot()
        workoutManager.discardWorkout()
        addRoutineStepResult(status: "Skipped")
        if isLastRoutineStep {
            navigationManager.goToScreen(.routineRecap)
        } else {
            currentRoutineStepIndex += 1
            navigationManager.goToScreen(.routineGetReady)
        }
    }

    func updateRoutineStepResultStatus(step: Int, status: String) {
        guard let index = routineStepResults.firstIndex(where: { $0.step == step }) else { return }
        routineStepResults[index].status = status
    }

    func performOptimisticModalitySave(
        workoutManager: WorkoutManager,
        navigationManager: NavigationManager
    ) {
        guard let step = currentRoutineStep, let routine = activeRoutine else { return }

        let hrSamples = routineModalityHRArray
        let totalTime = modalityAccumulatedSessionTime
        let epicSecs = routineModalityIsEpicMode ? modalityEpicElapsedSeconds : 0
        let stepNumber = step.step

        accumulatedSessionTime = totalTime
        storeStepStats(hrArray: hrSamples)
        addRoutineStepResult(status: "Pending")

        workoutManager.completelyEndSession()

        postRoutineModalityStep(
            step: step,
            routine: routine,
            hrArray: hrSamples,
            totalTime: totalTime,
            epicSecs: epicSecs
        ) { [weak self] success in
            self?.updateRoutineStepResultStatus(step: stepNumber, status: success ? "Saved" : "Pending")
        }

        clearRoutineModalitySnapshot()

        if isLastRoutineStep {
            navigationManager.goToScreen(.routineRecap)
        } else {
            currentRoutineStepIndex += 1
            resetSessionTracking()
            navigationManager.goToScreen(.routineGetReady)
        }
    }

    func postRoutineModalityStep(
        step: RoutineStepModel,
        routine: RoutineModel,
        hrArray: [Int],
        totalTime: Int,
        epicSecs: Int,
        completion: @escaping (Bool) -> Void
    ) {
        let userId = UserDefaults.standard.string(forKey: "userId") ?? "unknown"
        let d_id = WKInterfaceDevice.current().name
        let d_mv = WKInterfaceDevice.current().localizedModel
        let d_fv = "WatchOS \(WKInterfaceDevice.current().systemVersion)"
        let d_i = WKInterfaceDevice.current().identifierForVendor?.uuidString ?? "unknown"
        let tempF = step.tempF ?? 0.0
        let latitude = sessionLatitude
        let longitude = sessionLongitude
        let hasGps = (latitude != nil && longitude != nil)

        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        let timestampUTC = formatter.string(from: Date())
        let localTime = formattedLocalTime(for: routineModalityActivityStartDate)
        let routineStart = routineStartISO ?? formattedRoutineStartISO()
        routineStartISO = routineStart

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
            "routine_start_iso": routineStart,
            "routine_line_id": step.routineLineId,
            "step_number": step.step
        ]

        saveRoutinePendingRequest(payload: payload, timestampUTC: timestampUTC)

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
                let result = self.apiManager.handleAPIResponse(response as? HTTPURLResponse, data: data, error: error)
                if result.success {
                    self.removeRoutinePendingRequest(timestampUTC: timestampUTC)
                }
                completion(result.success)
            }
        }.resume()
    }

    private func saveRoutinePendingRequest(payload: [String: Any], timestampUTC: String) {
        var pending = UserDefaults.standard.array(forKey: "pending_requests") as? [[String: Any]] ?? []
        let alreadyExists = pending.contains { ($0["timestamp_utc"] as? String) == timestampUTC }
        if !alreadyExists {
            pending.insert(payload, at: 0)
            UserDefaults.standard.set(pending, forKey: "pending_requests")
        }
    }

    private func removeRoutinePendingRequest(timestampUTC: String) {
        var pending = UserDefaults.standard.array(forKey: "pending_requests") as? [[String: Any]] ?? []
        pending.removeAll { ($0["timestamp_utc"] as? String) == timestampUTC }
        UserDefaults.standard.set(pending, forKey: "pending_requests")
    }

    func storeStepStats(hrArray: [Int]) {
        guard let step = currentRoutineStep else { return }
        let minHR = hrArray.min() ?? 0
        let maxHR = hrArray.max() ?? 0
        let avgHR = hrArray.isEmpty ? 0 : hrArray.reduce(0, +) / hrArray.count
        routineStepStats[step.step] = RoutineStepStats(
            totalTime: accumulatedSessionTime,
            tempF: step.tempF ?? 98.6,
            minHR: minHR,
            maxHR: maxHR,
            avgHR: avgHR
        )
    }

    func addRoutineStepResult(status: String) {
        guard let step = currentRoutineStep else { return }
        routineStepResults.append(RoutineStepResult(
            step: step.step,
            type: step.type,
            activityType: step.activityType ?? "Activity",
            status: status
        ))
    }

    @StateObject private var apiManager = APIs.shared

    func fetchLastSessionData(completion: @escaping (Bool) -> Void = { _ in }) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            #if DEBUG
            print("No userId found in storage, cannot fetch session data")
            #endif
            completion(false)
            return
        }

        let baseURL = apiManager.getStartupDataForSmartWatchEndpoint
        let urlString = "\(baseURL)?userId=\(userId)"

        guard let url = URL(string: urlString) else {
            #if DEBUG
            print("Invalid URL: \(urlString)")
            #endif
            completion(false)
            return
        }

        #if DEBUG
        print("Fetching session data from: \(urlString)")
        #endif

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    #if DEBUG
                    print("API request failed with error: \(error)")
                    print("📦 Loading cached data due to network error")
                    #endif
                    self.loadCachedData()
                    completion(false)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    #if DEBUG
                    print("Invalid response type")
                    print("📦 Loading cached data due to invalid response")
                    #endif
                    self.loadCachedData()
                    completion(false)
                    return
                }

                #if DEBUG
                print("API response status code: \(httpResponse.statusCode)")
                #endif

                guard (200...299).contains(httpResponse.statusCode) else {
                    #if DEBUG
                    print("HTTP error status code: \(httpResponse.statusCode)")
                    print("📦 Loading cached data due to HTTP error")
                    #endif
                    self.loadCachedData()
                    completion(false)
                    return
                }

                guard let data = data else {
                    #if DEBUG
                    print("No data received from API")
                    print("📦 Loading cached data due to no data")
                    #endif
                    self.loadCachedData()
                    completion(false)
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        #if DEBUG
                        print("Session data API response: \(json)")
                        #endif

                        guard let unitOfMeasure = json["unitOfMeasure"] as? String else {
                            #if DEBUG
                            print("❌ unitOfMeasure missing from API response")
                            print("📦 Loading cached data due to missing required fields")
                            #endif
                            self.loadCachedData()
                            completion(false)
                            return
                        }

                        self.unitOfMeasure = unitOfMeasure
                        UserDefaults.standard.set(unitOfMeasure, forKey: "unitOfMeasure")

                        if let settingsRaw = json["activityTypeSettings"] as? [[String: Any]] {
                            do {
                                let settingsJSON = try JSONSerialization.data(withJSONObject: settingsRaw)
                                let decoded = try JSONDecoder().decode([ActivityTypeSetting].self, from: settingsJSON)
                                self.activityTypeSettings = decoded
                                UserDefaults.standard.set(settingsRaw, forKey: "activityTypeSettings")
                                #if DEBUG
                                print("✅ Loaded \(decoded.count) activity type setting(s) from API (cached)")
                                #endif
                            } catch {
                                #if DEBUG
                                print("⚠️ Failed to decode activityTypeSettings: \(error)")
                                #endif
                            }
                        }

                        if let useTempSensor = json["useSmartwatchTempSensor"] as? Bool {
                            self.useSmartwatchTempSensor = useTempSensor
                            UserDefaults.standard.set(useTempSensor, forKey: "useSmartwatchTempSensor")
                        } else {
                            self.useSmartwatchTempSensor = false
                            UserDefaults.standard.set(false, forKey: "useSmartwatchTempSensor")
                        }

                        if let allowGPS = json["allowSmartwatchGPSlocator"] as? Bool {
                            self.allowSmartwatchGPSlocator = allowGPS
                            UserDefaults.standard.set(allowGPS, forKey: "allowSmartwatchGPSlocator")
                        } else {
                            self.allowSmartwatchGPSlocator = true
                            UserDefaults.standard.set(true, forKey: "allowSmartwatchGPSlocator")
                        }

                        if let getReadyTimerSeconds = json["get_ready_timer_seconds"] as? Int {
                            UserDefaults.standard.set(getReadyTimerSeconds, forKey: "get_ready_timer_seconds")
                        } else {
                            UserDefaults.standard.set(5, forKey: "get_ready_timer_seconds")
                        }

                        if let isUserSubscribed = json["isUserSubscribed"] as? Bool {
                            UserDefaults.standard.set(isUserSubscribed, forKey: "isUserSubscribed")
                        } else {
                            UserDefaults.standard.set(false, forKey: "isUserSubscribed")
                        }

                        if let routineDataRaw = json["routine_data"] as? [[String: Any]] {
                            do {
                                let routineDataJSON = try JSONSerialization.data(withJSONObject: routineDataRaw)
                                let decoded = try JSONDecoder().decode([RoutineModel].self, from: routineDataJSON)
                                self.routineData = decoded
                                UserDefaults.standard.set(routineDataRaw, forKey: "routineData")
                                #if DEBUG
                                print("✅ Loaded \(decoded.count) routine(s) from API (cached)")
                                #endif
                            } catch {
                                #if DEBUG
                                print("⚠️ Failed to decode routine_data: \(error)")
                                #endif
                                self.routineData = []
                            }
                        } else {
                            self.routineData = []
                        }

                        #if DEBUG
                        print("✅ Startup data fetched and stored successfully")
                        print("unitOfMeasure: \(unitOfMeasure)")
                        #endif

                        completion(true)
                    } else {
                        #if DEBUG
                        print("❌ Failed to parse JSON - invalid format")
                        #endif
                        self.loadCachedData()
                        completion(false)
                    }
                } catch {
                    #if DEBUG
                    print("❌ Failed to parse JSON response: \(error)")
                    #endif
                    self.loadCachedData()
                    completion(false)
                }
            }
        }.resume()
    }

    // MARK: - Cache Management

    func loadCachedData() {
        #if DEBUG
        print("📦 Loading cached startup data from UserDefaults")
        #endif

        if let cachedUnit = UserDefaults.standard.string(forKey: "unitOfMeasure") {
            self.unitOfMeasure = cachedUnit
            #if DEBUG
            print("✅ Loaded cached unitOfMeasure: \(cachedUnit)")
            #endif
        }

        if let settingsRaw = UserDefaults.standard.array(forKey: "activityTypeSettings") as? [[String: Any]] {
            do {
                let settingsJSON = try JSONSerialization.data(withJSONObject: settingsRaw)
                let decoded = try JSONDecoder().decode([ActivityTypeSetting].self, from: settingsJSON)
                self.activityTypeSettings = decoded
                #if DEBUG
                print("✅ Loaded \(decoded.count) cached activity type setting(s)")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ Failed to decode cached activityTypeSettings: \(error)")
                #endif
            }
        }

        if UserDefaults.standard.object(forKey: "useSmartwatchTempSensor") != nil {
            self.useSmartwatchTempSensor = UserDefaults.standard.bool(forKey: "useSmartwatchTempSensor")
        }

        if UserDefaults.standard.object(forKey: "allowSmartwatchGPSlocator") != nil {
            self.allowSmartwatchGPSlocator = UserDefaults.standard.bool(forKey: "allowSmartwatchGPSlocator")
        }

        if let routineDataRaw = UserDefaults.standard.array(forKey: "routineData") as? [[String: Any]] {
            do {
                let routineDataJSON = try JSONSerialization.data(withJSONObject: routineDataRaw)
                let decoded = try JSONDecoder().decode([RoutineModel].self, from: routineDataJSON)
                self.routineData = decoded
            } catch {
                self.routineData = []
            }
        }

        #if DEBUG
        print("📦 Finished loading cached data")
        #endif
    }

    func resetSessionTracking() {
        #if DEBUG
        print("🔄 SessionDataManager: Resetting session tracking")
        #endif

        HRArray = []
        SW_Temp_Array_F = []
        epicTime = nil
        accumulatedSessionTime = 0
        originalCountdownTimeSeconds = 0
        currentTimerMode = "Countdown"
        activityStartDate = nil
        sessionTimeSeconds = 0
        sessionTempF = 0

        #if DEBUG
        print("✅ Session tracking reset complete")
        #endif
    }

    func addHeartRate(_ hr: Int) {
        HRArray.append(hr)
        #if DEBUG
        print("❤️ Heart rate added: \(hr), Total samples: \(HRArray.count)")
        #endif
    }

    // MARK: - Temperature Statistics
    func getAverageTemperature() -> String {
        guard !SW_Temp_Array_F.isEmpty else { return "0.0" }

        let validTemps = SW_Temp_Array_F.compactMap { Double($0) }
        guard !validTemps.isEmpty else { return "0.0" }

        let sum = validTemps.reduce(0.0, +)
        let average = sum / Double(validTemps.count)
        return String(format: "%.1f", average)
    }

    func getMinTemperature() -> String {
        guard !SW_Temp_Array_F.isEmpty else { return "0.0" }

        let validTemps = SW_Temp_Array_F.compactMap { Double($0) }
        guard !validTemps.isEmpty else { return "0.0" }

        let minTemp = validTemps.min() ?? 0.0
        return String(format: "%.1f", minTemp)
    }

    func getMaxTemperature() -> String {
        guard !SW_Temp_Array_F.isEmpty else { return "0.0" }

        let validTemps = SW_Temp_Array_F.compactMap { Double($0) }
        guard !validTemps.isEmpty else { return "0.0" }

        let maxTemp = validTemps.max() ?? 0.0
        return String(format: "%.1f", maxTemp)
    }
}
