import SwiftUI

enum Status: String, CaseIterable, Codable {
    case available = "Available"
    case checkedOut = "Checked Out"
    case sold = "Sold"
    case discarded = "Discarded"

    var label: String {
        rawValue
    }

    var color: Color {
        switch self {
        case .available: return .green
        case .checkedOut: return .blue
        case .sold: return .gray
        case .discarded: return .red
        }
    }
}
