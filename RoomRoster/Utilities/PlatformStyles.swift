import SwiftUI

extension View {
    /// Applies a prominent button style tuned for the current platform.
    func platformButtonStyle() -> some View {
#if os(iOS)
        self.buttonStyle(.borderedProminent).controlSize(.large)
#else
        self.buttonStyle(.borderedProminent).controlSize(.regular)
#endif
    }
}
