//
//  ShareSheet.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 7/25/25.
//

import SwiftUI

#if canImport(UIKit)
import UIKit

/// A wrapper around ``UIActivityViewController`` for presenting the system share sheet on iOS and iPadOS.
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}
#else
/// ``ShareSheet`` is unavailable on platforms without UIKit. ``ShareLink`` can be used instead
/// where supported.
struct ShareSheet: View {
    let activityItems: [Any]

    var body: some View {
        if #available(macOS 13, *) {
            if let first = activityItems.first as? any Transferable {
                ShareLink(item: first)
            }
        }
    }
}
#endif
