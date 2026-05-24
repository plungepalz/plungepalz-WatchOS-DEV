//
//  SetTemperatureScreen.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import SwiftUI

struct SetTemperatureScreen: View {
    @EnvironmentObject var sessionDataManager: SessionDataManager
    @StateObject private var screenManager = WatchScreenManager()
    @ObservedObject var navigationManager: NavigationManager

    @State private var selectedUnitIndex: Int = 0 // 0 = °F, 1 = °C
    @State private var selectedWhole: Int = 45
    @State private var selectedDecimal: Int = 0

    private let units = ["°F", "°C"]
    private let decimals = Array(0...9)

    private var tempConfig: TemperatureRangeConfig {
        TemperatureRanges.config(for: sessionDataManager.activityType)
    }

    private func getWholeRange() -> [Int] {
        selectedUnitIndex == 0
            ? TemperatureRanges.fahrenheitRange(for: sessionDataManager.activityType)
            : TemperatureRanges.celsiusRange(for: sessionDataManager.activityType)
    }

    private func getUnitOfMeasure() -> String {
        selectedUnitIndex == 0 ? "Imperial" : "Metric"
    }

    private func getTempString() -> String {
        String(format: "%d.%d", selectedWhole, selectedDecimal)
    }

    private func getInitialUnitIndex() -> Int {
        sessionDataManager.unitOfMeasure == "Metric" ? 1 : 0
    }

    private func applyDefaultsForCurrentUnit() {
        let config = tempConfig
        if selectedUnitIndex == 0 {
            selectedWhole = config.fahrenheitDefault
        } else {
            selectedWhole = config.celsiusDefault
        }
        selectedDecimal = 0
    }

    private func getInitialWhole() -> Int {
        let config = tempConfig
        if selectedUnitIndex == 0 {
            return config.fahrenheitDefault
        }
        return config.celsiusDefault
    }

    var body: some View {
        let screenSize = screenManager.currentScreenSize
        let headerIconSize = WatchGlobalUIConfig.SetTemperatureScreen.headerIconSize(for: screenSize)
        let headerTitleFontSize = WatchGlobalUIConfig.SetTemperatureScreen.headerTitleFontSize(for: screenSize)
        let valuesFontSize = WatchGlobalUIConfig.SetTemperatureScreen.valuesFontSize(for: screenSize)
        let valuesContainerWidthUnitAndDecimal = WatchGlobalUIConfig.SetTemperatureScreen.valuesContainerWidthUnitAndDecimal(for: screenSize)
        let valuesContainerWidthWholeNumber = WatchGlobalUIConfig.SetTemperatureScreen.valuesContainerWidthWholeNumber(for: screenSize)
        let pickerContainerPaddingTrailing = WatchGlobalUIConfig.SetTemperatureScreen.pickerContainerPaddingTrailing(for: screenSize)
        let valuesContainerGap = WatchGlobalUIConfig.SetTemperatureScreen.valuesContainerGap(for: screenSize)
        let buttonTopPadding = WatchGlobalUIConfig.SetTemperatureScreen.buttonTopPadding(for: screenSize)
        let buttonInternalTopPadding = WatchGlobalUIConfig.SetTemperatureScreen.buttonInternalTopPadding(for: screenSize)

        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "thermometer")
                    .font(.system(size: headerIconSize, weight: .bold))
                    .foregroundStyle(.white)
                Text("Set Temp")
                    .font(.system(size: headerTitleFontSize, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.top, 20)
            .padding(.bottom, 8)

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 28)
                HStack(alignment: .center, spacing: valuesContainerGap) {
                    Picker(selection: $selectedUnitIndex.onChange { _ in
                        applyDefaultsForCurrentUnit()
                    }, label: EmptyView()) {
                        ForEach(0..<units.count, id: \.self) { idx in
                            Text(units[idx])
                                .font(.system(size: valuesFontSize, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: valuesContainerWidthUnitAndDecimal, height: 100)
                    .padding(.trailing, pickerContainerPaddingTrailing)
                    .clipped()
                    .compositingGroup()
                    .pickerStyle(.wheel)

                    Picker(selection: $selectedWhole, label: EmptyView()) {
                        ForEach(getWholeRange(), id: \.self) { value in
                            Text("\(value)")
                                .font(.system(size: valuesFontSize, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: valuesContainerWidthWholeNumber, height: 100)
                    .padding(.trailing, pickerContainerPaddingTrailing)
                    .clipped()
                    .compositingGroup()
                    .pickerStyle(.wheel)

                    Picker(selection: $selectedDecimal, label: EmptyView()) {
                        ForEach(decimals, id: \.self) { value in
                            Text(".\(value)")
                                .font(.system(size: valuesFontSize, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: valuesContainerWidthUnitAndDecimal, height: 100)
                    .clipped()
                    .compositingGroup()
                    .pickerStyle(.wheel)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }

            Button(action: {
                var tempF: Double
                if selectedUnitIndex == 1 {
                    let celsius = Double(getTempString()) ?? 0
                    tempF = (celsius * 9 / 5) + 32
                } else {
                    tempF = Double(getTempString()) ?? 0
                }

                sessionDataManager.sessionTempF = tempF
                navigationManager.originalNavigationSource = .setTemperature
                navigationManager.goToScreen(.getReadyCountdownTimer)
            }) {
                HStack {
                    Spacer(minLength: 0)
                    Text("START")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Image(systemName: "arrow.forward")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, buttonInternalTopPadding)
                .background(Color.blue.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 6)
            .padding(.top, buttonTopPadding)
        }
        .background(Color.black.ignoresSafeArea())
        .watchBackNavigation(navigationManager: navigationManager, iconSize: headerIconSize)
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
        .onAppear {
            selectedUnitIndex = getInitialUnitIndex()
            selectedWhole = getInitialWhole()
            selectedDecimal = 0
        }
    }
}

#Preview {
    SetTemperatureScreen(navigationManager: NavigationManager())
        .environmentObject(SessionDataManager())
}
