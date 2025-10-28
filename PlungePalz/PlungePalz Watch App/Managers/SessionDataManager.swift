//
//  SessionDataManager.swift
//  PlungePalz Watch App
//
//  Updated to include activityType for multiple activity options
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
    
    // NEW: Activity Type - Default to "Cold Plunge"
    @Published var activityType: String = "Cold Plunge" // Options: "Cold Plunge", "Sauna", "Cold Shower"
    
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
        epicTime = nil
        accumulatedSessionTime = 0
        originalCountdownTimeSeconds = 0
        currentTimerMode = "Countdown"
        // Note: We don't reset activityType here - it persists until user selects a new activity
        
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
}