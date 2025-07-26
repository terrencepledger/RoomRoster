import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

final class HapticManager {
    static let shared = HapticManager()
    @AppStorage("hapticsEnabled") private var enabled: Bool = true

    func impact() {
        guard enabled else { return }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    func success() {
        guard enabled else { return }
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    func error() {
        guard enabled else { return }
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }
}
