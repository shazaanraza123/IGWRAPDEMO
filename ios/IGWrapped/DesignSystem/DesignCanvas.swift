import SwiftUI

/// Scales a 390×844 design to the device so card positions stay put on every iPhone.
struct DesignCanvas<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            let scale = min(
                proxy.size.width / WrappedSpace.frameWidth,
                proxy.size.height / WrappedSpace.frameHeight
            )
            content()
                .frame(width: WrappedSpace.frameWidth, height: WrappedSpace.frameHeight)
                .scaleEffect(scale, anchor: .top)
                .frame(
                    width: WrappedSpace.frameWidth * scale,
                    height: WrappedSpace.frameHeight * scale,
                    alignment: .top
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}
