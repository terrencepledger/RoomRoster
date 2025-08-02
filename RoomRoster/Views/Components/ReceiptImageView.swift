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
                    Image(systemName: "xmark.octagon")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .foregroundColor(.red.opacity(0.8))
                default:
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
        } else if let urlString, !urlString.isEmpty {
            Label("View Receipt", systemImage: "doc")
                .foregroundColor(.blue)
        } else {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(height: 120)
                .foregroundColor(.secondary.opacity(0.5))
        }
    }
}
