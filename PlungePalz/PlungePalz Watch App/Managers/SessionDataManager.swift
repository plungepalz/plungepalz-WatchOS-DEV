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
    @Published var lastSessionData: [String: String]? = nil
    @Published var HRArray: [Int] = []
    @Published var epicTime: Int? = nil
    @Published var accumulatedSessionTime: Int = 0
    @Published var originalCountdownTimeSeconds: Int = 0
    @Published var currentTimerMode: String = "Countdown" // "Countdown" or "Countup"
    
    // Activity Type - Default to "Cold Plunge"
    @Published var activityType: String = "Cold Plunge" // Options: "Cold Plunge", "Sauna", "Cold Shower"
    
    // Temperature Sensor Data (Ultra Watch only, for Sauna/Cold Shower)
    @Published var SW_Temp_Array_F: [String] = [] // Array of temp readings every 5 seconds (e.g., ["55.1", "55.0"])
    
    // Default temperatures from API (always in Fahrenheit)
    @Published var default_sauna_temp_F: Double = 180.0
    @Published var default_cold_shower_temp_F: Double = 45.0
    
    // Settings from API
    @Published var useSmartwatchTempSensor: Bool = false
    @Published var allowSmartwatchGPSlocator: Bool = true
    
    @StateObject private var apiManager = APIs.shared

    func fetchLastSessionData() {
        // Get the stored userId from UserDefaults
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            #if DEBUG
            print("No userId found in storage, cannot fetch session data")
            #endif
            return
        }
        
        // Create the URL with the userId as a query parameter
        let baseURL = apiManager.getStartupDataForSmartWatchEndpoint
        let urlString = "\(baseURL)?userId=\(userId)"
        
        guard let url = URL(string: urlString) else {
            #if DEBUG
            print("Invalid URL: \(urlString)")
            #endif
            return
        }
        
        #if DEBUG
        print("Fetching session data from: \(urlString)")
        #endif
        
        // Create the URL request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Make the API call
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    #if DEBUG
                    print("API request failed with error: \(error)")
                    #endif
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    #if DEBUG
                    print("Invalid response type")
                    #endif
                    return
                }
                
                #if DEBUG
                print("API response status code: \(httpResponse.statusCode)")
                #endif
                
                guard let data = data else {
                    #if DEBUG
                    print("No data received from API")
                    #endif
                    return
                }
                
                do {
                    // Parse the JSON response
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        #if DEBUG
                        print("Session data API response: \(json)")
                        #endif

                        // Extract subscription status FIRST
                        let isUserSubscribed = json["isUserSubscribed"] as? Bool ?? false

                        #if DEBUG
                        print("👤 User subscription status: \(isUserSubscribed)")
                        #endif
                        
                        // Extract the session data from the response
                        if let lastSessionTimeSet = json["lastSessionTimeSet"] as? String,
                           let lastSessionWaterTemp = json["lastSessionWaterTemp"] as? String,
                           let unitOfMeasure = json["unitOfMeasure"] as? String {
                            
                            // Store session data as before
                            self.lastSessionData = [
                                "lastSessionTimeSet": lastSessionTimeSet,
                                "lastSessionWaterTemp": lastSessionWaterTemp,
                                "unitOfMeasure": unitOfMeasure
                            ]
                            
                            // NEW: Extract and store default Sauna temperature
                            if let saunaTempF = json["default_sauna_temp_F"] as? Double {
                                self.default_sauna_temp_F = saunaTempF
                                #if DEBUG
                                print("✅ Default Sauna temp: \(saunaTempF)°F")
                                #endif
                            } else {
                                self.default_sauna_temp_F = 180.0 // Default fallback
                                #if DEBUG
                                print("⚠️ default_sauna_temp_F not in response, using default: 180.0°F")
                                #endif
                            }
                            
                            // NEW: Extract and store default Cold Shower temperature
                            if let coldShowerTempF = json["default_cold_shower_temp_F"] as? Double {
                                self.default_cold_shower_temp_F = coldShowerTempF
                                #if DEBUG
                                print("✅ Default Cold Shower temp: \(coldShowerTempF)°F")
                                #endif
                            } else {
                                self.default_cold_shower_temp_F = 45.0 // Default fallback
                                #if DEBUG
                                print("⚠️ default_cold_shower_temp_F not in response, using default: 45.0°F")
                                #endif
                            }
                            
                            // NEW: Extract and store useSmartwatchTempSensor setting
                            if let useTempSensor = json["useSmartwatchTempSensor"] as? Bool {
                                self.useSmartwatchTempSensor = useTempSensor
                                #if DEBUG
                                print("✅ Use Smartwatch Temp Sensor: \(useTempSensor)")
                                #endif
                            } else {
                                self.useSmartwatchTempSensor = false
                                #if DEBUG
                                print("⚠️ useSmartwatchTempSensor not in response, using default: false")
                                #endif
                            }
                            
                            // NEW: Extract and store allowSmartwatchGPSlocator setting
                            if let allowGPS = json["allowSmartwatchGPSlocator"] as? Bool {
                                self.allowSmartwatchGPSlocator = allowGPS
                                #if DEBUG
                                print("✅ Allow Smartwatch GPS: \(allowGPS)")
                                #endif
                            } else {
                                self.allowSmartwatchGPSlocator = true
                                #if DEBUG
                                print("⚠️ allowSmartwatchGPSlocator not in response, using default: true")
                                #endif
                            }
                            
                            // Extract and store the get_ready_timer_seconds value
                            if let getReadyTimerSeconds = json["get_ready_timer_seconds"] as? Int {
                                UserDefaults.standard.set(getReadyTimerSeconds, forKey: "get_ready_timer_seconds")
                                #if DEBUG
                                print("✅ Get ready timer settings saved from getStartupDataForSmartWatch: \(getReadyTimerSeconds) seconds")
                                #endif
                            } else {
                                // Store default value of 5 seconds if not present in response
                                UserDefaults.standard.set(5, forKey: "get_ready_timer_seconds")
                                #if DEBUG
                                print("⚠️ get_ready_timer_seconds not found in response, using default: 5 seconds")
                                #endif
                            }

                            // Extract and store the isUserSubscribed value
                            if let isUserSubscribed = json["isUserSubscribed"] as? Bool {
                                UserDefaults.standard.set(isUserSubscribed, forKey: "isUserSubscribed")
                                #if DEBUG
                                print("✅ isUserSubscribed saved from getStartupDataForSmartWatch: \(isUserSubscribed)")
                                #endif
                            } else {
                                // Store default value of false if not present in response
                                UserDefaults.standard.set(false, forKey: "isUserSubscribed")
                                #if DEBUG
                                print("⚠️ isUserSubscribed not found in response, using default: false")
                                #endif
                            }
                            
                            #if DEBUG
                            print("✅ Session data fetched and stored successfully")
                            print("lastSessionTimeSet: \(lastSessionTimeSet)")
                            print("lastSessionWaterTemp: \(lastSessionWaterTemp)")
                            print("unitOfMeasure: \(unitOfMeasure)")
                            #endif
                        } else {
                            #if DEBUG
                            print("❌ Failed to extract session data from API response")
                            #endif
                        }
                    }
                } catch {
                    #if DEBUG
                    print("❌ Failed to parse JSON response: \(error)")
                    #endif
                }
            }
        }.resume()
    }

    func resetSessionTracking() {
        #if DEBUG
        print("🔄 SessionDataManager: Resetting session tracking")
        #endif
        
        HRArray = []
        SW_Temp_Array_F = [] // Clear temperature array
        epicTime = nil
        accumulatedSessionTime = 0
        originalCountdownTimeSeconds = 0
        currentTimerMode = "Countdown"
        // Note: We don't reset activityType, default temps, or settings - they persist until changed
        
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