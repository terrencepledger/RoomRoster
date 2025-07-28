//
//  MainMenuView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 5/27/25.
//

import SwiftUI

private typealias l10n = Strings.mainMenu

/// Tabs used across the main menu on all platforms.
private enum MenuTab: Int, CaseIterable, Identifiable {
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
    @StateObject private var auth = AuthenticationManager.shared
    @State private var selectedTab: MenuTab = .inventory
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

    var body: some View {
        Group {
            if useSplitView {
                NavigationSplitView {
                    List(MenuTab.allCases, selection: $selectedTab) { tab in
                        Label(tab.label, systemImage: tab.icon)
                            .tag(tab)
                    }
                    .navigationTitle("Menu")
                } detail: {
                    detailView(for: selectedTab)
                }
            } else {
                TabView(selection: $selectedTab) {
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
        .onChange(of: selectedTab) { _, _ in
            HapticManager.shared.impact()
        }
        .onAppear {
            Task { await auth.signIn() }
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
