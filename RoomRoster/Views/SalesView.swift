import SwiftUI

private typealias l10n = Strings.sales

struct SalesView: View {
    @EnvironmentObject private var coordinator: MainMenuCoordinator
    @StateObject private var viewModel = SalesViewModel()
    @StateObject private var sheets = SpreadsheetManager.shared
#if os(macOS)
    @Binding var selectedSaleIndex: Int?
#endif
    @State private var selectedSale: Sale?

#if os(macOS)
    init(selectedSaleIndex: Binding<Int?>) {
        self._selectedSaleIndex = selectedSaleIndex
        self._selectedSale = State(initialValue: nil)
    }
#else
    init() {
        self._selectedSale = State(initialValue: nil)
    }
#endif

    var body: some View {
        ZStack(alignment: .bottom) {
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
            NavigationStack {
                listPane
            }
#endif
        }
        if let error = viewModel.errorMessage {
            ErrorBanner(message: error)
                .allowsHitTesting(false)
                .padding()
        }
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
#else
            if let pending = coordinator.pendingSale,
               let match = viewModel.sales.firstIndex(of: pending) {
                selectedSale = viewModel.sales[match]
                coordinator.pendingSale = nil
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
#else
            if let pending = coordinator.pendingSale,
               let match = viewModel.sales.firstIndex(of: pending) {
                selectedSale = viewModel.sales[match]
                coordinator.pendingSale = nil
            }
#endif
        }
        .onAppear { Logger.page("SalesView") }
        .onChange(of: coordinator.pendingSale) { _, newValue in
            if let pending = newValue,
               let match = viewModel.sales.firstIndex(of: pending) {
                selectedSale = viewModel.sales[match]
                coordinator.pendingSale = nil
            }
        }
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
#if os(macOS)
        List(selection: selectionBinding) {
            listContent
        }
        .listStyle(.inset)
#else
        List {
            listContent
        }
#endif
    }

    @ViewBuilder
    private var listContent: some View {
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
                NavigationLink(
                    tag: sale,
                    selection: $selectedSale,
                    destination: {
                        SalesDetailsView(
                            sale: sale,
                            itemName: viewModel.itemName(for: sale)
                        )
                    },
                    label: {
                        HStack {
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
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
#endif
            }
        }
    }
}
