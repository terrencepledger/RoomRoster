import SwiftUI

private typealias l10n = Strings.sales

struct SalesView: View {
    var body: some View {
        Text(l10n.comingSoon)
            .font(.title)
            .foregroundColor(.secondary)
            .navigationTitle(l10n.title)
            .onAppear { Logger.page("SalesView") }
    }
}
