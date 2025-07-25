import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

final class HapticManager {
    static let shared = HapticManager()
    @AppStorage("hapticsEnabled") private var enabled: Bool = true

    func impact() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func error() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
