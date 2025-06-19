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
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.lastSessionData = [
                "lastSessionTimeSet": "10:40",
                "lastSessionWaterTemp": "45.5",
                "unitOfMeasure": "Imperial"
            ]
        }
    }

    func resetSessionTracking() {
        HRArray = []
        epicTime = nil
        accumulatedSessionTime = 0
        originalCountdownTimeSeconds = 0
        currentTimerMode = "Countdown"
    }
} 