import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

private typealias l10n = Strings.sellItem

struct SellItemView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: SellItemViewModel
    var onComplete: (Result<Item, Error>) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(l10n.priceSection) {
                    TextField(l10n.price, value: $viewModel.sale.price, format: .number)
#if canImport(UIKit)
                        .keyboardType(.decimalPad)
#endif
                    Picker(l10n.condition, selection: $viewModel.sale.condition) {
                        ForEach(Condition.allCases, id: \.self) { condition in
                            Text(condition.label).tag(condition)
                        }
                    }
                    DatePicker(l10n.date, selection: $viewModel.sale.date, displayedComponents: .date)
                }
                Section(l10n.buyerSection) {
                    TextField(l10n.buyerName, text: $viewModel.sale.buyerName)
                    TextField(l10n.buyerContact, text: Binding(
                        get: { viewModel.sale.buyerContact ?? "" },
                        set: { viewModel.sale.buyerContact = $0.isEmpty ? nil : $0 }
                    ))
                }
                Section(l10n.sellerSection) {
                    TextField(l10n.soldBy, text: $viewModel.sale.soldBy)
                    TextField(l10n.department, text: $viewModel.sale.department)
                }
                Button(Strings.general.save) {
                    Task {
                        do {
                            let item = try await viewModel.submitSale()
                            onComplete(.success(item))
                            HapticManager.shared.success()
                            dismiss()
                        } catch {
                            Logger.log(error, extra: ["description": "Failed to record sale"])
                            onComplete(.failure(error))
                            HapticManager.shared.error()
                        }
                    }
                }
                .disabled(viewModel.isSubmitting)
                .platformButtonStyle()
            }
            .navigationTitle(l10n.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.general.cancel) { dismiss() }
                }
            }
        }
    }
}

