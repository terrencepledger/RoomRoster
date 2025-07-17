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

    var body: some View {
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
        .navigationTitle(l10n.title)
        .onAppear {
            Logger.page("SheetsView")
            Task { await manager.loadSheets() }
        }
    }
}
