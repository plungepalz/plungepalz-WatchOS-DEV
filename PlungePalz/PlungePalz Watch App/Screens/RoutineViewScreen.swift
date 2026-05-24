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

    @State private var scrollOffset: Int = 0

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
        let screenSize = screenManager.currentScreenSize

        GeometryReader { geo in
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 2) {
                    Text("Routine Steps")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Press Start to Begin")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color(hex: "#00A8FF"))
                }
                .padding(.top, 20)
                .padding(.bottom, 6)

                // Step Cards
                if let routine = routine {
                    let steps = routine.routineList
                    let visibleCount = 3
                    let maxOffset = max(0, steps.count - visibleCount)
                    let safeOffset = min(scrollOffset, maxOffset)
                    let visibleSteps = Array(steps[safeOffset..<min(safeOffset + visibleCount, steps.count)])

                    VStack(spacing: 4) {
                        ForEach(Array(visibleSteps.enumerated()), id: \.element.id) { enumIdx, step in
                            let isTop = enumIdx == 0
                            let globalIdx = safeOffset + enumIdx

                            StepCard(
                                step: step,
                                stepLabel: stepLabel(step),
                                duration: formatDuration(step.sLength),
                                tempString: tempString(for: step),
                                isHighlighted: isTop,
                                isFirst: globalIdx == 0,
                                isLast: globalIdx == steps.count - 1
                            )
                        }
                    }
                    .padding(.horizontal, 6)

                    Spacer(minLength: 4)

                    // Navigation + Start
                    HStack(spacing: 8) {
                        Button(action: { if scrollOffset > 0 { scrollOffset -= 1 } }) {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(scrollOffset > 0 ? .white : .gray)
                        }
                        .buttonStyle(.plain)
                        .disabled(scrollOffset == 0)

                        Button(action: startRoutine) {
                            Text("START")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color(hex: "#00A8FF"))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button(action: { if scrollOffset < maxOffset { scrollOffset += 1 } }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(scrollOffset < maxOffset ? .white : .gray)
                        }
                        .buttonStyle(.plain)
                        .disabled(scrollOffset >= maxOffset)
                    }
                    .padding(.bottom, 8)
                } else {
                    Spacer()
                    Text("No routine selected")
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
        let selectedRoutine = routine  // capture before resetRoutineState clears it
        sessionDataManager.resetRoutineState()
        sessionDataManager.activeRoutine = selectedRoutine
        navigationManager.goToScreen(.routineGetReady)
    }
}

// MARK: - Step Card

private struct StepCard: View {
    let step: RoutineStepModel
    let stepLabel: String
    let duration: String
    let tempString: String?
    let isHighlighted: Bool
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Step number badge
            Text("\(step.step)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(isHighlighted ? .black : Color(hex: "#00A8FF"))
                .frame(width: 20)

            // Icon
            Image(systemName: step.type == "Modality" ? activityIcon : "arrow.right.circle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isHighlighted ? .black : .white)
                .frame(width: 16)

            // Label
            Text(stepLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isHighlighted ? .black : .white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer()

            // Duration + temp
            VStack(alignment: .trailing, spacing: 1) {
                Text(duration)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isHighlighted ? .black : Color(hex: "#00A8FF"))
                if let t = tempString {
                    Text(t)
                        .font(.system(size: 9))
                        .foregroundStyle(isHighlighted ? Color.black.opacity(0.7) : .gray)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(isHighlighted ? Color(hex: "#00A8FF") : Color(red: 34/255, green: 34/255, blue: 34/255))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var activityIcon: String {
        switch step.activityType?.lowercased() ?? "" {
        case let s where s.contains("sauna"):   return "heater.vertical"
        case let s where s.contains("plunge"):  return "snowflake"
        case let s where s.contains("shower"):  return "shower"
        case let s where s.contains("tub"):     return "bathtub"
        default:                                return "bolt.heart"
        }
    }
}

#Preview {
    RoutineViewScreen(navigationManager: NavigationManager())
        .environmentObject(SessionDataManager())
}
