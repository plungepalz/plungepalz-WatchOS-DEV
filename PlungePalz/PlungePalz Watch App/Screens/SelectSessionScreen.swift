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
    @State private var selectedOption: OptionType? = nil
    
    enum OptionType {
        case useLast
        case createNew
    }
    
    var body: some View {

        // ====== Define all adaptive UI constants for SelectSessionScreen ======//
        let screenSize = screenManager.currentScreenSize
        let screenHeight = WKInterfaceDevice.current().screenBounds.height

        // Container Adaptive Constants
        let optionContainerPaddingHorizontal = WatchGlobalUIConfig.SelectSessionScreen.optionContainerPaddingHorizontal(for: screenSize)
        let optionContainerTitleFontSize = WatchGlobalUIConfig.SelectSessionScreen.optionContainerTitleFontSize(for: screenSize)
        let optionContainerSubtitleFontSize = WatchGlobalUIConfig.SelectSessionScreen.optionContainerSubtitleFontSize(for: screenSize)

        ZStack {
            Color(red: 0/255, green: 116/255, blue: 255/255)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    if let lastSession = sessionDataManager.lastSessionData {
                        Button(action: {
                            selectedOption = .useLast
                            navigationManager.goToScreen(.prepareCountdown)
                        }) {
                            OptionContainer(
                                iconName: "repeat",
                                title: "Use Last",
                                subtitle: "\(lastSession["lastSessionTimeSet"] ?? "") | \(formattedTemp(lastSession))",
                                isSelected: selectedOption == .useLast,
                                titleFontSize: optionContainerTitleFontSize,
                                subtitleFontSize: optionContainerSubtitleFontSize
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    Button(action: {
                        selectedOption = .createNew
                        navigationManager.goToScreen(.setTimer)
                    }) {
                        OptionContainer(
                            iconName: "plus",
                            title: "Create New Session",
                            subtitle: nil,
                            isSelected: selectedOption == .createNew,
                            titleFontSize: optionContainerTitleFontSize,
                            subtitleFontSize: optionContainerSubtitleFontSize
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical, 20)
                .padding(.horizontal, optionContainerPaddingHorizontal)
            }
        }
        .onAppear {
            if sessionDataManager.lastSessionData != nil {
                selectedOption = .useLast
            } else {
                selectedOption = .createNew
            }
        }
        .onChange(of: sessionDataManager.lastSessionData) { newValue in
            if newValue != nil {
                selectedOption = .useLast
            } else {
                selectedOption = .createNew
            }
        }
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
    }
    
    func formattedTemp(_ data: [String: String]) -> String {
        guard let tempFStr = data["lastSessionWaterTemp"],
              let tempF = Double(tempFStr),
              let unit = data["unitOfMeasure"] else { return "--" }
        if unit == "Metric" {
            let tempC = (tempF - 32) * 5 / 9
            return String(format: "%.1f ℃", tempC)
        } else {
            return String(format: "%.1f ℉", tempF)
        }
    }
}

struct OptionContainer: View {
    let iconName: String
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let titleFontSize: CGFloat
    let subtitleFontSize: CGFloat
    
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
        .background(isSelected ? Color.black : Color(red: 0.07, green: 0.18, blue: 0.45))
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
        )
    }
}

#Preview {
    let previewManager: SessionDataManager = {
        let manager = SessionDataManager()
        manager.lastSessionData = [
            "lastSessionTimeSet": "3:15",
            "lastSessionWaterTemp": "45.5",
            "unitOfMeasure": "Imperial"
        ]
        return manager
    }()
    return SelectSessionScreen(navigationManager: NavigationManager())
        .environmentObject(previewManager)
} 
