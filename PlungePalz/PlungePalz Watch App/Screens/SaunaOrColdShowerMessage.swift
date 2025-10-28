//
//  SaunaOrColdShowerMessage.swift
//  PlungePalz Watch App
//
//  Dynamic info screen for Sauna and Cold Shower activities
//

import SwiftUI
import WatchKit

struct SaunaOrColdShowerMessage: View {
    @EnvironmentObject var sessionDataManager: SessionDataManager
    @StateObject private var screenManager = WatchScreenManager()
    @ObservedObject var navigationManager: NavigationManager
    
    // Dynamic content based on activity type
    private var activityTitle: String {
        switch sessionDataManager.activityType {
        case "Sauna":
            return "Sauna Info"
        case "Cold Shower":
            return "Cold Shower Info"
        default:
            return "Activity Info"
        }
    }
    
    private var activityIcon: String {
        switch sessionDataManager.activityType {
        case "Sauna":
            return "heater.vertical"
        case "Cold Shower":
            return "shower"
        default:
            return "info.circle"
        }
    }
    
    private var activityMessage: String {
        switch sessionDataManager.activityType {
        case "Cold Shower":
            return "Default temp: 45°F / 7.2°C. Know your actual coldest shower water temp? Change the default Cold Shower temp in the mobile app settings."
        case "Sauna":
            return "Default temp: 180°F / 82°C. Prefer a different fixed temp? Update the Sauna temp in the mobile app settings."
        default:
            return "Activity information not available."
        }
    }
    
    private var activityColor: Color {
        switch sessionDataManager.activityType {
        case "Sauna":
            return Color.orange
        case "Cold Shower":
            return Color.blue
        default:
            return Color.gray
        }
    }
    
    var body: some View {
        let screenSize = screenManager.currentScreenSize
        let screenWidth = WKInterfaceDevice.current().screenBounds.width
        let screenHeight = WKInterfaceDevice.current().screenBounds.height
        
        // Adaptive sizing
        let iconSize: CGFloat = screenHeight <= 197 ? 35 : (screenHeight <= 224 ? 40 : 45)
        let titleSize: CGFloat = screenHeight <= 197 ? 18 : (screenHeight <= 224 ? 20 : 22)
        let messageSize: CGFloat = screenHeight <= 197 ? 14 : (screenHeight <= 224 ? 15 : 16)
        let buttonPaddingVertical: CGFloat = screenHeight <= 197 ? 8 : (screenHeight <= 224 ? 10 : 12)
        let buttonPaddingHorizontal: CGFloat = screenHeight <= 197 ? 16 : (screenHeight <= 224 ? 20 : 24)
        
        ScrollView {
            VStack(spacing: 16) {
                // Icon
                Image(systemName: activityIcon)
                    .font(.system(size: iconSize, weight: .bold))
                    .foregroundStyle(activityColor)
                    .padding(.top, 12)
                
                // Title
                Text(activityTitle)
                    .font(.system(size: titleSize, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                // Message
                Text(activityMessage)
                    .font(.system(size: messageSize, weight: .regular))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
                    .lineSpacing(2)
                
                // Continue Button
                Button(action: {
                    #if DEBUG
                    print("✅ User acknowledged \(sessionDataManager.activityType) info, navigating to SelectSession")
                    #endif
                    navigationManager.goToScreen(.selectSession)
                }) {
                    HStack {
                        Text("Continue")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, buttonPaddingVertical)
                    .padding(.horizontal, buttonPaddingHorizontal)
                    .background(activityColor)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
                
                // Back Button
                Button(action: {
                    #if DEBUG
                    print("🔙 User going back to Home")
                    #endif
                    navigationManager.goToHome()
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        Text("Back")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, buttonPaddingVertical * 0.8)
                    .padding(.horizontal, buttonPaddingHorizontal * 0.8)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
        .onAppear {
            #if DEBUG
            print("📱 SaunaOrColdShowerMessage: Appeared for activity type: \(sessionDataManager.activityType)")
            #endif
        }
    }
}

#Preview {
    SaunaOrColdShowerMessage(navigationManager: NavigationManager())
        .environmentObject(SessionDataManager())
}