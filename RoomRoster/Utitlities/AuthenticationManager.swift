//
//  AuthenticationManager.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 3/22/25.
//

import Foundation
import GoogleSignIn
import UIKit

@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()

    @Published private(set) var isSignedIn: Bool = false
    @Published private(set) var accessToken: String?
    @Published private(set) var userName: String?
    @Published private(set) var email: String?

    private init() {
        if let user = GIDSignIn.sharedInstance.currentUser {
            self.isSignedIn = true
            self.accessToken = user.accessToken.tokenString
            self.userName = user.profile?.name
        }
    }

    func signIn() async {
        if let user = GIDSignIn.sharedInstance.currentUser {
            self.isSignedIn = true
            self.accessToken = user.accessToken.tokenString
            self.userName = user.profile?.name
            return
        }
        do {
            try await triggerSignIn()
        } catch {
            Logger.log(error, extra: [
                "description": "Failed signing in"
            ])
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        self.accessToken = nil
        self.userName = nil
        self.isSignedIn = false
    }

    private func triggerSignIn() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
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
            additionalScopes: ["https://www.googleapis.com/auth/spreadsheets"]
        )

        let user = result.user
        self.accessToken = user.accessToken.tokenString
        self.userName = user.profile?.name
        self.email = user.profile?.email
        self.isSignedIn = true
    }
}
