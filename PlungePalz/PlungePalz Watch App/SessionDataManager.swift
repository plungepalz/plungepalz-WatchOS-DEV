import Foundation
import SwiftUI

class SessionDataManager: ObservableObject {
    @Published var lastSessionData: [String: String]? = nil

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
} 