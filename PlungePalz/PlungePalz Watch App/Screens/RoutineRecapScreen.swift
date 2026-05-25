//
//  RoutineRecapScreen.swift
//  PlungePalz Watch App
//
//  Multi-page summary after completing a routine. Mirrors Routine_RecapScreen.mc.
//

import SwiftUI
import WatchKit

struct RoutineRecapScreen: View {
    @ObservedObject var navigationManager: NavigationManager
    @EnvironmentObject var sessionDataManager: SessionDataManager
    @StateObject private var screenManager = WatchScreenManager()

    @State private var pageIndex: Int = 0

    // MARK: - Computed

    private var routine: RoutineModel? { sessionDataManager.activeRoutine }

    private var totalPages: Int {
        guard let r = routine else { return 1 }
        return 1 + r.routineList.count  // page 0 = summary, pages 1..N = per step
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            HStack(spacing: 0) {
                // Left dot navigator
                VStack(spacing: 6) {
                    ForEach(0..<totalPages, id: \.self) { i in
                        Circle()
                            .fill(i == pageIndex ? Color.white : Color.gray.opacity(0.4))
                            .frame(width: i == pageIndex ? 8 : 6, height: i == pageIndex ? 8 : 6)
                    }
                }
                .frame(width: 14)
                .padding(.leading, 4)

                // Page content
                Group {
                    if pageIndex == 0 {
                        summaryPage
                    } else {
                        stepPage(index: pageIndex - 1)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.height < -30 {
                        withAnimation { pageIndex = (pageIndex + 1) % totalPages }
                    } else if value.translation.height > 30 {
                        withAnimation { pageIndex = (pageIndex - 1 + totalPages) % totalPages }
                    }
                }
        )
    }

    // MARK: - Summary Page (page 0)

    private var summaryPage: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.green)
                .padding(.top, 16)

            Text("Routine Complete!")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(routine?.nickname ?? "")
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "#00A8FF"))
                .lineLimit(1)

            Spacer()

            Text("Swipe down for recap")
                .font(.system(size: 10))
                .foregroundStyle(.gray)

            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.gray)
                .padding(.bottom, 12)
        }
    }

    // MARK: - Per-Step Page (pages 1..N)

    @ViewBuilder
    private func stepPage(index: Int) -> some View {
        guard let routine = routine, index < routine.routineList.count else {
            return AnyView(EmptyView())
        }
        let step = routine.routineList[index]
        let result = sessionDataManager.routineStepResults.first(where: { $0.step == step.step })
        let stats  = sessionDataManager.routineStepStats[step.step]

        return AnyView(
            Group {
                if step.type == "Modality" {
                    modalityStepPage(step: step, result: result, stats: stats)
                } else {
                    transitionStepPage(step: step)
                }
            }
        )
    }

    // MARK: - Modality Step Page

    private func modalityStepPage(step: RoutineStepModel, result: RoutineStepResult?, stats: RoutineStepStats?) -> some View {
        let unit = sessionDataManager.unitOfMeasure
        let statusText  = result?.status ?? ""
        let statusColor: Color = {
            switch statusText {
            case "Saved":    return .green
            case "Pending":  return .yellow
            case "Skipped":  return Color(hex: "#8EC2FF")
            default:         return .white
            }
        }()

        return VStack(spacing: 4) {
            // Row 1: step# + icon + activity name
            HStack(spacing: 6) {
                Text("\(step.step).")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: "#00A8FF"))
                Image(systemName: activityIcon(for: step.activityType))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                Text(step.activityType ?? "Activity")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
            }
            .padding(.top, 10)
            .padding(.horizontal, 8)

            if let stats = stats {
                // Row 2: time | temp
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "stopwatch")
                            .font(.system(size: 10))
                            .foregroundStyle(.gray)
                        Text(formatTime(stats.totalTime))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    HStack(spacing: 3) {
                        Image(systemName: "thermometer.medium")
                            .font(.system(size: 10))
                            .foregroundStyle(.gray)
                        Text(formatTemp(stats.tempF, unit: unit))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 8)

                // Row 3: HR stats
                HStack(spacing: 4) {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.down.heart")
                            .font(.system(size: 9))
                            .foregroundStyle(.red)
                        Text("\(stats.minHR)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.heart")
                            .font(.system(size: 9))
                            .foregroundStyle(.red)
                        Text("\(stats.maxHR)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: "heart")
                            .font(.system(size: 9))
                            .foregroundStyle(.red)
                        Text("\(stats.avgHR)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 8)
            }

            Spacer()

            // Row 4: Status + Home button
            HStack {
                if !statusText.isEmpty {
                    Text("Status: \(statusText)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(statusColor)
                }
                Spacer()
                Button(action: navigateHome) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Transition Step Page

    private func transitionStepPage(step: RoutineStepModel) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Text("\(step.step).")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: "#00A8FF"))
                Image(systemName: "arrow.right.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
            }
            .padding(.top, 12)

            Text(step.stepNickname ?? "Transition")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 8)

            Spacer()

            Button(action: navigateHome) {
                HStack(spacing: 4) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 11))
                    Text("Home")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.3))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 10)
        }
    }

    // MARK: - Helpers

    private func navigateHome() {
        sessionDataManager.resetRoutineState()
        navigationManager.goToHome()
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func formatTemp(_ f: Double, unit: String) -> String {
        if unit == "Metric" {
            let c = (f - 32) * 5 / 9
            return String(format: "%.1f°C", c)
        }
        return String(format: "%.1f°F", f)
    }

    private func activityIcon(for type: String?) -> String {
        switch type?.lowercased() ?? "" {
        case let s where s.contains("sauna"):   return "heater.vertical"
        case let s where s.contains("plunge"):  return "drop.degreesign"
        case let s where s.contains("shower"):  return "shower"
        case let s where s.contains("tub"):     return "bathtub"
        default:                                return "bolt.heart"
        }
    }
}

#Preview {
    RoutineRecapScreen(navigationManager: NavigationManager())
        .environmentObject(SessionDataManager())
}
