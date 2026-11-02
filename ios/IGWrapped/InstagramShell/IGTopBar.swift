import PDFKit
import SwiftUI
import UIKit

struct IGTopBar: View {
    var onCreate: () -> Void
    var onActivity: () -> Void

    var body: some View {
        ZStack {
            IGWordmark()
                .position(
                    x: WrappedSpace.frameWidth / 2,
                    y: IGSpace.wordmarkTop + IGSpace.wordmarkHeight / 2
                )
            chromeButton("plus", label: "Create", showsBadge: false, action: onCreate)
                .position(x: IGSpace.plusCenterX, y: IGSpace.iconCenterY)
            chromeButton("heart", label: "Activity", showsBadge: true, action: onActivity)
                .position(x: IGSpace.heartCenterX, y: IGSpace.iconCenterY)
        }
        .frame(width: WrappedSpace.frameWidth, height: IGSpace.topBarHeight)
        .background(WrappedColor.igBackground)
    }

    private func chromeButton(
        _ symbol: String,
        label: String,
        showsBadge: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: symbol == "plus" ? IGSpace.plusIcon : IGSpace.chromeIcon, weight: .regular))
                .foregroundStyle(WrappedColor.igWhite)
                .overlay(alignment: .topTrailing) {
                    if showsBadge {
                        Circle()
                            .fill(WrappedColor.likeRed)
                            .frame(width: IGSpace.unreadDot, height: IGSpace.unreadDot)
                            .offset(x: -4, y: 3)
                    }
                }
                .frame(width: IGSpace.iconHit, height: IGSpace.iconHit)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct IGWordmark: View {
    var body: some View {
        Group {
            if let image = Self.asset {
                Image(uiImage: image.withRenderingMode(.alwaysTemplate))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(WrappedColor.igWhite)
            }
        }
        .frame(height: IGSpace.wordmarkHeight)
        .accessibilityHidden(true)
    }

    /// ImageIO cannot decode this PDF. PDFKit rasterizes it, and the tint uses that alpha.
    private static var asset: UIImage? {
        guard let url = Bundle.main.url(forResource: "instagram-wordmark", withExtension: "pdf"),
              let page = PDFDocument(url: url)?.page(at: 0) else { return nil }
        let bounds = page.bounds(for: .mediaBox)
        let scale: CGFloat = 3
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: bounds.width * scale, height: bounds.height * scale),
            format: format
        )
        return renderer.image { ctx in
            let context = ctx.cgContext
            context.translateBy(x: 0, y: bounds.height * scale)
            context.scaleBy(x: scale, y: -scale)
            page.draw(with: .mediaBox, to: context)
        }
    }
}
