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
