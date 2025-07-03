//
//  SheetsUtils.swift
//  RoomRoster
//
//  Created by Terrence - Personal on 5/15/25.
//


//  SheetsUtils.swift
//  RoomRoster

import Foundation

enum SheetsUtils {
    /// Converts a 1-based column index into A1 notation (e.g., 1 -> A, 27 -> AA).
    static func columnName(for index: Int) -> String {
        var result = ""
        var number = index
        while number > 0 {
            let remainder = (number - 1) % 26
            result = String(UnicodeScalar(65 + remainder)!) + result
            number = (number - 1) / 26
        }
        return result
    }

    /// Finds the row index of a given identifier within a response's first column
    static func rowIndex(for id: String, in rows: [[String]]) -> Int? {
        return rows.firstIndex(where: { $0.first == id })
    }
} 
