//
//  HomeScreen.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import SwiftUI

struct HomeScreen: View {
    @StateObject private var screenManager = WatchScreenManager()
    @ObservedObject var navigationManager: NavigationManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Adaptive icon that changes size based on watch screen
            Image(systemName: "drop.fill")
                .font(.system(size: WatchUIConfig(for: screenManager.currentScreenSize).largeIconSize))
                .foregroundStyle(.blue)
            
            // Adaptive title text
            Text("PlungePalz")
                .watchAdaptivePoppinsFont(style: .title, weight: .bold)
            
            // Screen indicator
            Text("We are on Screen 1")
                .watchAdaptivePoppinsFont(style: .body)
                .foregroundStyle(.secondary)
            
            // Navigation button
            Button("Start Plunge") {
                navigationManager.nextScreen()
            }
            .frame(height: WatchUIConfig(for: screenManager.currentScreenSize).buttonHeight)
            .frame(maxWidth: .infinity)
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .watchAdaptivePadding()
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
    }
}

#Preview {
    HomeScreen(navigationManager: NavigationManager())
} 