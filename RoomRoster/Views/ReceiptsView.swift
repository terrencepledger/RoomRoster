import SwiftUI

struct ReceiptsView: View {
    @StateObject var viewModel = ReceiptsViewModel()

    var body: some View {
        List(viewModel.receipts) { receipt in
            HStack {
                Text(receipt.saleId)
                Spacer()
                Text(receipt.date.toShortString())
            }
        }
        .onAppear { viewModel.loadReceipts() }
        .navigationTitle("Receipts")
    }
}

struct ReceiptsView_Previews: PreviewProvider {
    static var previews: some View {
        ReceiptsView()
    }
}
