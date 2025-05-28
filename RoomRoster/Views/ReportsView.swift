//
//  ReportsView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 5/27/25.
//

import SwiftUI

private typealias l10n = Strings.reports

struct ReportsView: View {
    var body: some View {
        Text(l10n.comingSoon)
            .font(.title)
            .foregroundColor(.secondary)
            .navigationTitle(l10n.title)
            .onAppear {
                Logger.page("ReportsView")
            }
    }
}
