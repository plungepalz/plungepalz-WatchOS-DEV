//
//  RoutineModel.swift
//  PlungePalz Watch App
//
//  Data models for the Routines feature.
//

import Foundation

// MARK: - RoutineModel

struct RoutineModel: Codable, Identifiable {
    var id: String { routineId }
    let routineId: String
    let nickname: String
    let stepsCount: Int
    let autoSaveOnModalityCompletion: Bool
    let routineList: [RoutineStepModel]
    let total_s_length_seconds: Int

    enum CodingKeys: String, CodingKey {
        case routineId = "routine_id"
        case nickname
        case stepsCount = "steps_count"
        case autoSaveOnModalityCompletion = "auto_save_on_modality_completion"
        case routineList = "routine_list"
        case total_s_length_seconds = "total_s_length_seconds"
    }
}

// MARK: - RoutineStepModel

struct RoutineStepModel: Codable, Identifiable {
    var id: Int { step }
    let step: Int               // 1-based step number
    let type: String            // "Modality" or "Transition"
    let routineLineId: String
    let activityType: String?   // Modality only
    let stepNickname: String?   // Transition only
    let sLength: Int            // Duration in seconds
    let tempF: Double?          // Target temp °F, Modality only

    enum CodingKeys: String, CodingKey {
        case step
        case type
        case routineLineId = "routine_line_id"
        case activityType
        case stepNickname = "step_nickname"
        case sLength = "s_length"
        case tempF = "temp_f"
    }
}

// MARK: - RoutineStepResult

struct RoutineStepResult {
    let step: Int
    let type: String
    let activityType: String
    var status: String   // "Saved" | "Pending" | "Skipped" | ""
}

// MARK: - RoutineStepStats

struct RoutineStepStats {
    let totalTime: Int   // seconds elapsed
    let tempF: Double    // from step definition
    let minHR: Int
    let maxHR: Int
    let avgHR: Int
}
