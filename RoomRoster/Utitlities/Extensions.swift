//
//  Extensions.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 3/22/25.
//

import Foundation

extension Date {
    /// A shared DateFormatter configured to the "M/d/yyyy" format.
    static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy" // e.g., "2/1/2025"
        return formatter
    }()
    
    /// Returns the string representation of the date using the shortFormatter.
    func toShortString() -> String {
        return Date.shortFormatter.string(from: self)
    }
    
    /// Returns a Date parsed from a given short date string.
    static func fromShortString(_ dateString: String) -> Date? {
        return Date.shortFormatter.date(from: dateString)
    }
}
