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
            return "49mm (Ultra 2, Ultra 3)"
        }
    }
    
    // Screen dimensions for each category
    var screenDimensions: CGSize {
        switch self {
        case .small:
            return CGSize(width: 162, height: 197) // Representative of 40mm/41mm
        case .regular:
            return CGSize(width: 184, height: 224) // Representative of 44mm/45mm/46mm
        case .ultra:
            return CGSize(width: 211, height: 257) // Ultra 3 (Ultra 2 is 205×251, same tier as 46mm regular)
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

        // Known logical widths (pt):
        // small:  136–187  (38–42mm class, incl. Series 10/11 42mm at 187)
        // regular: 184–210 (44–46mm class; Ultra 2 also reports 205×251, same as Series 10 46mm)
        // ultra:  211+     (Ultra 3 at 211×257)
        switch screenWidth {
        case ..<188:
            return .small
        case 188..<211:
            return .regular
        default:
            return .ultra
        }
    }

    #if DEBUG
    static func logDetectedScreenSize(context: String = "App launch") {
        let bounds = WKInterfaceDevice.current().screenBounds
        let size = detectScreenSize()
        print("📐 [DEV] \(context) — Watch screen category: \(size.rawValue) (\(size.description)), bounds: \(Int(bounds.width))×\(Int(bounds.height)) pt")
    }
    #endif
    
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

// MARK: - View Modifiers

private struct AdaptiveForWatchContainer<Small: View, Regular: View, Ultra: View>: View {
    @Environment(\.watchScreenSize) private var screenSize
    let small: () -> Small
    let regular: () -> Regular
    let ultra: () -> Ultra

    var body: some View {
        switch screenSize {
        case .small:
            small()
        case .regular:
            regular()
        case .ultra:
            ultra()
        }
    }
}

private struct WatchAdaptivePaddingModifier: ViewModifier {
    @Environment(\.watchScreenSize) private var screenSize

    func body(content: Content) -> some View {
        content.padding(WatchUIConfig(for: screenSize).standardPadding)
    }
}

private struct WatchAdaptiveFontModifier: ViewModifier {
    @Environment(\.watchScreenSize) private var screenSize
    let style: WatchFontStyle

    func body(content: Content) -> some View {
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
        return content.font(.system(size: fontSize))
    }
}

// MARK: - View Extensions for Easy Access
extension View {
    func watchScreenSize(_ size: WatchScreenSize) -> some View {
        environment(\.watchScreenSize, size)
    }

    func adaptiveForWatch<Small: View, Regular: View, Ultra: View>(
        small: @escaping () -> Small,
        regular: @escaping () -> Regular,
        ultra: @escaping () -> Ultra
    ) -> some View {
        AdaptiveForWatchContainer(small: small, regular: regular, ultra: ultra)
    }

    func watchAdaptivePadding() -> some View {
        modifier(WatchAdaptivePaddingModifier())
    }

    func watchAdaptiveFont(style: WatchFontStyle) -> some View {
        modifier(WatchAdaptiveFontModifier(style: style))
    }
}

enum WatchFontStyle {
    case title, body, caption
} 