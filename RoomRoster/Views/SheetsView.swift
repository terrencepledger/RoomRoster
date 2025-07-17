//
//  SheetsView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 5/27/25.
//

import SwiftUI

private typealias l10n = Strings.sheets

struct SheetsView: View {
    @StateObject private var manager = SpreadsheetManager.shared
    @StateObject private var auth = AuthenticationManager.shared

    var body: some View {
        Group {
            if auth.isSignedIn {
                List {
                    ForEach(manager.spreadsheets) { sheet in
                        HStack {
                            Text(sheet.name)
                            Spacer()
                            if sheet.id == manager.currentSheet?.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { manager.select(sheet) }
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Text(l10n.signInPrompt)
                    Button(l10n.signInButton) {
                        Task { await auth.signIn() }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(l10n.title)
        .onAppear {
            Logger.page("SheetsView")
            Task { await manager.loadSheets() }
        }
    }
}
