//
//  RoutinePauseScreen.swift
//  PlungePalz Watch App
//
//  Pause menu shown during a routine Modality or Transition step.
//  Options: Save (Modality only) | Continue | Skip This Step
//

import SwiftUI
import WatchKit

struct RoutinePauseScreen: View {
    @ObservedObject var navigationManager: NavigationManager
    @EnvironmentObject var sessionDataManager: SessionDataManager
    @EnvironmentObject var workoutManager: WorkoutManager
    @StateObject private var screenManager = WatchScreenManager()

    // MARK: - Computed helpers

    private var isModality: Bool { navigationManager.routinePauseSource == "Modality" }

    // MARK: - Actions

    private func handleSave() {
        sessionDataManager.performOptimisticModalitySave(
            workoutManager: workoutManager,
            navigationManager: navigationManager
        )
    }

    private func handleContinue() {
        if isModality {
            navigationManager.goToScreen(.routineModality)
        } else {
            navigationManager.goToScreen(.routineTransition)
        }
    }

    private func handleSkip() {
        if isModality {
            sessionDataManager.skipCurrentModalityStep(
                workoutManager: workoutManager,
                navigationManager: navigationManager
            )
        } else {
            sessionDataManager.skipCurrentTransitionStep(navigationManager: navigationManager)
        }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 0) {
                        VStack(spacing: 2) {
                            Text("Step Paused")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "#00A8FF"))
                        }
                        .padding(.top, 32)
                        .padding(.bottom, 12)
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 8) {
                            if isModality {
                                ModernPauseRowButton(
                                    iconName: "square.and.arrow.down.fill",
                                    title: "Save",
                                    subtitle: "Save your activity",
                                    iconColor: Color(hex: "#00A8FF"),
                                    action: handleSave
                                )
                            }

                            ModernPauseRowButton(
                                iconName: "arrow.uturn.backward.square",
                                title: "Continue",
                                subtitle: "Resume current step",
                                iconColor: .green,
                                action: handleContinue
                            )

                            ModernPauseRowButton(
                                iconName: "point.bottomleft.forward.to.arrow.triangle.scurvepath",
                                title: "Skip This Step",
                                subtitle: "Current step will not be saved",
                                iconColor: Color(.red).opacity(0.85),
                                action: handleSkip
                            )
                        }
                        .padding(.horizontal, 6)
                        .padding(.bottom, 16)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .edgesIgnoringSafeArea(.all)
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
    }
}

// MARK: - Modern Platter Row Button Component

private struct ModernPauseRowButton: View {
    let iconName: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.14))
                        .frame(width: 28, height: 28)

                    Image(systemName: iconName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RoutinePauseScreen(navigationManager: NavigationManager())
        .environmentObject(SessionDataManager())
        .environmentObject(WorkoutManager())
}
