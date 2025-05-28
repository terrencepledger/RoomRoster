//
//  ErrorBanner.swift
//  RoomRoster
//
//  Created by Terrence - Personal on 5/17/25.
//


import SwiftUI

struct ErrorBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.9))
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut, value: message)
    }
}
