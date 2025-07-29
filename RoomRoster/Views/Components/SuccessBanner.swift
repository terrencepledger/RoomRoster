import SwiftUI

struct SuccessBanner: View {
    let message: String

    var body: some View {
        Banner(kind: .success, message: message)
    }
}
