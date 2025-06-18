// WatchGlobalUIConfig.swift
// PlungePalz Watch App
//
// Global adaptive UI constants for all screens, organized by screen

import SwiftUI

struct WatchGlobalUIConfig {
    
    
    // ==== 1. HomeScreen ====
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
            case .ultra: return 10
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

        static func middleContainerPaddingTrailing(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 10
            case .regular: return 20
            case .ultra: return 20
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

    // ==== 2. ConnectDeviceScreen ====
    struct ConnectDeviceScreen {
        
    }

    // ==== 3. SelectSessionScreen ====
    struct SelectSessionScreen {

        static func optionContainerHeightRatio(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0.3
            case .regular: return 0.3
            case .ultra: return 0.3
            }
        }

        static func optionContainerWidthRatio(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0.3
            case .regular: return 0.3
            case .ultra: return 0.3
            }
        }

        static func optionContainerTitleFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 16
            case .regular: return 18
            case .ultra: return 20
            }
        }

        static func optionContainerSubtitleFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 14
            case .regular: return 18
            case .ultra: return 20
            }
        }

        static func optionContainerPaddingHorizontal(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 6
            case .regular: return 6
            case .ultra: return 10
            }
        }
        
    }

    // ==== 4. SetTimerScreen ====
    struct SetTimerScreen {
        
        // Header Assets
        static func headerIconSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 20
            case .regular: return 24
            case .ultra: return 28
            }
        }
        static func headerTitleFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 16
            case .regular: return 18
            case .ultra: return 20
            }
        }

        // Time Values Assets
        static func valuesFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 20
            case .regular: return 22
            case .ultra: return 24
            }
        }

        static func labelFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 12
            case .regular: return 14
            case .ultra: return 14
            }
        }

        static func valuesContainerWidth(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 42
            case .regular: return 44
            case .ultra: return 46
            }
        }

        static func valuesContainerXOffest(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 15
            case .regular: return 20
            case .ultra: return 20
            }
        }

        static func valuesContainerGap(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0
            case .regular: return 0
            case .ultra: return 0
            }
        }

        static func labelWidth(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 32
            case .regular: return 32
            case .ultra: return 40
            }
        }

        static func buttonTopPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 6
            case .regular: return 12
            case .ultra: return 12
            }
        }

        static func buttonInternalTopPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 8
            case .regular: return 10
            case .ultra: return 11
            }
        }



    }

    // ==== 5. SetTemperatureScreen ====
    struct SetTemperatureScreen {
        
        // Header Assets
        static func headerIconSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 20
            case .regular: return 24
            case .ultra: return 28
            }
        }
        static func headerTitleFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 18
            case .regular: return 18
            case .ultra: return 20
            }
        }

        // Temperature Values Assets
        static func valuesFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 24
            case .regular: return 24
            case .ultra: return 24
            }
        }

        static func labelFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 14
            case .regular: return 14
            case .ultra: return 14
            }
        }

        static func valuesContainerWidthUnitAndDecimal(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 42
            case .regular: return 42
            case .ultra: return 46
            }
        }

        static func valuesContainerWidthWholeNumber(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 54
            case .regular: return 54
            case .ultra: return 56
            }
        }

        static func pickerContainerPaddingTrailing(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 4
            case .regular: return 4
            case .ultra: return 4
            }
        }

        static func valuesContainerGap(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 4
            case .regular: return 4
            case .ultra: return 0
            }
        }

        static func labelWidth(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 32
            case .regular: return 32
            case .ultra: return 40
            }
        }

        static func buttonTopPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 2
            case .regular: return 12
            case .ultra: return 12
            }
        }

        static func buttonInternalTopPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 8
            case .regular: return 10
            case .ultra: return 11
            }
        }

    }

    // ==== 6. CountdownActivatedScreen ====
    struct CountdownActivatedScreen {

        // Top Corner Padding for Lock Icon
        static func lockIconTopCornerPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 8
            case .regular: return 12
            case .ultra: return 14
            }
        }

        // Sectional Container Paddings
        static func topPaddingTimer(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 65
            case .regular: return 95
            case .ultra: return 115
            }
        }

        static func topPaddingTempText(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0
            case .regular: return -2
            case .ultra: return 0
            }
        }
        static func topPaddingForProgressContainer(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 26
            case .regular: return 32
            case .ultra: return 32
            }
        }

        static func timerFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 44
            case .regular: return 44
            case .ultra: return 50
            }
        }

        static func temperatureFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 22
            case .regular: return 22
            case .ultra: return 26
            }
        }

        static func temperatureIconSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 18
            case .regular: return 20
            case .ultra: return 24
            }
        }

        static func progressBarHeight(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 8
            case .regular: return 8
            case .ultra: return 8
            }
        }

        static func paddingBetweenHeartRateAndBarChart(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0
            case .regular: return 5
            case .ultra: return 5
            }
        }

        // Divider Line Padding Assets
        static func dividerLine1TopPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0
            case .regular: return -2
            case .ultra: return -5
            }
        }

        static func dividerLine1BottomPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0
            case .regular: return 5
            case .ultra: return 5
            }
        }

        static func dividerLine2TopPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0
            case .regular: return 0
            case .ultra: return 5
            }
        }

        static func dividerLine2BottomPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0
            case .regular: return 0
            case .ultra: return 0
            }
        }

        static func dividerLine3TopPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0
            case .regular: return 5
            case .ultra: return 5
            }
        }

        static func dividerLine3BottomPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0
            case .regular: return 5
            case .ultra: return 5
            }
        }
    }


    // Add more nested structs for other screens as needed...
} 