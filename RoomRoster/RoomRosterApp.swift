//
//  RoomRosterApp.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 1/30/25.
//

import SwiftUI
import SwiftData
import Firebase

@main
struct RoomRosterApp: App {
    init() {
        FirebaseApp.configure()
        Logger.initialize()
    }
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var coordinator = MainMenuCoordinator()
    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .environmentObject(coordinator)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
