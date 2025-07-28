//
//  SettingsView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 5/27/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

private typealias l10n = Strings.settings

struct SettingsView: View {
    @StateObject private var auth = AuthenticationManager.shared
    @StateObject private var sheets = SpreadsheetManager.shared
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        Form {
            Section(l10n.accountSection) {
                if auth.isSignedIn {
                    Button(l10n.signOutButton) {
                        auth.signOut()
                        sheets.signOut()
                        HapticManager.shared.success()
                    }
                    .platformButtonStyle()
                } else {
                    Button(l10n.signInButton) {
                        Task {
                            await auth.signIn()
                            HapticManager.shared.success()
                        }
                    }
                    .platformButtonStyle()
                }
            }

            Section(l10n.appSettingsSection) {
                Toggle(l10n.darkModeToggle, isOn: $isDarkMode)
                    .onChange(of: isDarkMode) { _, _ in
                        HapticManager.shared.impact()
                    }
                Toggle(l10n.hapticsToggle, isOn: $hapticsEnabled)
                    .onChange(of: hapticsEnabled) { _, _ in
                        HapticManager.shared.impact()
                    }
            }

            Section(l10n.aboutSection) {
                HStack {
                    Text(l10n.versionLabel)
                    Spacer()
                    Text(versionString)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(l10n.title)
        .onAppear { Logger.page("SettingsView") }
    }
}
