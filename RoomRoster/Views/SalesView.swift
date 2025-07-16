import SwiftUI

private typealias l10n = Strings.sales

struct SalesView: View {
    @StateObject private var viewModel = SalesViewModel()

    var body: some View {
        NavigationView {
            List {
                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error)
                }

                if viewModel.sales.isEmpty {
                    Text(l10n.emptyState)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(viewModel.sales.enumerated()), id: \.offset) { i, sale in
                        NavigationLink(destination: SalesDetailsView(sale: sale, itemName: viewModel.itemName(for: sale))) {
                            VStack(alignment: .leading) {
                                Text(viewModel.itemName(for: sale))
                                    .font(.headline)
                                HStack {
                                    Text(sale.date.toShortString())
                                    Spacer()
                                    if let price = sale.price {
                                        Text("$\(price, specifier: "%.2f")")
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(l10n.title)
        }
        .task { await viewModel.loadSales() }
        .refreshable { await viewModel.loadSales() }
        .onAppear { Logger.page("SalesView") }
    }
}
