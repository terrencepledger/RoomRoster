//
//  MainMenuView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 5/27/25.
//


import SwiftUI

struct MainMenuView: View {
    var body: some View {
        TabView {
            InventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "archivebox")
                }

            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "chart.bar")
                }

            SheetsView()
                .tabItem {
                    Label("Sheets", systemImage: "tablecells")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
