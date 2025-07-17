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
        static let clear = "Clear"
        static let loading = "Loading..."
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
        static let includeSoldToggle = "Include Sold Items"
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
        static let failedToLoad = "Failed to load inventory. Please try again."
        static let failedToLoadRooms = "Failed to load rooms. Please try again."
        static let failedToAddRoom = "Failed to add room. Please try again."
        static let failedToLoadLogs = "Failed to load logs. Please try again."
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
                static let other = "Unknown tag error."
            }
            static func imageUpload(_ error: String) -> String {
                "Upload failed: \(error)"
            }
            static let saveFailed = "Failed to save item. Please try again."
            static let loadRoomsFailed = "Failed to load rooms. Please try again."
            static let addRoomFailed = "Failed to add room. Please try again."
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
        static let failedToLoadHistory = "Failed to load history. Please try again."
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
        static let accountSection = "Account"
        static let signInButton = "Sign In"
        static let signOutButton = "Sign Out"
//        static let appSettingsSection   = "App Settings"
//        static let darkModeToggle       = "Dark Mode"
//        static let aboutSection         = "About"
//        static let versionLabel         = "Version"
//        static let feedbackButton       = "Send Feedback"
    }

    // MARK: - ReportsView
    struct reports {
        static let title = "Reports"
        static let inventorySummary = "Inventory Summary"
        static let roomsSummary = "Items by Room"
        static let totalValue = "Total Estimated Value"
        static let recentActivity = "Recent Activity"
        static let exportCSV = "Export CSV"
        static let exportOverview = "Export Overview"
        static let exportSearch = "Export Search"
        static let searchPlaceholder = "Search items..."
        static let searchResults = "Results"
        static let clearSearch = "Clear"
        static let salesOverview = "Sales Overview"
        static let totalSold = "Total Sold"
        static let totalRevenue = "Total Revenue"
    }

    // MARK: - SheetsView
    struct sheets {
        static let title = "Sheets"
        static let comingSoon = "Sheets - Coming Soon"
        static let signInPrompt = "Sign in to view sheets"
        static let signInButton = "Sign In"
    }

    // MARK: - SalesView
    struct sales {
        static let title = "Sales"
        static let comingSoon = "Sales - Coming Soon"
        static let emptyState = "No sales recorded"
        static let failedToLoad = "Failed to load sales. Please try again."
    }

    // MARK: - SellItemView
    struct sellItem {
        static let title = "Sell Item"
        static let priceSection = "Sale Details"
        static let price = "Price"
        static let condition = "Condition"
        static let date = "Date"
        static let buyerSection = "Buyer"
        static let buyerName = "Name"
        static let buyerContact = "Contact"
        static let sellerSection = "Seller"
        static let soldBy = "Sold By"
        static let department = "Department"
        static let success = "Sale recorded successfully"
        static let failure = "Failed to record sale. Please try again."
    }

    // MARK: - SaleDetailsView
    struct saleDetails {
        static let title = "Sale Details"
        static let price = "Price:"
        static let condition = "Condition:"
        static let date = "Date:"
        static let buyerName = "Buyer:"
        static let buyerContact = "Contact:"
        static let soldBy = "Sold By:"
        static let department = "Department:"
    }
}
