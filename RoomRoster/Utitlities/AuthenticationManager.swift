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
    
    @Published var isSignedIn: Bool = false
    @Published var accessToken: String?
    @Published var userName: String?
    
    private init() { }
    
    func signIn() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller found"])
        }
        
        let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController, hint: nil, additionalScopes: [
            "https://www.googleapis.com/auth/spreadsheets"
        ])
        
        let token = signInResult.user.accessToken.tokenString
        self.accessToken = token
        self.isSignedIn = true
        self.userName = signInResult.user.profile?.name
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        self.accessToken = nil
        self.isSignedIn = false
    }
}
