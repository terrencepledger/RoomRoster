import Foundation

enum Condition: String, CaseIterable, Codable {
    case new = "New"
    case good = "Good"
    case damaged = "Damaged"
    case outdated = "Outdated"

    var label: String { rawValue }
}
