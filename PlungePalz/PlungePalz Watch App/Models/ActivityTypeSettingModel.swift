//
//  ActivityTypeSettingModel.swift
//  PlungePalz Watch App
//

import Foundation

struct LatestSessionParams: Codable {
    let totalTimeS: Int
    let setTimeS: Int
    let tempF: Double

    enum CodingKeys: String, CodingKey {
        case totalTimeS = "total_time_s"
        case setTimeS = "set_time_s"
        case tempF = "temp_f"
    }

    init(totalTimeS: Int, setTimeS: Int, tempF: Double) {
        self.totalTimeS = totalTimeS
        self.setTimeS = setTimeS
        self.tempF = tempF
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalTimeS = try container.decode(Int.self, forKey: .totalTimeS)
        setTimeS = try container.decode(Int.self, forKey: .setTimeS)
        if let value = try? container.decode(Double.self, forKey: .tempF) {
            tempF = value
        } else if let string = try? container.decode(String.self, forKey: .tempF),
                  let value = Double(string) {
            tempF = value
        } else {
            tempF = 0
        }
    }
}

struct ActivityTypeSetting: Codable, Identifiable {
    var id: String { activityType }
    let activityType: String
    let timerSettingMode: String
    let latestSessionParams: LatestSessionParams

    enum CodingKeys: String, CodingKey {
        case activityType = "activity_type"
        case timerSettingMode = "timer_setting_mode"
        case latestSessionParams = "latest_session_params"
    }

    var hasUseLast: Bool {
        latestSessionParams.totalTimeS > 0
    }

    var isCountdown: Bool {
        timerSettingMode == "Countdown"
    }

    var isStopwatch: Bool {
        timerSettingMode == "Stopwatch"
    }
}
