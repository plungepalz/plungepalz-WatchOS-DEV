//
//  RoutineViewScreen.swift
//  PlungePalz Watch App
//
//  Browsable step list before starting a routine.
//

import SwiftUI

struct RoutineViewScreen: View {
    @ObservedObject var navigationManager: NavigationManager
    @EnvironmentObject var sessionDataManager: SessionDataManager
    @StateObject private var screenManager = WatchScreenManager()

    // MARK: - Helpers

    private var routine: RoutineModel? { sessionDataManager.activeRoutine }

    private func stepLabel(_ step: RoutineStepModel) -> String {
        if step.type == "Modality" {
            return step.activityType ?? "Activity"
        } else {
            return step.stepNickname ?? "Transition"
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func tempString(for step: RoutineStepModel) -> String? {
        guard step.type == "Modality", let tf = step.tempF else { return nil }
        let unit = sessionDataManager.unitOfMeasure
        if unit == "Metric" {
            let c = (tf - 32) * 5 / 9
            return String(format: "%.1f°C", c)
        }
        return String(format: "%.1f°F", tf)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                if let routine = routine {
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 12) {
                            // Dynamic Sub-Header Info Area
                            VStack(spacing: 3) {
                                Text("Routine Steps")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                
                                Text("\(routine.routineList.count) Steps • Total flow")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 4)

                            // Continuous list of cards
                            LazyVStack(spacing: 6) {
                                ForEach(Array(routine.routineList.enumerated()), id: \.element.id) { index, step in
                                    NewStepCard(
                                        step: step,
                                        stepLabel: stepLabel(step),
                                        duration: formatDuration(step.sLength),
                                        tempString: tempString(for: step),
                                        isFirst: index == 0,
                                        isLast: index == routine.routineList.count - 1
                                    )
                                }
                            }
                            .padding(.horizontal, 4)

                            // Modern, sweeping CTA at the base of the list
                            Button(action: startRoutine) {
                                HStack {
                                    Spacer()
                                    Text("START ROUTINE")
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                        .foregroundStyle(.black)
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.black)
                                    Spacer()
                                }
                                .frame(height: 40)
                                .background(Color(hex: "#00A8FF"))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 6)
                            .padding(.top, 10)
                            .padding(.bottom, 12)
                        }
                    }
                } else {
                    Spacer()
                    Text("No routine selected")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.gray)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
        .watchBackNavigation(navigationManager: navigationManager, iconSize: 22)
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
    }

    // MARK: - Actions

    private func startRoutine() {
        let selectedRoutine = routine
        sessionDataManager.resetRoutineState()
        sessionDataManager.activeRoutine = selectedRoutine
        navigationManager.goToScreen(.routineGetReady)
    }
}

// MARK: - Modern Step Card View

private struct NewStepCard: View {
    let step: RoutineStepModel
    let stepLabel: String
    let duration: String
    let tempString: String?
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Step marker capsule
            Text("\(step.step)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 22, height: 16)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())

            // Contextual Modality/Transition Icon
            Image(systemName: step.type == "Modality" ? activityIcon : "arrow.right.circle")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(step.type == "Modality" ? Color(hex: "#00A8FF") : .secondary)
                .frame(width: 18)

            // Content Stack (Label + Parameters underneath)
            VStack(alignment: .leading, spacing: 2) {
                Text(stepLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                // Stacked Row metrics underneath title
                HStack(spacing: 6) {
                    Text(duration)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    if let t = tempString {
                        // Small dot separator to cleanly stitch text components
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary.opacity(0.5))
                        
                        Text(t)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(hex: "#00A8FF"))
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var activityIcon: String {
        switch step.activityType ?? "" {
        case "Cold Plunge":   return "drop.degreesign"
        case "Sauna":        return "heater.vertical"
        case "Steam Room":   return "cloud.fog"
        case "Cold Shower":  return "shower"
        case "Hot Tub":      return "water.waves"
        default:
            let lowerType = (step.activityType ?? "").lowercased()
            if lowerType.contains("plunge") { return "drop.degreesign" }
            if lowerType.contains("sauna") { return "heater.vertical" }
            if lowerType.contains("steam") { return "cloud.fog" }
            if lowerType.contains("shower") { return "shower" }
            if lowerType.contains("tub") { return "water.waves" }
            return "bolt.heart"
        }
    }
}