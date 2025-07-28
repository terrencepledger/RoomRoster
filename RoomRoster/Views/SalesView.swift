import SwiftUI

private typealias l10n = Strings.sales

struct SalesView: View {
    @StateObject private var viewModel = SalesViewModel()
    @StateObject private var sheets = SpreadsheetManager.shared
#if os(macOS)
    @State private var selectedSale: Sale?
#endif

    var body: some View {
        Group {
#if os(macOS)
            NavigationSplitView {
                listPane
            } detail: {
                if let sale = selectedSale {
                    SalesDetailsView(sale: sale, itemName: viewModel.itemName(for: sale))
                } else {
                    Text(l10n.selectSalePrompt)
                        .foregroundColor(.secondary)
                }
            }
#else
            NavigationView {
                listPane
            }
#endif
        }
        .navigationTitle(l10n.title)
        .task {
            guard sheets.currentSheet != nil else { return }
            await viewModel.loadSales()
        }
        .refreshable {
            guard sheets.currentSheet != nil else { return }
            await viewModel.loadSales()
        }
        .onAppear { Logger.page("SalesView") }
    }

#if os(macOS)
    private var selectionBinding: Binding<Sale?>? { $selectedSale }
#else
    private var selectionBinding: Binding<Sale?>? { nil }
#endif

    @ViewBuilder
    private var listPane: some View {
        List(selection: selectionBinding) {
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
            }

            if sheets.currentSheet == nil {
                Text(Strings.inventory.selectSheetPrompt)
                    .foregroundColor(.secondary)
            } else if viewModel.sales.isEmpty {
                Text(l10n.emptyState)
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(viewModel.sales.enumerated()), id: \.offset) { i, sale in
#if os(macOS)
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .tag(sale)
                    .onTapGesture { HapticManager.shared.impact() }
#else
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        TapGesture().onEnded { HapticManager.shared.impact() }
                    )
#endif
                }
            }
        }
    }
}
