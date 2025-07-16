//
//  SettingsView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 5/27/25.
//

import SwiftUI

private typealias l10n = Strings.settings

struct SettingsView: View {
    @StateObject private var manager = InventoryManager.shared
    @State private var sheetIdInput: String = ""
    @State private var apiKeyInput: String = ""
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section(l10n.currentInventory) {
                Text(manager.sheetId)
            }

            Section(l10n.changeInventory) {
                TextField(l10n.sheetIdField, text: $sheetIdInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField(l10n.apiKeyField, text: $apiKeyInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button(l10n.loadButton) {
                    Task {
                        do {
                            try await manager.switchInventory(sheetId: sheetIdInput, apiKey: apiKeyInput)
                            sheetIdInput = ""
                            apiKeyInput = ""
                            errorMessage = nil
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }

            if let message = errorMessage {
                Text(message)
                    .foregroundColor(.red)
            }
        }
        .navigationTitle(l10n.title)
        .onAppear {
            Logger.page("SettingsView")
        }
    }
}
