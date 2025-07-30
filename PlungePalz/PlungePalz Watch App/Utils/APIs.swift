import Foundation
import SwiftUI

class APIs: ObservableObject {
    static let shared = APIs()
    
    // MARK: - Environment Configuration
    @Published var isProduction: Bool = true

    
    // MARK: - API Base URLs
    private var baseURL: String {
        return isProduction 
            ? "https://d76hjali51.execute-api.us-east-1.amazonaws.com/SmartWatchActivitySaved_mvp_production"  // Production Endpoint URL
            : "https://d76hjali51.execute-api.us-east-1.amazonaws.com/SmartWatchActivitySaved_mvp_production" // DEV Endpoint URL
    }
    
    // MARK: - API Endpoints
    var saveSessionEndpoint: String {
        return "\(baseURL)/AppleWatch"
    }
    
    var savePendingSessionsEndpoint: String {
        return "\(baseURL)/AppleWatch"
    }
    
    var verifyPairingCodeEndpoint: String {
        return "\(baseURL)/AppleWatch/VerifyPairingCode_AppleWatchSide"
    }

    var getStartupDataForSmartWatchEndpoint: String {
        return "\(baseURL)/getStartupDataForSmartWatch"
    }

    var getUserCountdownTimerSettings: String {
        return "\(baseURL)/AppleWatch/getUserCountdownTimerSettings"
    }
    
    
    // MARK: - HTTP Headers
    var defaultHeaders: [String: String] {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "PlungePalz-WatchOS/1.0.0"
        ]
    }
    
    // MARK: - Request Timeouts
    var requestTimeout: TimeInterval = 30.0
    var retryTimeout: TimeInterval = 15.0
    var maxRetryAttempts: Int = 3
    
    // MARK: - Private Initializer for Singleton
    private init() {}
    
    // MARK: - Helper Methods
    func createRequest(url: String, method: String = "POST", body: [String: Any]? = nil) -> URLRequest? {
        guard let url = URL(string: url) else {
            #if DEBUG
            print("Invalid URL: \(url)")
            #endif
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = requestTimeout
        
        // Add default headers
        for (key, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add body if provided
        if let body = body {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: body)
                request.httpBody = jsonData
            } catch {
                #if DEBUG
                print("JSON serialization error: \(error)")
                #endif
                return nil
            }
        }
        
        return request
    }
    
    // Overloaded method for array of dictionaries (bulk operations)
    func createRequest(url: String, method: String = "POST", bodyArray: [[String: Any]]? = nil) -> URLRequest? {
        guard let url = URL(string: url) else {
            #if DEBUG
            print("Invalid URL: \(url)")
            #endif
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = requestTimeout
        
        // Add default headers
        for (key, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add body if provided
        if let bodyArray = bodyArray {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: bodyArray)
                request.httpBody = jsonData
            } catch {
                #if DEBUG
                print("JSON serialization error: \(error)")
                #endif
                return nil
            }
        }
        
        return request
    }
    
    // MARK: - API Response Handling
    func handleAPIResponse(_ response: HTTPURLResponse?, data: Data?, error: Error?) -> (success: Bool, message: String) {
        if let error = error {
            return (false, "Network error: \(error.localizedDescription)")
        }
        
        guard let response = response else {
            return (false, "Invalid response")
        }
        
        #if DEBUG
        print("API Response Status: \(response.statusCode)")
        #endif
        
        if response.statusCode >= 200 && response.statusCode < 300 {
            return (true, "Success")
        } else {
            let errorMessage = data != nil ? String(data: data!, encoding: .utf8) ?? "Unknown error" : "HTTP \(response.statusCode)"
            return (false, errorMessage)
        }
    }
    
    // MARK: - Get Ready Timer API
    func fetchGetReadyTimerSettings(completion: @escaping (Int?) -> Void) {
        // Get userId from UserDefaults
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            #if DEBUG
            print("No userId found in UserDefaults, skipping get ready timer API call")
            #endif
            completion(nil) // No userId, don't make API call
            return
        }
        
        // Create URL with accountId query parameter
        var urlComponents = URLComponents(string: getUserCountdownTimerSettings)
        urlComponents?.queryItems = [URLQueryItem(name: "accountId", value: userId)]
        
        guard let url = urlComponents?.url else {
            #if DEBUG
            print("Failed to create URL with accountId parameter")
            #endif
            completion(nil)
            return
        }
        
        // Create GET request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = requestTimeout
        
        // Add default headers
        for (key, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        #if DEBUG
        print("Making GET request to: \(url)")
        #endif
        
        // Make the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                let result = self.handleAPIResponse(response as? HTTPURLResponse, data: data, error: error)
                
                if result.success, let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let getReadySeconds = json["get_ready_timer_seconds"] as? Int {
                            #if DEBUG
                            print("Successfully fetched get ready timer: \(getReadySeconds) seconds")
                            #endif
                            completion(getReadySeconds)
                        } else {
                            #if DEBUG
                            print("Invalid JSON response format")
                            #endif
                            completion(5)
                        }
                    } catch {
                        #if DEBUG
                        print("JSON parsing error: \(error)")
                        #endif
                        completion(5)
                    }
                } else {
                    #if DEBUG
                    print("API request failed: \(result.message)")
                    #endif
                    completion(5)
                }
            }
        }.resume()
    }
} 