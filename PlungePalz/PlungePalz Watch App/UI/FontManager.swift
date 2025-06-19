//
//  FontManager.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import SwiftUI

// MARK: - Font Manager
struct FontManager {
    
    // Check if Poppins font is available
    static var isPoppinsAvailable: Bool {
        return UIFont.familyNames.contains("Poppins")
    }
    
    // Get font with Poppins or fallback to system
    static func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if isPoppinsAvailable {
            switch weight {
            case .light:
                return .custom("Poppins-Light", size: size)
            case .regular:
                return .custom("Poppins-Regular", size: size)
            case .medium:
                return .custom("Poppins-Medium", size: size)
            case .semibold:
                return .custom("Poppins-SemiBold", size: size)
            case .bold:
                return .custom("Poppins-Bold", size: size)
            default:
                return .custom("Poppins-Regular", size: size)
            }
        } else {
            // Fallback to system font
            return .system(size: size, weight: weight)
        }
    }
}

// MARK: - Font Style Extensions
extension WatchUIConfig {
    
    // Updated font methods using FontManager
    var titleFont: Font {
        return FontManager.font(size: titleFontSize, weight: .bold)
    }
    
    var bodyFont: Font {
        return FontManager.font(size: bodyFontSize, weight: .regular)
    }
    
    var captionFont: Font {
        return FontManager.font(size: captionFontSize, weight: .regular)
    }
}

// MARK: - Updated View Modifiers
extension View {
    func watchAdaptivePoppinsFont(style: WatchFontStyle, weight: Font.Weight = .regular) -> some View {
        @Environment(\.watchScreenSize) var screenSize
        let config = WatchUIConfig(for: screenSize)
        
        let fontSize: CGFloat
        switch style {
        case .title:
            fontSize = config.titleFontSize
        case .body:
            fontSize = config.bodyFontSize
        case .caption:
            fontSize = config.captionFontSize
        }
        
        return self.font(FontManager.font(size: fontSize, weight: weight))
    }
} 