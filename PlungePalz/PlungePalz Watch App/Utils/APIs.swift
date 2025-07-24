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
} 