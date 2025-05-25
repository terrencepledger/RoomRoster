//
//  PropertyTag.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 5/24/25.
//

struct PropertyTag: RawRepresentable, Equatable, Hashable, Codable {
    let rawValue: String

    init?(rawValue: String) {
        let pattern = #"^[A-Z][0-9]{4}$"#
        guard rawValue.range(of: pattern, options: .regularExpression) != nil else {
            return nil
        }
        self.rawValue = rawValue
    }

    var label: String {
        rawValue
    }
}

extension PropertyTag {
    private init() {
        rawValue = "-1"
    }

    static func empty() -> PropertyTag {
        .init()
    }
}
