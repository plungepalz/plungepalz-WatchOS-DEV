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
    @StateObject private var apiManager = APIs.shared

    func fetchLastSessionData() {
        // Get the stored userId from UserDefaults
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            // print("No userId found in storage, cannot fetch session data")
            return
        }
        
        // Create the URL with the userId as a query parameter
        let baseURL = apiManager.getStartupDataForSmartWatchEndpoint
        let urlString = "\(baseURL)?userId=\(userId)"
        
        guard let url = URL(string: urlString) else {
            // print("Invalid URL: \(urlString)")
            return
        }
        
        // print("Fetching session data from: \(urlString)")
        
        // Create the URL request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Make the API call
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    // print("API request failed with error: \(error)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    // print("Invalid response type")
                    return
                }
                
                // print("API response status code: \(httpResponse.statusCode)")
                
                guard let data = data else {
                    // print("No data received from API")
                    return
                }
                
                do {
                    // Parse the JSON response
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        // print("Session data API response: \(json)")

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
                            
                            // NEW: Extract and store the get_ready_timer_seconds value
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

                            // NEW: Extract and store the isUserSubscribed value
                            if let isUserSubscribed = json["isUserSubscribed"] as? Bool {
                                UserDefaults.standard.set(isUserSubscribed, forKey: "isUserSubscribed")
                                #if DEBUG
                                print("✅ isUserSubscribed settings saved from getStartupDataForSmartWatch: \(isUserSubscribed) seconds")
                                #endif
                            } else {
                                // Store default value of false if not present in response
                                UserDefaults.standard.set(false, forKey: "isUserSubscribed")
                                #if DEBUG
                                print("⚠️ isUserSubscribed not found in response, using default: false")
                                #endif
                            }
                            
                            // print("✅ Session data loaded successfully")
                        } else {
                            // print("❌ Missing required fields in API response")
                            // Store default get ready timer value even if other data is missing
                            UserDefaults.standard.set(5, forKey: "get_ready_timer_seconds")
                        }
                    }
                } catch {
                    // print("❌ Failed to parse JSON: \(error)")
                    // Store default get ready timer value on JSON parse error
                    UserDefaults.standard.set(5, forKey: "get_ready_timer_seconds")
                }
            }
        }.resume()
    }

    func resetSessionTracking() {
        HRArray = []
        epicTime = nil
        accumulatedSessionTime = 0
        originalCountdownTimeSeconds = 0
        currentTimerMode = "Countdown"
    }
} 
