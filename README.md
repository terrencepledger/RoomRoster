# RoomRoster

RoomRoster is a SwiftUI-based inventory management application that integrates with Google Sheets as its backend data source. The app fetches inventory data from a Google Sheets spreadsheet, displays items in a list, and allows users to view detailed information and edit item details.

## Features

- **Inventory List:** Displays a list of inventory items with details such as name, status, and last known room.
- **Item Details:** Provides detailed information about an item, including an image, description, dates, estimated price, and a color-coded status.
- **History Logs:** Fetches and displays the history log for each item from a dedicated Google Sheets range.
- **Edit Functionality:** Allows users to edit item details via a dedicated editing view.
- **Sales Tracking:** Record item sales with buyer information and condition while emailing receipts.
- **Modern Concurrency:** Utilizes Swift's async/await for cleaner and more efficient asynchronous networking.
- **Clean Architecture:** Implements a clear separation of concerns with dedicated networking and service layers, view models, and SwiftUI views.

## Usage

- **View Inventory:** The app automatically fetches and displays inventory items from a configured Google Sheet.
- **Item Details:** Tap on any item in the list to view its detailed information, including a history log and color-coded status.
- **Edit Items:** Use the "Edit Item" button in the details view to modify item information. Changes are applied locally and can be extended to update remotely.
- **Sell Items:** From an item's details you can record a sale which updates the Google Sheet and emails a receipt.

## Configuration

The project requires private configuration that is not checked into source control:

- **Firebase** – Copy `RoomRoster/GoogleService-Info-Example.plist` to `RoomRoster/GoogleService-Info.plist` and populate it with the credentials for your Firebase project. The resulting file is ignored by Git.
- **Secrets** – Copy `RoomRoster/Secrets-Example.plist` to `RoomRoster/Secrets.plist` and provide the following value:
  - `SentryDSN` – *(Optional)* The DSN for Sentry crash reporting. If omitted, Sentry will not send events.

Google Sign‑In requests Drive, Sheets, and Gmail scopes so the app can list available spreadsheets, read and update them, and email sales receipts.

When users sign in, the app lists any spreadsheets shared with them that contain tabs named **Inventory**, **HistoryLog**, **Rooms**, and **Sales**. Selecting one of these sheets sets it as the active inventory.

## Backend Sheets

The app expects a "Sales" sheet alongside the existing "Inventory" and "HistoryLog" sheets. Each sale row should contain the item ID, sale date, price, condition, buyer name and contact, and the seller and department.

## Email Receipts

Sales receipts are emailed using the Gmail API. The app generates a simple PDF receipt and attaches it to the email.
