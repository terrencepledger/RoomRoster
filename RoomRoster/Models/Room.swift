//
//  Room.swift
//  RoomRoster
//
//  Created by Terrence Pledger 5/24/25.
//

struct Room: Identifiable, Hashable, Codable, Equatable {
    var id: String { name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
    var name: String
    var label: String {
        name.capitalized
    }
}

extension Room {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Room, rhs: Room) -> Bool {
        lhs.id == rhs.id
    }

    static func empty() -> Room {
        .init()
    }
    
    static func placeholder() -> Room {
        Room(name: "__placeholder__")
    }

    private init() {
        name = "Null"
    }
}
