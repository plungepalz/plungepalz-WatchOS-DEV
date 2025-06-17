//
//  SetTimerScreen.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import SwiftUI

struct SetTimerScreen: View {
    @StateObject private var screenManager = WatchScreenManager()
    @ObservedObject var navigationManager: NavigationManager
    
    @State private var selectedMinute: Int = 1
    @State private var selectedSecond: Int = 0
    @State private var activePicker: PickerType = .minute
    
    enum PickerType {
        case minute, second
    }
    
    let range = 0...59
    
    var body: some View {

        // ====== Define all adaptive UI constants for SetTimerScreen ======//
        let screenSize = screenManager.currentScreenSize
        let screenHeight = WKInterfaceDevice.current().screenBounds.height

        // Header Assets
        let headerTitleFontSize = WatchGlobalUIConfig.SetTimerScreen.headerTitleFontSize(for: screenSize)
        let headerIconSize = WatchGlobalUIConfig.SetTimerScreen.headerIconSize(for: screenSize)

        // Time Values Assets
        let valuesFontSize = WatchGlobalUIConfig.SetTimerScreen.valuesFontSize(for: screenSize)
        let labelFontSize = WatchGlobalUIConfig.SetTimerScreen.labelFontSize(for: screenSize)
        let valuesContainerWidth = WatchGlobalUIConfig.SetTimerScreen.valuesContainerWidth(for: screenSize)
        let valuesContainerXOffest = WatchGlobalUIConfig.SetTimerScreen.valuesContainerXOffest(for: screenSize)
        let valuesContainerGap = WatchGlobalUIConfig.SetTimerScreen.valuesContainerGap(for: screenSize)
        let labelWidth = WatchGlobalUIConfig.SetTimerScreen.labelWidth(for: screenSize)

        VStack(spacing: 18) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.system(size: headerIconSize, weight: .bold))
                    .foregroundStyle(.white)
                Text("Set Timer")
                    .font(.system(size: headerTitleFontSize, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.top, 4)
            
            // Timer Pickers
            ZStack {
                // Selection highlight
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 32)
                HStack(alignment: .center, spacing: 0) {
                    // Minutes Picker + Label
                    HStack(spacing: valuesContainerGap) {
                        Picker(selection: $selectedMinute.onChange { _ in activePicker = .minute }, label: EmptyView()) {
                            ForEach(range, id: \.self) { value in
                                Text(String(format: "%01d", value))
                                    .font(.system(size: valuesFontSize, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: valuesContainerWidth, height: 100, alignment: .center)
                        .padding(.leading, valuesContainerXOffest)
                        .clipped()
                        .compositingGroup()
                        .pickerStyle(.wheel)
                        Text("min")
                            .font(.system(size: labelFontSize, weight: .regular))
                            .foregroundColor(.white)
                            .frame(width: labelWidth, alignment: .center)
                    }
                    .frame(width: valuesContainerWidth + labelWidth + valuesContainerGap)
                    //.background(Color.red)
                    // Seconds Picker + Label
                    HStack(spacing: valuesContainerGap) {
                        Picker(selection: $selectedSecond.onChange { _ in activePicker = .second }, label: EmptyView()) {
                            ForEach(range, id: \.self) { value in
                                Text(String(format: "%01d", value))
                                    .font(.system(size: valuesFontSize, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: valuesContainerWidth, height: 100, alignment: .center)
                        .padding(.leading, valuesContainerXOffest)
                        .clipped()
                        .compositingGroup()
                        .pickerStyle(.wheel)
                        Text("sec")
                            .font(.system(size: labelFontSize, weight: .regular))
                            .foregroundColor(.white)
                            .frame(width: labelWidth, alignment: .center)
                    }
                    .frame(width: valuesContainerWidth + labelWidth + valuesContainerGap, alignment: .center)
                    //.background(Color.blue)
                    
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            // NEXT button
            Button(action: {
                navigationManager.nextScreen()
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
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            
        }
        .background(Color.black.ignoresSafeArea())
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
    }
}

#Preview {
    SetTimerScreen(navigationManager: NavigationManager())
} 
