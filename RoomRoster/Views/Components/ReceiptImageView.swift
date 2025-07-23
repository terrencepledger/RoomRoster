import SwiftUI

struct ReceiptImageView: View {
    var urlString: String?

    var body: some View {
        if let urlString,
           let url = URL(string: urlString),
           ["jpg", "jpeg", "png"].contains(url.pathExtension.lowercased()) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                         .scaledToFit()
                         .frame(height: 120)
                         .cornerRadius(8)
                case .failure:
                    Image(systemName: "xmark.octagon").foregroundColor(.red)
                default:
                    ProgressView().frame(height: 120)
                }
            }
        } else if let urlString, !urlString.isEmpty {
            Label("View Receipt", systemImage: "doc")
                .foregroundColor(.blue)
        } else {
            Text("No receipt")
                .foregroundColor(.gray)
        }
    }
}
