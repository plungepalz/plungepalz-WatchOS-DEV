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
    @State private var crownPage: Double = 0
    @FocusState private var isCrownFocused: Bool

    // Access screen size config
    @Environment(\.watchScreenSize) private var screenSize

    // MARK: - Computed

    private var routine: RoutineModel? { sessionDataManager.activeRoutine }

    private var totalPages: Int {
        guard let r = routine else { return 1 }
        return 1 + r.routineList.count  // page 0 = summary, pages 1..N = per step
    }

    // MARK: - Body

    var body: some View {
        let maxPage = max(0, totalPages - 1)

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
                        setPageIndex((pageIndex + 1) % totalPages)
                    } else if value.translation.height > 30 {
                        setPageIndex((pageIndex - 1 + totalPages) % totalPages)
                    }
                }
        )
        .focusable(true)
        .focused($isCrownFocused)
        .digitalCrownRotation(
            $crownPage,
            from: 0,
            through: Double(maxPage),
            by: 1,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: crownPage) { _, newValue in
            let targetPage = min(maxPage, max(0, Int(round(newValue))))
            guard targetPage != pageIndex else { return }
            withAnimation {
                pageIndex = targetPage
            }
        }
        .onAppear {
            crownPage = Double(pageIndex)
            DispatchQueue.main.async {
                isCrownFocused = true
            }
        }
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
                .font(.system(size: 15))
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
        let safeActivityType = step.activityType ?? "Modality"
        let sfSymbol = getSFSymbol(for: safeActivityType)
        let color = getColor(for: safeActivityType)

        let statusText: String
        let statusColor: Color

        // Map your exact string statuses to UI representation
        if result?.status == "Saved" {
            statusText = "Saved"
            statusColor = .green
        } else if result?.status == "Pending" {
            statusText = "Pending"
            statusColor = .orange
        } else {
            statusText = "Skipped"
            statusColor = .gray
        }

        return VStack(spacing: 8) {
            // Row 1: Step Circle + Icon + Name (Spanning Full Horizontal Width)
            HStack(spacing: 8) {
                // Step Circle
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(
                            width: WatchGlobalUIConfig.RoutineRecapScreen.stepCircleSize(for: screenSize),
                            height: WatchGlobalUIConfig.RoutineRecapScreen.stepCircleSize(for: screenSize)
                        )
                    Text("\(step.step)")
                        .font(.system(size: WatchGlobalUIConfig.RoutineRecapScreen.stepFontSize(for: screenSize), weight: .bold))
                        .foregroundStyle(.white)
                }

                // Icon + Activity Name
                HStack(spacing: 4) {
                    Image(systemName: sfSymbol)
                        .font(.system(size: WatchGlobalUIConfig.RoutineRecapScreen.modalityTopRowIconSize(for: screenSize)))
                    Text(safeActivityType)
                        .font(.system(size: WatchGlobalUIConfig.RoutineRecapScreen.modalityTopRowFontSize(for: screenSize), weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(color)

                Spacer()
            }
            .padding(.horizontal, 4)

            Divider()

            // Conditional Row 2 & 3 (Show data if saved or pending)
            if statusText == "Saved" || statusText == "Pending" {
                // Row 2: Time | Temp
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: WatchGlobalUIConfig.RoutineRecapScreen.timeTempIconSize(for: screenSize)))
                            .foregroundStyle(.gray)
                        // Fallback to planned step length if stats totalTime is missing
                        let timeVal = stats?.totalTime ?? step.sLength
                        Text(formatTime(timeVal))
                            .font(.system(size: WatchGlobalUIConfig.RoutineRecapScreen.timeTempFontSize(for: screenSize), weight: .semibold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 4) {
                        Image(systemName: "thermometer")
                            .font(.system(size: WatchGlobalUIConfig.RoutineRecapScreen.timeTempIconSize(for: screenSize)))
                            .foregroundStyle(.gray)
                        // Fallback to planned step tempF if stats temp is missing
                        let tempVal = stats?.tempF ?? step.tempF ?? 0
                        let tempStr = tempVal > 0 ? formatTemp(tempVal, unit: sessionDataManager.unitOfMeasure) : "--"
                        Text(tempStr)
                            .font(.system(size: WatchGlobalUIConfig.RoutineRecapScreen.timeTempFontSize(for: screenSize), weight: .semibold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 8)

                // Row 3: HR Stats
                if let stats = stats {
                    HStack(spacing: 4) {
                        // Min HR
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.down.heart.fill")
                                .font(.system(size: WatchGlobalUIConfig.RoutineRecapScreen.hrStatsIconSize(for: screenSize)))
                                .foregroundStyle(.red)
                            Text(formatHR(Double(stats.minHR)))
                                .font(.system(size: WatchGlobalUIConfig.RoutineRecapScreen.hrStatsFontSize(for: screenSize), weight: .bold))
                        }
                        .frame(maxWidth: .infinity)

                        // Avg HR
                        VStack(spacing: 2) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: WatchGlobalUIConfig.RoutineRecapScreen.hrStatsIconSize(for: screenSize)))
                                .foregroundStyle(.red)
                            Text(formatHR(Double(stats.avgHR)))
                                .font(.system(size: WatchGlobalUIConfig.RoutineRecapScreen.hrStatsFontSize(for: screenSize), weight: .bold))
                        }
                        .frame(maxWidth: .infinity)

                        // Max HR
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.up.heart.fill")
                                .font(.system(size: WatchGlobalUIConfig.RoutineRecapScreen.hrStatsIconSize(for: screenSize)))
                                .foregroundStyle(.red)
                            Text(formatHR(Double(stats.maxHR)))
                                .font(.system(size: WatchGlobalUIConfig.RoutineRecapScreen.hrStatsFontSize(for: screenSize), weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 4)
                } else {
                    Text("No HR Data")
                        .font(.system(size: WatchGlobalUIConfig.RoutineRecapScreen.hrStatsFontSize(for: screenSize)))
                        .foregroundStyle(.gray)
                        .padding(.vertical, 4)
                }

                Divider()
            }

            // Bottom Status Row
            HStack {
                Text(statusText)
                    .font(.system(size: WatchGlobalUIConfig.RoutineRecapScreen.statusFontSize(for: screenSize), weight: .bold))
                    .foregroundStyle(statusColor)

                Spacer()

                Button(action: {
                    navigateHome()
                }) {
                    Image(systemName: "house.fill")
                        .font(.system(size: WatchGlobalUIConfig.RoutineRecapScreen.homeIconSize(for: screenSize)))
                        .foregroundStyle(Color(hex: "#00A8FF"))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)

            Spacer()
        }
        .padding(.vertical, 8)
    }

    // Helper strictly limits double-based HRs down to no-decimal integers
    private func formatHR(_ value: Double) -> String {
        return value > 0 ? String(Int(value)) : "--"
    }

    // MARK: - Transition Step Page
    private func transitionStepPage(step: RoutineStepModel) -> some View {
        return VStack(spacing: 16) {

            // Top row: Step in circle | Icon | "Transition"
            HStack(spacing: 8) {
                // Step Circle
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(
                            width: WatchGlobalUIConfig.RoutineRecapScreen.stepCircleSize(for: screenSize),
                            height: WatchGlobalUIConfig.RoutineRecapScreen.stepCircleSize(for: screenSize)
                        )
                    Text("\(step.step)")
                        .font(.system(size: WatchGlobalUIConfig.RoutineRecapScreen.stepFontSize(for: screenSize), weight: .bold))
                        .foregroundStyle(.white)
                }

                // Green Icon & Text
                HStack(spacing: 6) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: WatchGlobalUIConfig.RoutineRecapScreen.transitionIconSize(for: screenSize)))
                    Text("Transition")
                        .font(.system(size: WatchGlobalUIConfig.RoutineRecapScreen.transitionFontSize(for: screenSize), weight: .bold))
                }
                .foregroundStyle(.green)

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.top, 16)

            // Step Nickname
            let nickname = step.stepNickname ?? ""
            Text(nickname.isEmpty ? "Rest" : nickname)
                .font(.system(size: WatchGlobalUIConfig.RoutineRecapScreen.transitionNicknameFontSize(for: screenSize), weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)

            Spacer()

            // Home Button
            Button(action: {
                navigateHome()
            }) {
                Image(systemName: "house.fill")
                    .font(.system(size: WatchGlobalUIConfig.RoutineRecapScreen.homeIconSize(for: screenSize)))
                    .foregroundStyle(Color(hex: "#00A8FF"))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Helpers

    private func getSFSymbol(for type: String) -> String {
        switch type {
        case "Cold Plunge": return "drop.degreesign"
        case "Cold Shower": return "shower"
        case "Sauna": return "heater.vertical"
        case "Steam Room": return "cloud.fog"
        case "Hot Tub": return "water.waves"
        default: return "questionmark.circle"
        }
    }

    private func getColor(for type: String) -> Color {
        switch type {
        case "Cold Plunge": return Color(red: 0.24, green: 0.78, blue: 1.0)
        case "Cold Shower": return .blue
        case "Sauna": return .orange
        case "Steam Room": return .gray
        case "Hot Tub": return Color(red: 0.95, green: 0.35, blue: 0.25)
        default: return .white
        }
    }

    private func navigateHome() {
        sessionDataManager.resetRoutineState()
        navigationManager.goToHome()
    }

    private func setPageIndex(_ newIndex: Int) {
        withAnimation {
            pageIndex = newIndex
            crownPage = Double(newIndex)
        }
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

}

#Preview {
    RoutineRecapScreen(navigationManager: NavigationManager())
        .environmentObject(SessionDataManager())
}