import SwiftUI

private typealias l10n = Strings.saleDetails

struct SalesDetailsView: View {
    let sale: Sale
    let itemName: String

    var body: some View {
        List {
            Section {
                row(l10n.date, sale.date.toShortString())
                if let price = sale.price {
                    row(l10n.price, "$\(price, specifier: \"%.2f\")")
                }
                row(l10n.condition, sale.condition.label)
                row(l10n.buyerName, sale.buyerName)
                row(l10n.buyerContact, sale.buyerContact)
                row(l10n.soldBy, sale.soldBy)
                row(l10n.department, sale.department)
            }
        }
        .navigationTitle(itemName)
    }

    @ViewBuilder
    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).bold()
            Spacer()
            Text(value)
        }
    }
}
