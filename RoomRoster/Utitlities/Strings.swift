//
//  Strings.swift
//  RoomRoster
//
//  Created by Terrence - Personal on 5/27/25.
//

import Foundation

struct Strings {
    // MARK: - General
    struct general {
        static let save = "Save"
        static let cancel = "Cancel"
    }

    // MARK: - MainMenu
    struct mainMenu {
        static let inventory = "Inventory"
        static let reports = "Reports"
        static let sheets = "Sheets"
        static let settings = "Settings"
    }

    // MARK: - InventoryView
    struct inventory {
        static let title = "Inventory"
        static let searchPlaceholder = "Search..."
        static let includeHistoryToggle = "Include History"
        static let addItemButton = "Add Item"
        static func status(_ status: String) -> String {
            "Status: \(status)"
        }
        static func tag(_ tag: String) -> String {
            "Tag: \(tag)"
        }
        static func matchedLabel(_ context: String) -> String {
            "Matched in: \(context)"
        }
        static let failedToSave = "Failed to save item. Please try again."
        struct query {
            static let name = "name"
            static let description = "description"
            static let tag = "property tag"
            static let status = "status"
            static let updatedBy = "updated by"
            static let dateAdded = "date added"
            static func historyField(_ field: String) -> String {
                "history (\(field))"
            }
            static let history = "history"
        }
    }

    // MARK: - CreateItemView
    struct createItem {
        static let title = "Create Item"
        static let uploadingImage = "Uploading Image…"
        static let imageURL = "Image URL"
        static let photo = "Photo"
        struct basicInfo {
            static let title = "Basic Information"
            static let name = "Name"
            static let description = "Description"
            static let quantity = "Quantity"
            static let tag = "Property Tag"
            struct enter {
                static let name = "Enter Name"
                static let description = "Enter Description"
                static let quantity = "Enter Quantity"
                static let tag = "Enter Property Tag"
            }
        }
        struct details {
            static let title = "Details"
            static let price = "Estimated Price"
            static let status = "Status"
            struct room {
                static let title = "Last Known Room"
                static let add = "Add Room…"
            }
            struct enter {
                static let price = "Enter price"
                static let status = "Status"
                static let room = "Select a Room"
            }
        }
        struct addRoom {
            static let title = "Add New Room"
            static let placeholder = "Room Name"
            static let button = "Add"
        }
        struct errors {
            struct tag {
                static let format = "Invalid tag format. Use formatting like A1234."
                static let duplicate = "That tag already exists."
            }
            static func imageUpload(_ error: String) -> String {
                "Upload failed: \(error)"
            }
        }
    }

    // MARK: - ItemDetailsView
    struct itemDetails {
        static let title = "Item Details"
        static let quantity = "Quantity:"
        static let tag = "Property Tag:"
        static let dateAdded = "Date Added:"
        static let priceTitle = "Estimated Price:"
        static let status = "Status:"
        static let room = "Last Known Room:"
        static func dateUpdated(_ date: String) -> String {
            "Last Updated: \(date)"
        }
        struct logs {
            static let title = "History Log"
            static let loading = "Loading history…"
            static let emptyState = "No history available"
            static func row(_ log: String) -> String {
                "* \(log)"
            }
        }
        static let editItem = "Edit Item"
        static let failedToUpdate = "Failed to update item. Please try again."
    }

    // MARK: - EditItemView
    struct editItem {
        static let title = "Edit Item"
        struct photo {
            static let title = "Photo"
            static let emptyState = "No Photo"
            static let enter = "Select or Take Photo"
            static let loading = "Uploading Image…"
        }
        struct basicInfo {
            static let title = "Basic Information"
            static let name = "Name"
            static let description = "Description"
            static let quantity = "Quantity"
            static let tag = "Property Tag"
            struct enter {
                static let name = "Enter Name"
                static let description = "Enter Description"
                static let quantity = "Enter Quantity"
                static let tag = "Enter Property Tag"
            }
        }
        struct details {
            static let title = "Details"
            static let price = "Estimated Price"
            static let status = "Status"
            struct room {
                static let title = "Last Known Room"
                static let subtitle = "Room"
                static let add = "Add Room…"
                static let loading = "Loading Rooms..."
            }
            struct enter {
                static let price = "Enter price"
                static let status = "Status"
                static let room = "Select a Room"
            }
        }
        struct addRoomAlert {
            static let title = "Add New Room"
            static let placeholder = "Room Name"
            static let add = "Add"
        }
        struct errors {
            struct tag {
                static let format = "Invalid tag format. Use formatting like A1234."
                static let duplicate = "That tag already exists."
            }
            static func imageUpload(_ error: String) -> String {
                "Upload failed: \(error)"
            }
        }
    }

    // MARK: - ImagePickerView
    struct imagePicker {
        static let title = "Choose or Take Photo"
        struct dialog {
            static let title = "Select Photo Source"
            static let capture = "Select Photo Source"
            static let library = "Photo Library"
        }
    }

    // MARK: - SettingsView
    struct settings {
        static let title = "Settings"
        static let comingSoon = "Settings - Coming Soon"
//        static let accountSection       = "Account"
//        static let signOutButton        = "Sign Out"
//        static let appSettingsSection   = "App Settings"
//        static let darkModeToggle       = "Dark Mode"
//        static let aboutSection         = "About"
//        static let versionLabel         = "Version"
//        static let feedbackButton       = "Send Feedback"
    }

    // MARK: - ReportsView
    struct reports {
        static let title = "Reports"
        static let comingSoon = "Reports - Coming Soon"
    }

    // MARK: - SheetsView
    struct sheets {
        static let title = "Sheets"
        static let comingSoon = "Sheets - Coming Soon"
    }
}
