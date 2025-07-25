#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(CoreGraphics)
import CoreGraphics
#endif

#if canImport(AppKit) || canImport(UIKit)
extension PlatformImage {
    func jpegDataCompatible(compressionQuality: CGFloat) -> Data? {
        #if canImport(UIKit)
        return self.jpegData(compressionQuality: compressionQuality)
        #elseif canImport(AppKit)
        guard let tiffData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
        #endif
    }
}
#endif

#if canImport(SwiftUI) && (canImport(AppKit) || canImport(UIKit))
extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: platformImage)
        #endif
    }
}
#endif
