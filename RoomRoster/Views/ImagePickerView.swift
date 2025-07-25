//
//  ImagePickerView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 4/16/25.
//

import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

private typealias l10n = Strings.imagePicker

// UIKit-based picker for iPhone and iPad only. Not available on Mac Catalyst.
#if canImport(UIKit) && !targetEnvironment(macCatalyst)
struct UIKitImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var image: PlatformImage?
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
    @Binding var image: PlatformImage?
    @State private var showSourceDialog = false
    @State private var showPicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary

    var body: some View {
        Button {
            Logger.action("Selected Image Picker")
            showSourceDialog = true
        } label: {
            if let img = image {
                Image(platformImage: img)
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
#else
/// macOS or Mac Catalyst version using `PhotosPicker` since `UIImagePickerController`
/// isn't available.
struct CombinedImagePickerButton: View {
    @Binding var image: PlatformImage?
    @State private var selection: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selection, matching: .images) {
            if let img = image {
                Image(platformImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .cornerRadius(8)
            } else {
                Label(l10n.title, systemImage: "photo.on.rectangle")
            }
        }
        .onChange(of: selection) { newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let platform = PlatformImage(data: data) {
                    image = platform
                }
            }
        }
    }
}
#endif
