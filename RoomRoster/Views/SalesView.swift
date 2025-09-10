import SwiftUI

private typealias l10n = Strings.sales

struct SalesView: View {
    @EnvironmentObject private var coordinator: MainMenuCoordinator
    @StateObject private var viewModel = SalesViewModel()
    @StateObject private var sheets = SpreadsheetManager.shared
    @StateObject private var auth = AuthenticationManager.shared
#if os(macOS)
    @Binding var selectedSaleIndex: Int?
#endif
    @State private var selectedSale: Sale?
#if os(macOS)
    @State private var editingSale: Sale?
#endif
    @State private var successMessage: String?

    @State private var searchText: String = ""
    @State private var dateRange: ClosedRange<Date>?
    @State private var minPrice: Double?
    @State private var maxPrice: Double?

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
                if let sale = editingSale {
                    EditSaleView(
                        viewModel: EditSaleViewModel(sale: sale)
                    ) { updated in
                        selectedSale = updated
                        editingSale = nil
                        successMessage = Strings.saleDetails.editSuccess
                        HapticManager.shared.success()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            withAnimation { successMessage = nil }
                        }
                    }
                } else if let sale = selectedSale {
                    SalesDetailsView(
                        sale: sale,
                        itemName: viewModel.itemName(for: sale),
                        openEdit: { editingSale = $0 }
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
        if let message = successMessage {
            SuccessBanner(message: message)
                .allowsHitTesting(false)
                .padding()
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
            updateSelection()
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
            updateSelection()
#else
            if let pending = coordinator.pendingSale,
               let match = viewModel.sales.firstIndex(of: pending) {
                selectedSale = viewModel.sales[match]
                coordinator.pendingSale = nil
            }
#endif
        }
        .onAppear { Logger.page("SalesView") }
        .onChange(of: coordinator.pendingSale) { newValue in
            if let pending = newValue,
               let match = viewModel.sales.firstIndex(of: pending) {
                selectedSale = viewModel.sales[match]
                coordinator.pendingSale = nil
            }
        }
        .onChange(of: auth.isSignedIn) { signedIn in
            if signedIn, sheets.currentSheet != nil {
                Task {
                    await viewModel.loadSales()
                }
            }
        }
        .onChange(of: sheets.currentSheet?.id) { sheetID in
            if sheetID != nil, auth.isSignedIn {
                Task {
                    await viewModel.loadSales()
                }
            }
        }
#if os(macOS)
        .onChange(of: searchText) { _ in updateSelection() }
        .onChange(of: dateRange) { _ in updateSelection() }
        .onChange(of: minPrice) { _ in updateSelection() }
        .onChange(of: maxPrice) { _ in updateSelection() }
#endif
    }

#if os(macOS)
    private var selectionBinding: Binding<Sale?>? {
        Binding(
            get: { selectedSale },
            set: { newValue in
                selectedSale = newValue
                if let value = newValue,
                   let idx = filteredSales.firstIndex(of: value) {
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
            Section {
                listContent
            } header: {
                filterHeader
            }
        }
        .listStyle(.inset)
#else
        List {
            Section {
                listContent
            } header: {
                filterHeader
            }
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
        } else if filteredSales.isEmpty {
            Text("No results")
                .foregroundColor(.secondary)
        } else {
            ForEach(Array(filteredSales.enumerated()), id: \.offset) { i, sale in
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
                )
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
#endif
            }
        }
    }

    @ViewBuilder
    private var filterHeader: some View {
        VStack {
            HStack {
                TextField("Search", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                Button("Clear") { clearFilters() }
            }
            DatePicker(
                "Date Range",
                selection: Binding<ClosedRange<Date>>(
                    get: { dateRange ?? Date.distantPast...Date.distantFuture },
                    set: { dateRange = $0 }
                ),
                in: Date.distantPast...Date.distantFuture,
                displayedComponents: .date
            )
            HStack {
                TextField(
                    "Min Price",
                    value: Binding(get: { minPrice ?? 0 }, set: { minPrice = $0 }),
                    format: .number
                )
                TextField(
                    "Max Price",
                    value: Binding(get: { maxPrice ?? 0 }, set: { maxPrice = $0 }),
                    format: .number
                )
            }
        }
    }

    private var filteredSales: [Sale] {
        viewModel.filteredSales(
            query: searchText,
            dateRange: dateRange,
            minPrice: minPrice,
            maxPrice: maxPrice
        )
    }

#if os(macOS)
    private func updateSelection() {
        if let idx = selectedSaleIndex, idx < filteredSales.count {
            selectedSale = filteredSales[idx]
        } else {
            selectedSale = nil
            selectedSaleIndex = nil
        }
    }
#endif

    private func clearFilters() {
        searchText = ""
        dateRange = nil
        minPrice = nil
        maxPrice = nil
    }
}
