import SwiftUI

enum BannerKind {
    case error, success

    var icon: String {
        switch self {
        case .error:   return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .error:   return .red
        case .success: return .green
        }
    }
}

struct Banner: View {
    let kind: BannerKind
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: kind.icon)
                .imageScale(.medium)
            Text(message)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(kind.color.opacity(0.9))
        .foregroundColor(.white)
#if os(macOS)
        .cornerRadius(12)
#else
        .cornerRadius(8)
#endif
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeInOut, value: message)
    }
}

extension Banner {
    static func error(_ message: String) -> Banner {
        Banner(kind: .error, message: message)
    }
    static func success(_ message: String) -> Banner {
        Banner(kind: .success, message: message)
    }
}
