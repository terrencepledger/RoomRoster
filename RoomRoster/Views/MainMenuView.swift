//
//  MainMenuView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 5/27/25.
//

import SwiftUI

private typealias l10n = Strings.mainMenu

struct MainMenuView: View {
    @StateObject private var auth = AuthenticationManager.shared
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            InventoryView()
                .tabItem {
                    Label(l10n.inventory, systemImage: "archivebox")
                }
                .tag(0)

            SalesView()
                .tabItem {
                    Label(Strings.sales.title, systemImage: "dollarsign")
                }
                .tag(1)

            ReportsView()
                .tabItem {
                    Label(l10n.reports, systemImage: "chart.bar")
                }
                .tag(2)

            SheetsView()
                .tabItem {
                    Label(l10n.sheets, systemImage: "tablecells")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label(l10n.settings, systemImage: "gearshape")
                }
                .tag(4)
        }
        .onChange(of: selectedTab) { _, _ in
            HapticManager.shared.impact()
        }
        .onAppear {
            Task {
                if !auth.isSignedIn {
                    await auth.signIn()
                }
            }
        }
    }
}
