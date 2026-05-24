//
//  SessionDataManager.swift
//  PlungePalz Watch App
//
//  Updated to include activityType and temperature sensor support
//

import Foundation
import SwiftUI
import Combine

class SessionDataManager: ObservableObject {
    @Published var HRArray: [Int] = []
    @Published var epicTime: Int? = nil
    @Published var accumulatedSessionTime: Int = 0
    @Published var originalCountdownTimeSeconds: Int = 0
    @Published var currentTimerMode: String = "Countdown" // "Countdown" or "Countup"

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
            sessionTimeSeconds = params.setTimeS > 0 ? params.setTimeS : params.totalTimeS
        }
        sessionTempF = params.tempF
    }

    static func formatTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
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
