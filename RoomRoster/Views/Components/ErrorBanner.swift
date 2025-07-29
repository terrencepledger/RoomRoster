import SwiftUI

struct ErrorBanner: View {
    let message: String

    var body: some View {
        Banner(kind: .error, message: message)
    }
}
