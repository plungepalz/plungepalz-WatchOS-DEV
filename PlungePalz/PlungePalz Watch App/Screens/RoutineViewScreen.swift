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
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                
                                Text("\(routine.routineList.count) Steps • Length: \(formatDuration(routine.total_s_length_seconds))")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 0)
                            .padding(.bottom, 4)

                            // Continuous list of cards
                            LazyVStack(spacing: 10) { // Increased spacing to accommodate top/bottom badge bleed room
                                ForEach(Array(routine.routineList.enumerated()), id: \.element.id) { index, step in
                                    NewStepCard(
                                        step: step,
                                        stepLabel: stepLabel(step),
                                        duration: formatDuration(step.sLength),
                                        tempString: tempString(for: step)
                                    )
                                }
                            }
                            // Added left padding so the bleeding badge doesn't touch or clip off the physical watch bezel line
                            .padding(.leading, 10)
                            .padding(.trailing, 6)

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
        .watchBackNavigation(navigationManager: navigationManager, iconSize: 22, topPadding: -40)
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

    var body: some View {
        // Single Parent Container handling strictly Rows
        VStack(spacing: 6) {
            // Row 1: Icon on Left, stepLabel on Right
            HStack(spacing: 6) {
                Image(systemName: itemIcon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(itemIconColor)
                    .frame(width: 18, alignment: .leading)
                
                Text(stepLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Spacer()
            }
            
            // Row 2: Duration on Left, tempString on Right
            HStack {
                Text(duration)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let t = tempString {
                    Text(t)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(tempFontColor)
                }
            }
        }
        .padding(.leading, 20) // Shifts row text safely right so it clears the bleeding badge
        .padding(.trailing, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        // Absolute Bleed Overlay Execution
        .overlay(
            Text("#\(step.step)")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color(hex: "#00A8FF")) // Uses your brand palette to make the pop-out badge look deliberate and premium
                .clipShape(Capsule())
                // Negative offsets pull the top-left corner up and out into the black background canvas
                .offset(x: -10, y: -6),
            alignment: .topLeading
        )
    }

    // MARK: - Visual Configurations

    private var itemIcon: String {
        guard step.type == "Modality" else { return "arrow.right.circle" }
        return ActivityTypes.systemIcon(for: step.activityType)
    }

    private var itemIconColor: Color {
        guard step.type == "Modality" else { return Color.green.opacity(0.8) }
        return ActivityTypes.iconColor(for: step.activityType)
    }

    private var tempFontColor: Color {
        ActivityTypes.temperatureTextColor(for: step.activityType)
    }
}