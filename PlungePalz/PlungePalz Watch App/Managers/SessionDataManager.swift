import Foundation
import SwiftUI

class SessionDataManager: ObservableObject {
    @Published var lastSessionData: [String: String]? = nil
    @Published var HRArray: [Int] = []
    @Published var epicTime: Int? = nil
    @Published var accumulatedSessionTime: Int = 0
    @Published var originalCountdownTimeSeconds: Int = 0
    @Published var currentTimerMode: String = "Countdown" // "Countdown" or "Countup"

    func fetchLastSessionData() {
        // Get the stored userId from UserDefaults
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            // print("No userId found in storage, cannot fetch session data")
            return
        }
        
        // Create the URL with the userId as a query parameter
        let baseURL = "https://d76hjali51.execute-api.us-east-1.amazonaws.com/SmartWatchActivitySaved_mvp_production/getStartupDataForSmartWatch"
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
                        
                        // Extract the session data from the response
                        // Adjust these field names based on your actual API response structure
                        if let lastSessionTimeSet = json["lastSessionTimeSet"] as? String,
                           let lastSessionWaterTemp = json["lastSessionWaterTemp"] as? String,
                           let unitOfMeasure = json["unitOfMeasure"] as? String {
                            
                            self.lastSessionData = [
                                "lastSessionTimeSet": lastSessionTimeSet,
                                "lastSessionWaterTemp": lastSessionWaterTemp,
                                "unitOfMeasure": unitOfMeasure
                            ]
                            
                            // print("Session data updated successfully")
                        } else {
                            // print("Missing required fields in API response")
                        }
                    } else {
                        // print("Failed to parse JSON response")
                    }
                } catch {
                    // print("JSON parsing error: \(error)")
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