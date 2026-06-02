//
//  WatchHaptics.swift
//  PlungePalz Watch App
//

import WatchKit

enum WatchHaptics {
    static func playGetReadyComplete() {
        WKInterfaceDevice.current().play(.start)
    }
}
