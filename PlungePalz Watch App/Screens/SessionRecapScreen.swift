//
//  SessionRecapScreen.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import SwiftUI

struct SessionRecapScreen: View {
    @StateObject private var screenManager = WatchScreenManager()
    @ObservedObject var navigationManager: NavigationManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: "chart.bar")
                .font(.system(size: WatchUIConfig(for: screenManager.currentScreenSize).largeIconSize))
                .foregroundStyle(.mint)
            
            // Title
            Text("Session Recap")
                .watchAdaptivePoppinsFont(style: .title, weight: .bold)
            
            // Screen indicator
            Text("We are on Screen 8")
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
                
                Button("Home") {
                    navigationManager.nextScreen() // This will go back to home
                }
                .frame(height: WatchUIConfig(for: screenManager.currentScreenSize).buttonHeight)
                .frame(maxWidth: .infinity)
                .background(.green)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .watchAdaptivePadding()
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
    }
}

#Preview {
    SessionRecapScreen(navigationManager: NavigationManager())
} 