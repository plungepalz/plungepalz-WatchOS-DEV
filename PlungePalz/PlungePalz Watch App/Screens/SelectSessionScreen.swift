//
//  SelectSessionScreen.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import SwiftUI

struct SelectSessionScreen: View {
    @EnvironmentObject var sessionDataManager: SessionDataManager
    @StateObject private var screenManager = WatchScreenManager()
    @ObservedObject var navigationManager: NavigationManager
    private var hasUseLast: Bool {
        sessionDataManager.hasUseLastForCurrentActivity
    }

    private var useLastSubtitle: String? {
        guard let params = sessionDataManager.currentActivitySettings?.latestSessionParams else { return nil }
        let timeStr = SessionDataManager.formatTime(seconds: sessionDataManager.useLastDisplayTimeSeconds(for: params))
        let tempStr = sessionDataManager.formatTempDisplay(tempF: params.tempF)
        return "\(timeStr) | \(tempStr)"
    }

    var body: some View {

        let screenSize = screenManager.currentScreenSize

        let optionContainerPaddingHorizontal = WatchGlobalUIConfig.SelectSessionScreen.optionContainerPaddingHorizontal(for: screenSize)
        let optionContainerTitleFontSize = WatchGlobalUIConfig.SelectSessionScreen.optionContainerTitleFontSize(for: screenSize)
        let optionContainerSubtitleFontSize = WatchGlobalUIConfig.SelectSessionScreen.optionContainerSubtitleFontSize(for: screenSize)

        ZStack {
            Color(red: 0/255, green: 116/255, blue: 255/255)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    if hasUseLast, let subtitle = useLastSubtitle {
                        Button(action: {
                            sessionDataManager.applyUseLastSession()
                            navigationManager.originalNavigationSource = .selectSession
                            navigationManager.goToScreen(.getReadyCountdownTimer)
                        }) {
                            OptionContainer(
                                iconName: "repeat",
                                title: "Use Last",
                                subtitle: subtitle,
                                titleFontSize: optionContainerTitleFontSize,
                                subtitleFontSize: optionContainerSubtitleFontSize
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    Button(action: {
                        if sessionDataManager.isCurrentActivityCountdown {
                            navigationManager.goToScreen(.setTimer)
                        } else {
                            navigationManager.goToScreen(.setTemperature)
                        }
                    }) {
                        OptionContainer(
                            iconName: "plus",
                            title: "Create New Session",
                            subtitle: nil,
                            titleFontSize: optionContainerTitleFontSize,
                            subtitleFontSize: optionContainerSubtitleFontSize
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical, 20)
                .padding(.horizontal, optionContainerPaddingHorizontal)
                .padding(.top, 0)
            }
        }
        .watchBackNavigation(
            navigationManager: navigationManager,
            iconSize: 32, // Override with a larger size for this specific screen if needed
            topPadding: -40 // Tweak this small value to nudge it up or down perfectly
        )
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
    }
}

struct OptionContainer: View {
    let iconName: String
    let title: String
    let subtitle: String?
    let titleFontSize: CGFloat
    let subtitleFontSize: CGFloat

    private static let containerBackground = Color.black

    var body: some View {

        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 0) {
                Image(systemName: iconName)
                    .font(.system(size: 22, weight: .bold))
                    .padding(.trailing, 6)
                if subtitle == nil && title == "Create New Session" {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Create New")
                            .font(.system(size: titleFontSize, weight: .bold))
                        Text("Session")
                            .font(.system(size: titleFontSize, weight: .bold))
                    }
                } else {
                    Text(title)
                        .font(.system(size: titleFontSize, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: subtitleFontSize, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .lineLimit(1)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Self.containerBackground)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    let previewManager: SessionDataManager = {
        let manager = SessionDataManager()
        manager.unitOfMeasure = "Imperial"
        manager.activityType = "Cold Plunge"
        manager.activityTypeSettings = [
            ActivityTypeSetting(
                activityType: "Cold Plunge",
                timerSettingMode: "Countdown",
                latestSessionParams: LatestSessionParams(totalTimeS: 195, setTimeS: 150, tempF: 45.5)
            )
        ]
        return manager
    }()
    return SelectSessionScreen(navigationManager: NavigationManager())
        .environmentObject(previewManager)
}
