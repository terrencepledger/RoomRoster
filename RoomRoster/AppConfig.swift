//
//  AppConfig.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 3/22/25.
//

import Foundation

struct AppConfig {
    static let shared = AppConfig()
    
    let sheetId: String
    let apiKey: String
    let sentryDSN: String?
    
    private init() {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            fatalError("Unable to load Secrets.plist")
        }
        
        guard let sheetId = plist["SheetID"] as? String,
              let apiKey = plist["GoogleSheetsAPIKey"] as? String else {
            fatalError("Missing keys in Secrets.plist")
        }

        self.sheetId = sheetId
        self.apiKey = apiKey
        self.sentryDSN = plist["SentryDSN"] as? String
    }
}
