//
//  ImagePickerView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 4/16/25.
//

import SwiftUI
import PhotosUI

private typealias l10n = Strings.imagePicker

struct UIKitImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: UIKitImagePicker
        init(_ parent: UIKitImagePicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

struct CombinedImagePickerButton: View {
    @Binding var image: UIImage?
    @State private var showSourceDialog = false
    @State private var showPicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary

    var body: some View {
        Button {
            Logger.action("Selected Image Picker")
            showSourceDialog = true
        } label: {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .cornerRadius(8)
            } else {
                Label(l10n.title, systemImage: "photo.on.rectangle")
            }
        }
        .confirmationDialog(l10n.dialog.title, isPresented: $showSourceDialog) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(l10n.dialog.capture) {
                    sourceType = .camera
                    showPicker = true
                }
            }
            Button(l10n.dialog.library) {
                sourceType = .photoLibrary
                showPicker = true
            }
            Button(Strings.general.cancel, role: .cancel) {}
        }
        .sheet(isPresented: $showPicker) {
            UIKitImagePicker(image: $image, sourceType: sourceType)
        }
    }
}
