//
//  SessionDeletedScreen.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import SwiftUI

struct SessionDeletedScreen: View {
    @StateObject private var screenManager = WatchScreenManager()
    @ObservedObject var navigationManager: NavigationManager
    
    var body: some View {

        // Screen Size
        let screenSize = screenManager.currentScreenSize

        // UI Constants
        let iconSize = WatchGlobalUIConfig.SessionDeletedScreen.iconSize(for: screenManager.currentScreenSize)
        let titleFontSize = WatchGlobalUIConfig.SessionDeletedScreen.titleFontSize(for: screenManager.currentScreenSize)
        let buttonVerticalPadding = WatchGlobalUIConfig.SessionDeletedScreen.buttonVerticalPadding(for: screenManager.currentScreenSize)

        VStack(spacing: 16) {
            Image(systemName: "trash")
                .font(.system(size: iconSize))
                .foregroundStyle(.green)
            Text("Session Deleted")
                .font(.system(size: titleFontSize, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: {
                navigationManager.goToScreen(.home)
            }) {
                HStack {
                    Text("Go Home")
                    Image(systemName: "house")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, buttonVerticalPadding)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 50))
            }
        }
        .padding()
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
    }
}

#Preview {
    SessionDeletedScreen(navigationManager: NavigationManager())
} 