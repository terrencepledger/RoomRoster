import SwiftUI

struct ReceiptsView: View {
    @StateObject var viewModel = ReceiptsViewModel()

    var body: some View {
        List(viewModel.receipts) { receipt in
            HStack {
                Text(receipt.saleId)
                Spacer()
                Text(receipt.date, style: .date)
            }
        }
        .navigationTitle("Receipts")
        .task { await viewModel.loadReceipts() }
    }
}

struct ReceiptsView_Previews: PreviewProvider {
    static var previews: some View {
        ReceiptsView()
    }
}
