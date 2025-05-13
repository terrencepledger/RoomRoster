//
//  AppLogger.swift
//  RoomRoster
//
//  Created by Terrence on 5/11/25.
//

import Sentry

enum LogLevel {
    case info, warning, error

    var sentryLevel: SentryLevel {
        switch self {
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        }
    }
}

enum LogCategory: String {
    case navigation, action, network, auth
}

struct Logger {
    static func initialize() {
        SentrySDK.start { options in
            options.dsn = "https://d2cb98bf29f371b5ef1db80869e2cd37@o4509301971550208.ingest.us.sentry.io/4509301976006656"
            options.enableAutoSessionTracking = true
        }

        Task {
            if let user = await AuthenticationManager.shared.userName, let email = await AuthenticationManager.shared.email {
                let userId = user.lowercased().replacingOccurrences(of: " ", with: "")
                self.setUser(id: userId, email: email)
            }
        }
    }

    private static func setUser(id: String?, email: String? = nil) {
        if let id = id {
            let user = User(userId: id)
            user.email = email
            SentrySDK.setUser(user)
        } else {
            SentrySDK.setUser(nil)
        }
    }

    static func page(_ name: String) {
        breadcrumb("Navigated to \(name)", category: .navigation)
    }

    static func action(_ name: String) {
        breadcrumb("Action: \(name)", category: .action)
    }

    static func network(_ name: String) {
        breadcrumb("Network: \(name)", category: .action)
    }

    private static func breadcrumb(_ message: String, category: LogCategory, level: LogLevel = .info) {
        let crumb = Breadcrumb(level: level.sentryLevel, category: category.rawValue)
        crumb.message = message
        SentrySDK.addBreadcrumb(crumb)
    }

    static func log(
        _ error: Error,
        level: LogLevel = .error,
        tags: [String: String]? = nil,
        extra: [String: Any]? = nil
    ) {
        SentrySDK.capture(error: error) { scope in
            scope.setLevel(level.sentryLevel)
            tags?.forEach { scope.setTag(value: $0.value, key: $0.key) }
            extra?.forEach { scope.setExtra(value: $0.value, key: $0.key) }
        }
    }
}
