import SwiftUI

private typealias l10n = Strings.sales

struct SalesView: View {
    @StateObject private var viewModel = SalesViewModel()
    @StateObject private var sheets = SpreadsheetManager.shared
#if os(macOS)
    @Binding var selectedSaleIndex: Int?
    @State private var selectedSale: Sale?
#endif

#if os(macOS)
    init(selectedSaleIndex: Binding<Int?>) {
        self._selectedSaleIndex = selectedSaleIndex
        self._selectedSale = State(initialValue: nil)
    }
#else
    init() {}
#endif

    var body: some View {
        Group {
#if os(macOS)
            NavigationSplitView {
                listPane
            } detail: {
                if let sale = selectedSale {
                    SalesDetailsView(
                        sale: sale,
                        itemName: viewModel.itemName(for: sale)
                    )
                    .id(sale.itemId + sale.date.toShortString())
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
#if os(macOS)
            if let idx = selectedSaleIndex,
               idx < viewModel.sales.count {
                selectedSale = viewModel.sales[idx]
            }
#endif
        }
        .refreshable {
            guard sheets.currentSheet != nil else { return }
            await viewModel.loadSales()
#if os(macOS)
            if let idx = selectedSaleIndex,
               idx < viewModel.sales.count {
                selectedSale = viewModel.sales[idx]
            }
#endif
        }
        .onAppear { Logger.page("SalesView") }
    }

#if os(macOS)
    private var selectionBinding: Binding<Sale?>? {
        Binding(
            get: { selectedSale },
            set: { newValue in
                selectedSale = newValue
                if let value = newValue,
                   let idx = viewModel.sales.firstIndex(of: value) {
                    selectedSaleIndex = idx
                } else {
                    selectedSaleIndex = nil
                }
            }
        )
    }
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
                    .tag(sale)
                    .contentShape(Rectangle())
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
#if os(macOS)
        .listStyle(.inset)
#endif
    }
}
