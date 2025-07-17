//
//  AppConfig.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 3/22/25.
//

import Foundation

struct AppConfig {
    static let shared = AppConfig()
    
    let sentryDSN: String?
    
    private init() {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            fatalError("Unable to load Secrets.plist")
        }
        
        self.sentryDSN = plist["SentryDSN"] as? String
    }
}
