//
//  ActivityTypes.swift
//  PlungePalz Watch App
//
//  Single source of truth for activity icons, colors, and home-screen labels.
//

import SwiftUI

struct ActivityTypeAppearance {
    /// API `activity_type` value (e.g. "Cold Plunge").
    let activityType: String
    /// Short label shown on HomeScreen.
    let homeDisplayName: String
    let systemIcon: String
    let iconColor: Color
    /// Cold modalities use brand blue for temperature text; heat modalities use orange.
    let isColdTherapy: Bool
}

enum ActivityTypes {
    // MARK: - Catalog (edit icons/colors here)

    static let catalog: [ActivityTypeAppearance] = [
        ActivityTypeAppearance(
            activityType: "Cold Plunge",
            homeDisplayName: "Plunge",
            systemIcon: "drop.degreesign",
            iconColor: Color(red: 0.24, green: 0.78, blue: 1.0),
            isColdTherapy: true
        ),
        ActivityTypeAppearance(
            activityType: "Sauna",
            homeDisplayName: "Sauna",
            systemIcon: "heater.vertical",
            iconColor: .orange,
            isColdTherapy: false
        ),
        ActivityTypeAppearance(
            activityType: "Steam Room",
            homeDisplayName: "Steam Room",
            systemIcon: "cloud.fog",
            iconColor: .gray,
            isColdTherapy: false
        ),
        ActivityTypeAppearance(
            activityType: "Cold Shower",
            homeDisplayName: "Cold Shower",
            systemIcon: "shower",
            iconColor: .blue,
            isColdTherapy: true
        ),
        ActivityTypeAppearance(
            activityType: "Hot Tub",
            homeDisplayName: "Hot Tub",
            systemIcon: "water.waves",
            iconColor: Color(red: 0.95, green: 0.35, blue: 0.25),
            isColdTherapy: false
        ),
    ]

    private static let fallback = ActivityTypeAppearance(
        activityType: "Activity",
        homeDisplayName: "Activity",
        systemIcon: "bolt.heart",
        iconColor: Color(red: 0, green: 168 / 255, blue: 1),
        isColdTherapy: false
    )

    // MARK: - Lookup

    static func appearance(for activityType: String) -> ActivityTypeAppearance {
        if let exact = catalog.first(where: { $0.activityType == activityType }) {
            return exact
        }
        return appearance(matchingPartial: activityType)
    }

    static func appearance(for activityType: String?) -> ActivityTypeAppearance {
        guard let activityType, !activityType.isEmpty else { return fallback }
        return appearance(for: activityType)
    }

    private static func appearance(matchingPartial type: String) -> ActivityTypeAppearance {
        let lower = type.lowercased()
        if lower.contains("plunge") { return appearance(for: "Cold Plunge") }
        if lower.contains("sauna") { return appearance(for: "Sauna") }
        if lower.contains("steam") { return appearance(for: "Steam Room") }
        if lower.contains("shower") { return appearance(for: "Cold Shower") }
        if lower.contains("tub") { return appearance(for: "Hot Tub") }
        return fallback
    }

    static func systemIcon(for activityType: String?) -> String {
        appearance(for: activityType).systemIcon
    }

    static func iconColor(for activityType: String?) -> Color {
        appearance(for: activityType).iconColor
    }

    static func isColdTherapy(for activityType: String?) -> Bool {
        appearance(for: activityType).isColdTherapy
    }

    /// Thermometer SF Symbol for active session temperature display.
    static func thermometerIcon(for activityType: String?) -> String {
        isColdTherapy(for: activityType) ? "thermometer.snowflake" : "thermometer.high"
    }

    /// Temperature label color on routine step cards.
    static func temperatureTextColor(for activityType: String?) -> Color {
        let app = appearance(for: activityType)
        if app.isColdTherapy {
            return Color(red: 0, green: 168 / 255, blue: 1)
        }
        return Color.orange.opacity(0.8)
    }
}
