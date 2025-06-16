// WatchGlobalUIConfig.swift
// PlungePalz Watch App
//
// Global adaptive UI constants for all screens, organized by screen

import SwiftUI

struct WatchGlobalUIConfig {
    
    
    // MARK: - HomeScreen
    struct HomeScreen {

        // Container Height Ratios
        static func topContainerHeightRatio(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0.3
            case .regular: return 0.3
            case .ultra: return 0.3
            }
        }
        static func middleBlueContainerHeightRatio(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0.4
            case .regular: return 0.4
            case .ultra: return 0.4
            }
        }
        static func bottomContainerHeightRatio(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0.3
            case .regular: return 0.3
            case .ultra: return 0.3
            }
        }

        // Top Container Assets
        static func connectionStatusIconSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 20
            case .regular: return 28
            case .ultra: return 32
            }
        }

        // Middle Container Assets
        static func chevronPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 4
            case .regular: return 8
            case .ultra: return 12
            }
        }

        static func plungeButtonCornerRadius(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 10
            case .regular: return 14
            case .ultra: return 18
            }
        }

        static func plungeButtonHorizontalPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 18
            case .regular: return 18
            case .ultra: return 20
            }
        }

        static func plungeButtonVerticalPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 10
            case .regular: return 10
            case .ultra: return 10
            }
        }

        // Bottom Container Assets
        static func bottomLogoSpacing(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0
            case .regular: return 8
            case .ultra: return 12
            }
        }

        static func bottomContainerLogoSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 36
            case .regular: return 36
            case .ultra: return 46
            }
        }

        static func bottomContainerLogoSpacing(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 4
            case .regular: return 8
            case .ultra: return 12
            }
        }

        static func bottomContainerAssetPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0
            case .regular: return 8
            case .ultra: return 12
            }
        }
    }




    // Add more nested structs for other screens as needed...
} 