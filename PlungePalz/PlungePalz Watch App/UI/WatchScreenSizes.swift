//
//  WatchScreenSizes.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import SwiftUI
import WatchKit
import Combine

// MARK: - Watch Screen Size Categories
enum WatchScreenSize: String, CaseIterable {
    case small = "SMALL"
    case regular = "REGULAR"
    case ultra = "ULTRA"
    
    var description: String {
        switch self {
        case .small:
            return "38mm, 40mm, 41mm, 42mm (Series 10)"
        case .regular:
            return "42mm (legacy), 44mm, 45mm, 46mm (Series 10)"
        case .ultra:
            return "49mm (Ultra models)"
        }
    }
    
    // Screen dimensions for each category
    var screenDimensions: CGSize {
        switch self {
        case .small:
            return CGSize(width: 162, height: 197) // Representative of 40mm/41mm
        case .regular:
            return CGSize(width: 184, height: 224) // Representative of 44mm/45mm
        case .ultra:
            return CGSize(width: 205, height: 251) // 49mm Ultra
        }
    }
    
    // Corner radius for each screen size
    var cornerRadius: CGFloat {
        switch self {
        case .small:
            return 18
        case .regular:
            return 20
        case .ultra:
            return 22
        }
    }
}

// MARK: - Watch Screen Manager
class WatchScreenManager: ObservableObject {
    @Published var currentScreenSize: WatchScreenSize
    
    init() {
        self.currentScreenSize = WatchScreenManager.detectScreenSize()
    }
    
    static func detectScreenSize() -> WatchScreenSize {
        let screenBounds = WKInterfaceDevice.current().screenBounds
        let screenWidth = screenBounds.width
        
        // Detect based on screen width
        switch screenWidth {
        case 136...162: // 38mm, 40mm, 41mm, 42mm Series 10
            return .small
        case 184...184: // 44mm, 45mm, 46mm Series 10
            return .regular
        case 205...205: // 49mm Ultra
            return .ultra
        default:
            // Default to regular if we can't determine
            return .regular
        }
    }
    
    // Get current screen info
    var currentScreenInfo: (size: WatchScreenSize, dimensions: CGSize, cornerRadius: CGFloat) {
        return (currentScreenSize, currentScreenSize.screenDimensions, currentScreenSize.cornerRadius)
    }
}

// MARK: - UI Configuration for Different Screen Sizes
struct WatchUIConfig {
    let screenSize: WatchScreenSize
    
    init(for screenSize: WatchScreenSize) {
        self.screenSize = screenSize
    }
    
    // Font sizes
    var titleFontSize: CGFloat {
        switch screenSize {
        case .small:
            return 18
        case .regular:
            return 20
        case .ultra:
            return 22
        }
    }
    
    var bodyFontSize: CGFloat {
        switch screenSize {
        case .small:
            return 14
        case .regular:
            return 16
        case .ultra:
            return 18
        }
    }
    
    var captionFontSize: CGFloat {
        switch screenSize {
        case .small:
            return 12
        case .regular:
            return 13
        case .ultra:
            return 14
        }
    }
    
    // Spacing and padding
    var standardPadding: CGFloat {
        switch screenSize {
        case .small:
            return 12
        case .regular:
            return 16
        case .ultra:
            return 20
        }
    }
    
    var compactPadding: CGFloat {
        switch screenSize {
        case .small:
            return 8
        case .regular:
            return 10
        case .ultra:
            return 12
        }
    }
    
    var buttonHeight: CGFloat {
        switch screenSize {
        case .small:
            return 36
        case .regular:
            return 40
        case .ultra:
            return 44
        }
    }
    
    // Icon sizes
    var smallIconSize: CGFloat {
        switch screenSize {
        case .small:
            return 16
        case .regular:
            return 18
        case .ultra:
            return 20
        }
    }
    
    var mediumIconSize: CGFloat {
        switch screenSize {
        case .small:
            return 24
        case .regular:
            return 28
        case .ultra:
            return 32
        }
    }
    
    var largeIconSize: CGFloat {
        switch screenSize {
        case .small:
            return 40
        case .regular:
            return 48
        case .ultra:
            return 56
        }
    }
}

// MARK: - SwiftUI Environment Key
struct WatchScreenSizeKey: EnvironmentKey {
    static let defaultValue: WatchScreenSize = .regular
}

extension EnvironmentValues {
    var watchScreenSize: WatchScreenSize {
        get { self[WatchScreenSizeKey.self] }
        set { self[WatchScreenSizeKey.self] = newValue }
    }
}

// MARK: - View Extensions for Easy Access
extension View {
    func watchScreenSize(_ size: WatchScreenSize) -> some View {
        environment(\.watchScreenSize, size)
    }
    
    func adaptiveForWatch<Content: View>(
        small: () -> Content,
        regular: () -> Content,
        ultra: () -> Content
    ) -> some View {
        @Environment(\.watchScreenSize) var screenSize
        
        switch screenSize {
        case .small:
            return AnyView(small())
        case .regular:
            return AnyView(regular())
        case .ultra:
            return AnyView(ultra())
        }
    }
}

// MARK: - Convenience View Modifiers
extension View {
    func watchAdaptivePadding() -> some View {
        @Environment(\.watchScreenSize) var screenSize
        let config = WatchUIConfig(for: screenSize)
        return self.padding(config.standardPadding)
    }
    
    func watchAdaptiveFont(style: WatchFontStyle) -> some View {
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
        
        return self.font(.system(size: fontSize))
    }
}

enum WatchFontStyle {
    case title, body, caption
} 