//
//  MainMenuView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 5/27/25.
//

import SwiftUI

private typealias l10n = Strings.mainMenu

/// Tabs used across the main menu on all platforms.
enum MenuTab: Int, CaseIterable, Identifiable {
    case inventory, sales, reports, sheets, settings
    var id: Int { rawValue }

    var label: String {
        switch self {
        case .inventory: return l10n.inventory
        case .sales:     return l10n.sales
        case .reports:   return l10n.reports
        case .sheets:    return l10n.sheets
        case .settings:  return l10n.settings
        }
    }

    var icon: String {
        switch self {
        case .inventory: return "archivebox"
        case .sales:     return "dollarsign"
        case .reports:   return "chart.bar"
        case .sheets:    return "tablecells"
        case .settings:  return "gearshape"
        }
    }
}

struct MainMenuView: View {
    @EnvironmentObject private var coordinator: MainMenuCoordinator
    @StateObject private var auth = AuthenticationManager.shared
#if os(macOS)
    @State private var selectedItemID: String?
    @State private var selectedSaleIndex: Int?
#endif
#if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
#endif

    private var useSplitView: Bool {
#if os(macOS)
        return true
#else
        horizontalSizeClass == .regular
#endif
    }

    @ViewBuilder
    private var menuList: some View {
#if os(macOS)
        List(MenuTab.allCases, selection: $coordinator.selectedTab) { tab in
            Label(tab.label, systemImage: tab.icon)
                .tag(tab)
        }
#else
        List(MenuTab.allCases) { tab in
            Label(tab.label, systemImage: tab.icon)
                .tag(tab)
        }
#endif
    }

    var body: some View {
        Group {
            if useSplitView {
                NavigationSplitView {
                    menuList
                        .navigationTitle("Menu")
                } detail: {
                    detailView(for: coordinator.selectedTab)
                }
            } else {
                TabView(selection: $coordinator.selectedTab) {
                    tabContent(for: .inventory)
                        .tag(MenuTab.inventory)

                    tabContent(for: .sales)
                        .tag(MenuTab.sales)

                    tabContent(for: .reports)
                        .tag(MenuTab.reports)

                    tabContent(for: .sheets)
                        .tag(MenuTab.sheets)

                    tabContent(for: .settings)
                        .tag(MenuTab.settings)
                }
            }
        }
        .onChange(of: coordinator.selectedTab) { _, _ in
            HapticManager.shared.impact()
        }
        .onChange(of: auth.isSignedIn) { _, signedIn in
            if signedIn {
                Task {
                    await SpreadsheetManager.shared.loadSheets()
                    let manager = SpreadsheetManager.shared
                    if manager.spreadsheets.count == 1 && manager.currentSheet == nil {
                        if let sheet = manager.spreadsheets.first {
                            manager.select(sheet)
                            coordinator.selectedTab = .inventory
                        }
                    } else if manager.currentSheet == nil {
                        coordinator.selectedTab = .sheets
                    } else {
                        coordinator.selectedTab = .inventory
                    }
                }
            } else {
                SpreadsheetManager.shared.signOut()
            }
        }
        .task {
            await auth.signIn()
        }
    }

    @ViewBuilder
    private func tabContent(for tab: MenuTab) -> some View {
        detailView(for: tab)
            .tabItem { Label(tab.label, systemImage: tab.icon) }
    }

    @ViewBuilder
    private func detailView(for tab: MenuTab) -> some View {
        switch tab {
#if os(macOS)
        case .inventory: InventoryView(selectedItemID: $selectedItemID)
        case .sales:     SalesView(selectedSaleIndex: $selectedSaleIndex)
#else
        case .inventory: InventoryView()
        case .sales:     SalesView()
#endif
        case .reports:   ReportsView()
        case .sheets:    SheetsView()
        case .settings:  SettingsView()
        }
    }
}
