//
//  SettingsView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 5/27/25.
//

import SwiftUI

private typealias l10n = Strings.settings

struct SettingsView: View {
    @StateObject private var auth = AuthenticationManager.shared
    @StateObject private var sheets = SpreadsheetManager.shared

    var body: some View {
        Form {
            Section(l10n.accountSection) {
                if auth.isSignedIn {
                    Button(l10n.signOutButton) {
                        auth.signOut()
                        sheets.signOut()
                    }
                } else {
                    Button(l10n.signInButton) {
                        Task { await auth.signIn() }
                    }
                }
            }
        }
        .navigationTitle(l10n.title)
        .onAppear { Logger.page("SettingsView") }
    }
}
