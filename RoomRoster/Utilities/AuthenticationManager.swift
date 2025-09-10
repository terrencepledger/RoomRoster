//
//  AuthenticationManager.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 3/22/25.
//

import Foundation
import GoogleSignIn
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()

    @Published private(set) var isSignedIn: Bool = false
    @Published private(set) var isSigningIn: Bool = false
    @Published private(set) var accessToken: String?
    @Published private(set) var userName: String?
    @Published private(set) var email: String?
    @Published var signInError: String?

    private init() {
        if let user = GIDSignIn.sharedInstance.currentUser {
            updateUser(from: user)
        }
    }

    func signIn() async {
        guard isSigningIn == false else { return }
        isSigningIn = true
        defer { isSigningIn = false }

        guard isSignedIn == false else { return }

        if await signInSilently() { return }

        do {
            try await triggerSignIn()
        } catch {
            Logger.log(error, extra: ["description": "Failed signing in"])
            signInError = error.localizedDescription
        }
    }

    func ensureSignedIn() async {
        await signIn()
    }

    private func signInSilently() async -> Bool {
        if let user = GIDSignIn.sharedInstance.currentUser {
            updateUser(from: user)
            await SpreadsheetManager.shared.loadSheets()
            return true
        }

        do {
            let restored = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            updateUser(from: restored)
            await SpreadsheetManager.shared.loadSheets()
            return true
        } catch {
            return false
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        self.accessToken = nil
        self.userName = nil
        self.isSignedIn = false
        self.signInError = nil
    }

    private func updateUser(from user: GIDGoogleUser) {
        self.accessToken = user.accessToken.tokenString
        self.userName = user.profile?.name
        self.email = user.profile?.email
        self.isSignedIn = true
        self.signInError = nil
    }

    private func triggerSignIn() async throws {
        #if canImport(UIKit)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else {
            throw NSError(
                domain: "Auth",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No root view controller found"]
            )
        }

        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: rootVC,
            hint: nil,
            additionalScopes: [
                "https://www.googleapis.com/auth/spreadsheets",
                "https://www.googleapis.com/auth/drive.readonly",
                "https://www.googleapis.com/auth/gmail.send",
            ]
        )

        let user = result.user
        updateUser(from: user)
        await SpreadsheetManager.shared.loadSheets()
        #elseif canImport(AppKit)
        var window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first { $0.isVisible }
        if window == nil {
            NSApp.activate(ignoringOtherApps: true)
            try await Task.sleep(nanoseconds: 500_000_000)
            window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first { $0.isVisible }
        }
        guard let presenting = window else {
            throw NSError(
                domain: "Auth",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No active window found"]
            )
        }

        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: presenting,
            hint: nil,
            additionalScopes: [
                "https://www.googleapis.com/auth/spreadsheets",
                "https://www.googleapis.com/auth/drive.readonly",
                "https://www.googleapis.com/auth/gmail.send",
            ]
        )

        updateUser(from: result.user)
        await SpreadsheetManager.shared.loadSheets()
        #else
        throw NSError(
            domain: "Auth",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Google sign-in not supported"]
        )
        #endif
    }
}
