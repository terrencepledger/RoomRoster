#if canImport(UIKit)
import SwiftUI
import UniformTypeIdentifiers

struct DocumentPickerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    var allowedTypes: [UTType]
    @Binding var url: URL?

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        init(parent: DocumentPickerView) { self.parent = parent }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.url = urls.first
            parent.presentationMode.wrappedValue.dismiss()
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes, asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}

struct PDFPickerButton: View {
    @Binding var url: URL?
    @State private var showPicker = false
    var label: String = "Select PDF"

    var body: some View {
        Button {
            showPicker = true
        } label: {
            if let url {
                Label(url.lastPathComponent, systemImage: "doc")
            } else {
                Label(label, systemImage: "doc")
            }
        }
        .sheet(isPresented: $showPicker) {
            DocumentPickerView(allowedTypes: [.pdf], url: $url)
        }
    }
}
#endif
