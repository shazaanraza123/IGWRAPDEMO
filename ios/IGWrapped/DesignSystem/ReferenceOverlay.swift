import SwiftUI

#if DEBUG
/// Lays a reference screenshot over a screen at 50% so alignment can be checked.
struct ReferenceOverlay: View {
    var image: Image
    var opacity: Double = 0.5

    var body: some View {
        image
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .opacity(opacity)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
#endif

extension View {
    @ViewBuilder
    func referenceOverlay(image: Image?, opacity: Double = 0.5) -> some View {
        #if DEBUG
        overlay {
            if let image, !Pitch.active {
                ReferenceOverlay(image: image, opacity: opacity)
            }
        }
        #else
        self
        #endif
    }
}
