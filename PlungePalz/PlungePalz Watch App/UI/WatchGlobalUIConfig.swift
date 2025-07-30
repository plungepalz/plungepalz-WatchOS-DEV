// WatchGlobalUIConfig.swift
// PlungePalz Watch App
//
// Global adaptive UI constants for all screens, organized by screen

import SwiftUI

struct WatchGlobalUIConfig {

    // ==== 1A. HomeScreen ====
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

    // ==== 1B. PendingSaveSessionsScreen ====
    struct PendingSaveSessionsScreen {

        // Title UI
        static func titleTopPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return -15
            case .regular: return -20
            case .ultra: return -25
            }
        }

        static func titleBottomPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0
            case .regular: return 0
            case .ultra: return 0
            }
        }

        static func titleFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 16
            case .regular: return 18
            case .ultra: return 20
            }
        }

        // Option Container Width
        static func optionContainerTopPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 10
            case .regular: return 10
            case .ultra: return 12
            }
        }

        static func optionContainerWidthRatio(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0.9
            case .regular: return 0.9
            case .ultra: return 0.9
            }
        }

        // Option Container Height
        static func optionContainerHeightRatio(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0.1
            case .regular: return 0.1
            case .ultra: return 0.1
            }
        }

        // Option Container Assets
        static func optionIconSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 20
            case .regular: return 24
            case .ultra: return 28
            }
        }

        static func optionTitleFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 18
            case .regular: return 18
            case .ultra: return 20
            }
        }

        static func optionSubtitleFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 14
            case .regular: return 16
            case .ultra: return 18
            }
        }

        static func iconTitleGap(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 6
            case .regular: return 8
            case .ultra: return 8
            }
        }
    }
    
    // ==== 1C. SavingOrDeletingPendingActivities ====
    struct SavingOrDeletingPendingActivities {

        static func titleTopPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 5
            case .regular: return 15
            case .ultra: return 20
            }
        }

        static func titleFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 18
            case .regular: return 20
            case .ultra: return 22
            }
        }

        static func circleTopPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 10
            case .regular: return 10
            case .ultra: return 15
            }
        }

        static func circleSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 90
            case .regular: return 95
            case .ultra: return 100
            }
        }

        static func countdownFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 32
            case .regular: return 36
            case .ultra: return 40
            }
        }

        static func buttonTopPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 10
            case .regular: return 10
            case .ultra: return 20
            }
        }

        static func buttonFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 16
            case .regular: return 18
            case .ultra: return 20
            }
        }

        static func buttonWidth(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 90
            case .regular: return 120
            case .ultra: return 120
            }
        }

        static func buttonHeight(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 30
            case .regular: return 40
            case .ultra: return 40
            }
        }
    }

    // ==== 1D. GetReadyCountdownTimer ====
    struct GetReadyCountdownTimer {

        static func titleTopPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 5
            case .regular: return 15
            case .ultra: return 20
            }
        }

        static func titleFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 18
            case .regular: return 20
            case .ultra: return 22
            }
        }

        static func circleTopPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 10
            case .regular: return 10
            case .ultra: return 15
            }
        }

        static func circleSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 90
            case .regular: return 95
            case .ultra: return 100
            }
        }

        static func countdownFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 32
            case .regular: return 36
            case .ultra: return 40
            }
        }

        static func buttonTopPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 10
            case .regular: return 10
            case .ultra: return 20
            }
        }

        static func buttonFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 16
            case .regular: return 18
            case .ultra: return 20
            }
        }

        static func buttonWidth(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 90
            case .regular: return 120
            case .ultra: return 120
            }
        }

        static func buttonHeight(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 30
            case .regular: return 40
            case .ultra: return 40
            }
        }
    }

    // ==== 2. ConnectDeviceScreen ====
    struct ConnectDeviceScreen {

        // Ratio for Rectangular Progress Height and Width
        static func progressHeightRatio(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 1
            case .regular: return 0.97
            case .ultra: return 0.97
            }
        }

        static func progressWidthRatio(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 1
            case .regular: return 0.97
            case .ultra: return 0.97
            }
        }

        static func outerProgressContainerBorderRadius(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 20
            case .regular: return 20
            case .ultra: return 25
            }
        }

        static func innerProgressContainerBorderRadius(for size: WatchScreenSize) -> CGFloat {

            switch size {
            case .small: return 15
            case .regular: return 10
            case .ultra: return 17
            }
        }

        static func six_digit_font_size(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 25
            case .regular: return 30
            case .ultra: return 34
            }
        }

        static func status_text_font_size(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 16
            case .regular: return 18
            case .ultra: return 22
            }
        }

        // Skip Button Assets
        static func skipButtonTextPaddingHorizontal(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return -30
            case .regular: return -40
            case .ultra: return -50
            }
        }

        static func skipButtonTextPaddingVertical(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return -5
            case .regular: return -10
            case .ultra: return -10
            }
        }

        static func skipButtonFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 14
            case .regular: return 16
            case .ultra: return 20
            }
        }

        static func skipButtonTopPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 80
            case .regular: return 90
            case .ultra: return 100
            }
        }
        
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

        // Top Corner Padding for Stop Icon
        static func stopIconTopCornerPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 4
            case .regular: return 8
            case .ultra: return 8
            }
        }

        static func stopIconSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 28
            case .regular: return 34
            case .ultra: return 42
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

    // ==== 8. ActivityStoppedOrPausedScreen ====
    struct ActivityStoppedOrPausedScreen {

        // Option Container Width
        static func optionContainerTopPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return -15
            case .regular: return -15
            case .ultra: return -20
            }
        }

        static func optionContainerWidthRatio(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0.9
            case .regular: return 0.9
            case .ultra: return 0.9
            }
        }

        // Option Container Height
        static func optionContainerHeightRatio(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0.1
            case .regular: return 0.1
            case .ultra: return 0.1
            }
        }

        // Option Container Assets
        static func optionIconSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 20
            case .regular: return 24
            case .ultra: return 28
            }
        }

        static func optionTitleFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 18
            case .regular: return 18
            case .ultra: return 20
            }
        }

        static func optionSubtitleFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 14
            case .regular: return 16
            case .ultra: return 18
            }
        }   

        static func iconTitleGap(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 6
            case .regular: return 8
            case .ultra: return 8
            }
        }
    }


    // ==== 9A. SessionDeletedScreen ====
    struct SessionDeletedScreen {

        // Icon Size
        static func iconSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 40
            case .regular: return 40
            case .ultra: return 46
            }
        }

        // Title Font Size
        static func titleFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 18
            case .regular: return 22
            case .ultra: return 24
            }
        }

        // Button Assets
        static func buttonVerticalPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 8
            case .regular: return 10
            case .ultra: return 12
            }
        }

    
    }

    // ==== 9B. SessionRecapScreen ====
    struct SessionRecapScreen {
        // Option Container Width
        static func optionContainerTopPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return -15
            case .regular: return -15
            case .ultra: return -20
            }
        }

        static func optionContainerWidthRatio(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0.9
            case .regular: return 0.9
            case .ultra: return 0.9
            }
        }

        // Option Container Height
        static func optionContainerHeightRatio(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0.1
            case .regular: return 0.1
            case .ultra: return 0.1
            }
        }

        // Option Container Assets
        static func optionIconSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 20
            case .regular: return 24
            case .ultra: return 28
            }
        }

        static func optionTitleFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 14
            case .regular: return 18
            case .ultra: return 20
            }
        }

        static func optionSubtitleFontSize(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 14
            case .regular: return 16
            case .ultra: return 18
            }
        }   

        static func iconTitleGap(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 8
            case .regular: return 8
            case .ultra: return 8
            }
        }

        // Option Container Assets
        static func optionContainerHorizontalPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 4
            case .regular: return 8
            case .ultra: return 8
            }
        }

        static func optionContainerVerticalPadding(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 8
            case .regular: return 8
            case .ultra: return 8
            }
        }

        // Retrying Progress Bar Assets
        static func retryingProgressBarPaddingVerticalOffsetRatio(for size: WatchScreenSize) -> CGFloat {
            switch size {
            case .small: return 0.45
            case .regular: return 0.45
            case .ultra: return 0.45
            }
        }
    }




    // Add more nested structs for other screens as needed...
} 