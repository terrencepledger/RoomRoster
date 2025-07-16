//
//  MainMenuView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 5/27/25.
//

import SwiftUI

private typealias l10n = Strings.mainMenu

struct MainMenuView: View {
    var body: some View {
        TabView {
            InventoryView()
                .tabItem {
                    Label(l10n.inventory, systemImage: "archivebox")
                }

            SalesView()
                .tabItem {
                    Label(Strings.sales.title, systemImage: "dollarsign")
                }

            ReportsView()
                .tabItem {
                    Label(l10n.reports, systemImage: "chart.bar")
                }

            SheetsView()
                .tabItem {
                    Label(l10n.sheets, systemImage: "tablecells")
                }

            SettingsView()
                .tabItem {
                    Label(l10n.settings, systemImage: "gearshape")
                }
        }
    }
}
