# RoomRoster

RoomRoster is a SwiftUI-based inventory management application that integrates with Google Sheets as its backend data source. The app fetches inventory data from a Google Sheets spreadsheet, displays items in a list, and allows users to view detailed information and edit item details.

## Features

- **Inventory List:** Displays a list of inventory items with details such as name, status, and last known room.
- **Item Details:** Provides detailed information about an item, including an image, description, dates, estimated price, and a color-coded status.
- **History Logs:** Fetches and displays the history log for each item from a dedicated Google Sheets range.
- **Edit Functionality:** Allows users to edit item details via a dedicated editing view.
- **Modern Concurrency:** Utilizes Swift's async/await for cleaner and more efficient asynchronous networking.
- **Clean Architecture:** Implements a clear separation of concerns with dedicated networking and service layers, view models, and SwiftUI views.

## Usage

- **View Inventory:** The app automatically fetches and displays inventory items from a configured Google Sheet.
- **Item Details:** Tap on any item in the list to view its detailed information, including a history log and color-coded status.
- **Edit Items:** Use the "Edit Item" button in the details view to modify item information. Changes are applied locally and can be extended to update remotely.

## Configuration

The project requires private configuration that is not checked into source control:

- **Firebase** – Copy `RoomRoster/GoogleService-Info-Example.plist` to `RoomRoster/GoogleService-Info.plist` and populate it with the credentials for your Firebase project. The resulting file is ignored by Git.
- **Secrets** – Copy `RoomRoster/Secrets-Example.plist` to `RoomRoster/Secrets.plist` and provide the following values:
  - `SheetID` – The ID of the Google Sheet used by the app.
  - `GoogleSheetsAPIKey` – Your Google Sheets API key.
  - `SentryDSN` – *(Optional)* The DSN for Sentry crash reporting. If omitted, Sentry will not send events.
