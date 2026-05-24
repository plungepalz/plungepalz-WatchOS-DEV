//
//  TemperatureRanges.swift
//  PlungePalz Watch App
//
//  Activity-type temperature ranges aligned with Garmin SetTemperatureScreen.mc
//

import Foundation

struct TemperatureRangeConfig {
    let fahrenheitMin: Int
    let fahrenheitMax: Int
    let fahrenheitDefault: Int
    let celsiusMin: Int
    let celsiusMax: Int
    let celsiusDefault: Int
}

enum TemperatureRanges {
    static func config(for activityType: String) -> TemperatureRangeConfig {
        switch activityType {
        case "Sauna":
            return TemperatureRangeConfig(
                fahrenheitMin: 120, fahrenheitMax: 220, fahrenheitDefault: 180,
                celsiusMin: 49, celsiusMax: 104, celsiusDefault: 82
            )
        case "Steam Room":
            return TemperatureRangeConfig(
                fahrenheitMin: 90, fahrenheitMax: 130, fahrenheitDefault: 110,
                celsiusMin: 32, celsiusMax: 54, celsiusDefault: 43
            )
        case "Hot Tub":
            return TemperatureRangeConfig(
                fahrenheitMin: 90, fahrenheitMax: 107, fahrenheitDefault: 102,
                celsiusMin: 32, celsiusMax: 41, celsiusDefault: 39
            )
        default:
            // Cold Plunge, Cold Shower
            return TemperatureRangeConfig(
                fahrenheitMin: 23, fahrenheitMax: 65, fahrenheitDefault: 48,
                celsiusMin: -5, celsiusMax: 18, celsiusDefault: 9
            )
        }
    }

    static func fahrenheitRange(for activityType: String) -> [Int] {
        let config = config(for: activityType)
        return Array(config.fahrenheitMin...config.fahrenheitMax)
    }

    static func celsiusRange(for activityType: String) -> [Int] {
        let config = config(for: activityType)
        return Array(config.celsiusMin...config.celsiusMax)
    }
}
