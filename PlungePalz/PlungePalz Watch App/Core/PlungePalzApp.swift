//
//  PlungePalzApp.swift
//  PlungePalz Watch App
//
//  Created by AJ Aviles on 6/4/25.
//

import SwiftUI

@main
struct PlungePalzApp: App {
    @StateObject var sessionDataManager = SessionDataManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionDataManager)
        }
    }
}
