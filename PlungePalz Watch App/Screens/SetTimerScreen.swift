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
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: "timer")
                .font(.system(size: WatchUIConfig(for: screenManager.currentScreenSize).largeIconSize))
                .foregroundStyle(.purple)
            
            // Title
            Text("Set Timer")
                .watchAdaptivePoppinsFont(style: .title, weight: .bold)
            
            // Screen indicator
            Text("We are on Screen 4")
                .watchAdaptivePoppinsFont(style: .body)
                .foregroundStyle(.secondary)
            
            // Navigation buttons
            HStack(spacing: 8) {
                Button("Back") {
                    navigationManager.previousScreen()
                }
                .frame(height: WatchUIConfig(for: screenManager.currentScreenSize).buttonHeight)
                .frame(maxWidth: .infinity)
                .background(.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Button("Next") {
                    navigationManager.nextScreen()
                }
                .frame(height: WatchUIConfig(for: screenManager.currentScreenSize).buttonHeight)
                .frame(maxWidth: .infinity)
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .watchAdaptivePadding()
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
    }
}

#Preview {
    SetTimerScreen(navigationManager: NavigationManager())
} 