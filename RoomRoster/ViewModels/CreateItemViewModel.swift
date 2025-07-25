//
//  CreateItemViewModel.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 6/4/25.
//

import SwiftUI
import Combine
import Foundation

private typealias l10n = Strings.createItem

@MainActor
final class CreateItemViewModel: ObservableObject {
    private let inventoryService: InventoryService
    private let roomService: RoomService
    private let imageUploadService: ImageUploadService
    private let receiptService: PurchaseReceiptService
    private let itemsProvider: () -> [Item]

    @Published var newItem: Item
    @Published var pickedImage: PlatformImage?
    @Published var pickedReceiptImage: PlatformImage?
    @Published var pickedReceiptPDF: URL?
    @Published var isUploading: Bool = false
    @Published var isUploadingReceipt: Bool = false
    @Published var uploadError: String?
    @Published var receiptUploadError: String?
    @Published var tagError: String?
    @Published var showTagError: Bool = false
    @Published var propertyTagInput: String = ""
    @Published var showingAddRoomPrompt: Bool = false
    @Published var newRoomName: String = ""
    @Published var rooms: [Room] = []
    @Published var errorMessage: String?
    
    var onSave: ((Item) -> Void)?

    init(
        inventoryService: InventoryService,
        roomService: RoomService,
        imageUploadService: ImageUploadService = .init(),
        receiptService: PurchaseReceiptService = .init(),
        itemsProvider: @escaping () -> [Item],
        onSave: ((Item) -> Void)? = nil
    ) {
        self.inventoryService = inventoryService
        self.roomService = roomService
        self.imageUploadService = imageUploadService
        self.receiptService = receiptService
        self.itemsProvider = itemsProvider
        self.onSave = onSave

        self.newItem = Item(
            id: UUID().uuidString,
            imageURL: "",
            name: "",
            description: "",
            quantity: 1,
            dateAdded: Date().toShortString(),
            estimatedPrice: nil,
            status: .available,
            lastKnownRoom: .placeholder(),
            updatedBy: "",
            lastUpdated: nil,
            propertyTag: nil,
            purchaseReceiptURL: nil
        )
    }

    func loadRooms() async {
        do {
            rooms = try await roomService.fetchRooms()
        } catch {
            errorMessage = l10n.errors.loadRoomsFailed
            HapticManager.shared.error()
        }
    }

    func onImagePicked(_ image: PlatformImage?) {
        pickedImage = image
        guard let image else { return }
        Task { await uploadPickedImage(image) }
    }

    func onReceiptPicked(_ image: PlatformImage?) {
        pickedReceiptImage = image
        guard let image else { return }
        Task { await saveReceiptImage(image) }
    }

    func onReceiptPDFPicked(_ url: URL?) {
        pickedReceiptPDF = url
        guard let url else { return }
        Task { await saveReceiptPDF(from: url) }
    }

    private func uploadPickedImage(_ image: PlatformImage) async {
        isUploading = true
        uploadError = nil

        do {
            let url = try await imageUploadService.uploadImageAsync(
                image: image,
                forItemId: newItem.id
            )
            newItem.imageURL = url.absoluteString
        } catch {
            uploadError = Strings.createItem.errors.imageUpload(error.localizedDescription)
            HapticManager.shared.error()
        }
        isUploading = false
    }

    private func saveReceiptImage(_ image: PlatformImage) async {
        isUploadingReceipt = true
        receiptUploadError = nil

        do {
            let url = try await receiptService.uploadReceipt(image: image, for: newItem.id)
            newItem.purchaseReceiptURL = url.absoluteString
        } catch {
            receiptUploadError = error.localizedDescription
            HapticManager.shared.error()
        }
        isUploadingReceipt = false
    }

    private func saveReceiptPDF(from url: URL) async {
        isUploadingReceipt = true
        receiptUploadError = nil

        do {
            let data = try Data(contentsOf: url)
            let saved = try await receiptService.uploadReceiptPDF(data, for: newItem.id)
            newItem.purchaseReceiptURL = saved.absoluteString
        } catch {
            receiptUploadError = error.localizedDescription
            HapticManager.shared.error()
        }
        isUploadingReceipt = false
    }

    func validateTag() {
        do {
            let tag = try ItemValidator.validateTag(
                propertyTagInput,
                currentItemID: nil,
                allItems: itemsProvider()
            )
            newItem.propertyTag = tag
            tagError = nil
            showTagError = false
        } catch {
            switch error {
            case .invalidTagFormat:
                tagError = l10n.errors.tag.format
            case .duplicateTag:
                tagError = l10n.errors.tag.duplicate
            default:
                tagError = l10n.errors.tag.other
            }
            showTagError = true
            newItem.propertyTag = nil
        }
    }

    func addRoom() async {
        do {
            let newRoom = try await roomService.addRoom(name: newRoomName)
            newItem.lastKnownRoom = newRoom
            rooms.append(newRoom)
        } catch {
            newItem.lastKnownRoom = Room.placeholder()
            errorMessage = l10n.errors.addRoomFailed
            HapticManager.shared.error()
        }
        newRoomName = ""
        showingAddRoomPrompt = false
    }

    func saveItem() async {
        validateTag()
        guard tagError == nil else { return }
        do {
            try await inventoryService.createItem(newItem)
            onSave?(newItem)
        } catch {
            errorMessage = l10n.errors.saveFailed
            HapticManager.shared.error()
        }
    }

    func signIn() async {
        await AuthenticationManager.shared.signIn()
    }
}
