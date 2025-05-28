//
//  SettingsView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 5/27/25.
//

import SwiftUI

private typealias l10n = Strings.settings

struct SettingsView: View {
    var body: some View {
        Text(l10n.comingSoon)
            .font(.title)
            .foregroundColor(.secondary)
            .navigationTitle(l10n.title)
            .onAppear {
                Logger.page("SettingsView")
            }
    }
}
