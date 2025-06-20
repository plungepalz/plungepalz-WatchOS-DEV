//
//  PendingSaveSessionsScreen.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/11/24.
//

import SwiftUI

struct PendingSaveSessionsScreen: View {
    @StateObject private var screenManager = WatchScreenManager()
    @ObservedObject var navigationManager: NavigationManager
    @State private var pendingSessionsCount: Int = 0

    private func getPendingSessionsCount() -> Int {
        return UserDefaults.standard.array(forKey: "pending_requests")?.count ?? 0
    }
    
    var body: some View {
        let screenSize = screenManager.currentScreenSize
        let screenWidth = WKInterfaceDevice.current().screenBounds.width
        let screenHeight = WKInterfaceDevice.current().screenBounds.height


        // Title UI
        let titleTopPadding = WatchGlobalUIConfig.PendingSaveSessionsScreen.titleTopPadding(for: screenSize)
        let titleBottomPadding = WatchGlobalUIConfig.PendingSaveSessionsScreen.titleBottomPadding(for: screenSize)
        let titleFontSize = WatchGlobalUIConfig.PendingSaveSessionsScreen.titleFontSize(for: screenSize)
        
        // Option UI
        let optionIconSize = WatchGlobalUIConfig.PendingSaveSessionsScreen.optionIconSize(for: screenSize)
        let optionTitleFontSize = WatchGlobalUIConfig.PendingSaveSessionsScreen.optionTitleFontSize(for: screenSize)
        let optionSubtitleFontSize = WatchGlobalUIConfig.PendingSaveSessionsScreen.optionSubtitleFontSize(for: screenSize)
        let iconTitleGap = WatchGlobalUIConfig.PendingSaveSessionsScreen.iconTitleGap(for: screenSize)
        
        // Option Container
        let optionContainerWidthRatio = WatchGlobalUIConfig.PendingSaveSessionsScreen.optionContainerWidthRatio(for: screenSize)
        let optionContainerHeightRatio = WatchGlobalUIConfig.PendingSaveSessionsScreen.optionContainerHeightRatio(for: screenSize)
        
        let optionContainerWidth = screenWidth * optionContainerWidthRatio
        let optionContainerHeight = screenHeight * optionContainerHeightRatio
        
        let optionContainerCornerRadius: CGFloat = 12
        let optionContainerBackground = Color.black
        let deleteRed = Color(red: 1.0, green: 0.36, blue: 0.36)
        
        ZStack {
            Color(red: 0/255, green: 116/255, blue: 255/255)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 10) {
                    Text("\(pendingSessionsCount) Activities Pending Save")
                        .font(.system(size: titleFontSize, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, titleBottomPadding)
                        .padding(.top, titleTopPadding)

                    ActionOptionContainer(
                        iconName: "square.and.arrow.down.on.square",
                        iconSize: optionIconSize,
                        iconTitleGap: iconTitleGap,
                        title: "Save To",
                        subtitle: "PlungePalz App",
                        titleColor: Color.white,
                        iconColor: Color.white,
                        backgroundColor: optionContainerBackground,
                        height: optionContainerHeight,
                        width: optionContainerWidth,
                        titleFontSize: optionTitleFontSize,
                        subtitleFontSize: optionSubtitleFontSize,
                        cornerRadius: optionContainerCornerRadius
                    ) {
                        print("Save To option clicked.")
                        navigationManager.activityMode = .saving
                        navigationManager.goToScreen(.savingOrDeletingPendingActivities)
                    }
                    
                    ActionOptionContainer(
                        iconName: "play",
                        iconSize: optionIconSize,
                        iconTitleGap: iconTitleGap,
                        title: "Ignore",
                        subtitle: "and go home",
                        titleColor: Color.white,
                        iconColor: Color.white,
                        backgroundColor: optionContainerBackground,
                        height: optionContainerHeight,
                        width: optionContainerWidth,
                        titleFontSize: optionTitleFontSize,
                        subtitleFontSize: optionSubtitleFontSize,
                        cornerRadius: optionContainerCornerRadius
                    ) {
                        print("Ignore option clicked. Navigating to HomeScreen.")
                        navigationManager.goToScreen(.home)
                    }
                    
                    ActionOptionContainer(
                        iconName: "trash",
                        iconSize: optionIconSize,
                        iconTitleGap: iconTitleGap,
                        title: "DELETE",
                        subtitle: "ALL SESSIONS",
                        titleColor: deleteRed,
                        iconColor: deleteRed,
                        backgroundColor: optionContainerBackground,
                        height: optionContainerHeight,
                        width: optionContainerWidth,
                        titleFontSize: optionTitleFontSize,
                        subtitleFontSize: optionSubtitleFontSize,
                        cornerRadius: optionContainerCornerRadius
                    ) {
                        print("Delete all sessions option clicked.")
                        navigationManager.activityMode = .deleting
                        navigationManager.goToScreen(.savingOrDeletingPendingActivities)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
        .onAppear {
            pendingSessionsCount = getPendingSessionsCount()
            let pendingRequests = UserDefaults.standard.array(forKey: "pending_requests") as? [[String: Any]] ?? []
            print("=== PENDING SAVE SESSIONS SCREEN DEBUG ===")
            print("Pending Requests: \(pendingRequests)")
            print("========================================")
        }
    }
}

private struct ActionOptionContainer: View {
    let iconName: String
    let iconSize: CGFloat
    let iconTitleGap: CGFloat
    let title: String
    let subtitle: String?
    let titleColor: Color
    let iconColor: Color
    let backgroundColor: Color
    let height: CGFloat
    let width: CGFloat
    let titleFontSize: CGFloat
    let subtitleFontSize: CGFloat
    let cornerRadius: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: iconTitleGap) {
                    Image(systemName: iconName)
                        .font(.system(size: iconSize, weight: .bold))
                        .foregroundColor(iconColor)
                    Text(title)
                        .font(.system(size: titleFontSize, weight: .bold))
                        .foregroundColor(titleColor)
                    Spacer()
                }
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: subtitleFontSize, weight: .regular))
                        .foregroundColor(Color.white)
                        .padding(.top, 2)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: width, minHeight: height, alignment: .leading)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PendingSaveSessionsScreen(navigationManager: NavigationManager())
}
