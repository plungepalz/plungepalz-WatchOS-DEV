//
//  NotSubscribed.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import SwiftUI

struct NotSubscribed: View {
    @StateObject private var screenManager = WatchScreenManager()
    @ObservedObject var navigationManager: NavigationManager
    
    var body: some View {
        let screenSize = screenManager.currentScreenSize
        let screenHeight = WKInterfaceDevice.current().screenBounds.height
        
        // Enable Digital Crown scrolling with ScrollView
        ScrollView {
            VStack(spacing: 12) {
                // Add top padding to center content vertically
                Spacer()
                    .frame(height: 20)
                
                // Title
                Text("Follow These Steps:")
                    .watchAdaptivePoppinsFont(style: .title, weight: .bold)
                    .foregroundStyle(.yellow)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Step-by-step instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Open PlungePalz mobile app")
                        .watchAdaptivePoppinsFont(style: .body, weight: .regular)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("2. Go to Settings -> Connect Apple Watch")
                        .watchAdaptivePoppinsFont(style: .body, weight: .regular)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("3. Click \"Begin Pairing Process\" to resubscribe")
                        .watchAdaptivePoppinsFont(style: .body, weight: .regular)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("4. Once resubscribed, refresh Watch App")
                        .watchAdaptivePoppinsFont(style: .body, weight: .regular)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Back button
                Button(action: {
                    #if DEBUG
                    print("🔙 NotSubscribed: Back button tapped, returning to Home")
                    #endif
                    navigationManager.goToScreen(.home)
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text("Back")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 24)
                    .background(Color.blue.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                // MODIFICATION: Added to remove the default grey background from the button
                .buttonStyle(.plain)
                
                // Add bottom padding
                Spacer()
                    .frame(height: 20)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
        }
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
        .onTapGesture {
            // Any tap on the screen goes back to home
            #if DEBUG
            print("🔙 NotSubscribed: Screen tapped, returning to Home")
            #endif
            navigationManager.goToScreen(.home)
        }
        .onAppear {
            #if DEBUG
            print("📱 NotSubscribed: Screen appeared - user is in subscription loop")
            #endif
        }
    }
}

#Preview {
    NotSubscribed(navigationManager: NavigationManager())
}