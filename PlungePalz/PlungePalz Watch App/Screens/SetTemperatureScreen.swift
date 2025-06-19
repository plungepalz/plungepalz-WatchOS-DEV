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
    @State private var selectedDecimal: Int = 1
    
    private let units = ["°F", "°C"]
    private let fahrenheitRange = Array(32...65)
    private let celsiusRange = Array(0...18)
    private let decimals = Array(0...9)

    private func getWholeRange() -> [Int] {
        return selectedUnitIndex == 0 ? fahrenheitRange : celsiusRange
    }
    private func getUnitOfMeasure() -> String {
        return selectedUnitIndex == 0 ? "Imperial" : "Metric"
    }
    private func getTempString() -> String {
        return String(format: "%d.%d", selectedWhole, selectedDecimal)
    }
    private func getInitialUnitIndex() -> Int {
        guard let unit = sessionDataManager.lastSessionData?["unitOfMeasure"] else { return 0 }
        if unit == "Metric" { return 1 }
        return 0
    }
    private func getInitialWhole() -> Int {
        guard let tempStr = sessionDataManager.lastSessionData?["lastSessionWaterTemp"], let temp = Double(tempStr) else {
            // Use preferred defaults if no last session value
            return selectedUnitIndex == 0 ? 45 : 7
        }
        if selectedUnitIndex == 0 {
            return Int(temp.rounded(.down))
        } else {
            // Convert F to C
            let c = (temp - 32) * 5 / 9
            return Int(c.rounded(.down))
        }
    }
    private func getInitialDecimal() -> Int {
        guard let tempStr = sessionDataManager.lastSessionData?["lastSessionWaterTemp"], let temp = Double(tempStr) else {
            return 0 // Always .0 if no last session value
        }
        let decimal = Int((temp * 10).truncatingRemainder(dividingBy: 10))
        return decimal
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
            // Header
            HStack(spacing: 6) {
                Image(systemName: "thermometer.snowflake")
                    .font(.system(size: headerIconSize, weight: .bold))
                    .foregroundStyle(.white)
                Text("Set Temp")
                    .font(.system(size: headerTitleFontSize, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 8)

            // Pickers
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 28)
                HStack(alignment: .center, spacing: valuesContainerGap) {
                    // Unit Picker
                    Picker(selection: $selectedUnitIndex.onChange { newIndex in
                        // When unit changes, set to preferred defaults
                        if newIndex == 0 {
                            selectedWhole = 45
                            selectedDecimal = 0
                        } else {
                            selectedWhole = 7
                            selectedDecimal = 0
                        }
                    }, label: EmptyView()) {
                        ForEach(0..<units.count, id: \ .self) { idx in
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 0)
                    )

                    // Whole Number Picker
                    Picker(selection: $selectedWhole, label: EmptyView()) {
                        ForEach(getWholeRange(), id: \ .self) { value in
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 0)
                    )

                    // Decimal Picker
                    Picker(selection: $selectedDecimal, label: EmptyView()) {
                        ForEach(decimals, id: \ .self) { value in
                            Text(".\(value)")
                                .font(.system(size: valuesFontSize, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: valuesContainerWidthUnitAndDecimal, height: 100)
                    .clipped()
                    .compositingGroup()
                    .pickerStyle(.wheel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 0)
                    )
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }

            // START button
            Button(action: {
                // Save temp and unit as string
                let tempString = getTempString()
                let unitString = getUnitOfMeasure()
                if sessionDataManager.lastSessionData == nil {
                    sessionDataManager.lastSessionData = [:]
                }
                sessionDataManager.lastSessionData?["lastSessionWaterTemp"] = tempString
                sessionDataManager.lastSessionData?["unitOfMeasure"] = unitString
                navigationManager.goToScreen(.prepareCountdown)
            }) {
                HStack {
                    Spacer(minLength: 0)
                    Text("NEXT")
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
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
        .onAppear {
            // Set initial values from API if available
            let initialUnit = getInitialUnitIndex()
            selectedUnitIndex = initialUnit
            selectedWhole = getInitialWhole()
            selectedDecimal = getInitialDecimal()
        }
    }
}

#Preview {
    SetTemperatureScreen(navigationManager: NavigationManager())
        .environmentObject(SessionDataManager())
} 