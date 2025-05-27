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
    var body: some Scene {
        WindowGroup {
            MainMenuView()
        }
    }
}
