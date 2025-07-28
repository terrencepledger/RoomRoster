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

    /// Presents the given content using a style appropriate for the platform.
    func platformPopup<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
#if os(macOS)
        self.sheet(isPresented: isPresented, content: content)
#else
        self.sheet(isPresented: isPresented, content: content)
            .presentationDetents([.medium, .large])
#endif
    }
}
