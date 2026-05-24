//
//  WatchBackNavigation.swift
//  PlungePalz Watch App
//

import SwiftUI

struct WatchBackNavigationModifier: ViewModifier {
    @ObservedObject var navigationManager: NavigationManager
    let iconSize: CGFloat
    let topPadding: CGFloat

    private func navigateBack() {
        navigationManager.goToPreviousScreen()
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topLeading) {
                Button(action: navigateBack) {
                    Image(systemName: "arrowshape.backward.circle")
                        .font(.system(size: iconSize, weight: .medium))
                        .foregroundStyle(.white)
                        // 👇 1. Expand the frame around the icon to create a larger tap target
                        .frame(width: iconSize + 24, height: iconSize + 24)
                        // 👇 2. Tell watchOS that this entire expanded frame is clickable
                        .contentShape(Rectangle()) 
                }
                .buttonStyle(.plain)
                // 👇 3. Shift the button slightly to account for the newly expanded frame
                .padding(.leading, -2)
                .padding(.top, topPadding)
                .zIndex(1)
            }
            .gesture(
                DragGesture(minimumDistance: 25)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = abs(value.translation.height)
                        if horizontal > 40 && horizontal > vertical {
                            navigateBack()
                        }
                    }
            )
    }
}

extension View {
    func watchBackNavigation(
        navigationManager: NavigationManager,
        iconSize: CGFloat = 30, // 👈 Increased default size to make it more visible
        topPadding: CGFloat = 0 // 👈 Reset default padding
    ) -> some View {
        modifier(WatchBackNavigationModifier(
            navigationManager: navigationManager,
            iconSize: iconSize,
            topPadding: topPadding
        ))
    }
}