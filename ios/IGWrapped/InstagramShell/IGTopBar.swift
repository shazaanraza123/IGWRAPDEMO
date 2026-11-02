import SwiftUI
import UIKit

struct IGTopBar: View {
    var onCreate: () -> Void
    var onActivity: () -> Void

    var body: some View {
        ZStack {
            IGWordmark()
                .position(x: WrappedSpace.frameWidth / 2, y: IGSpace.iconCenterY)
            chromeButton("plus", label: "Create", action: onCreate)
                .position(x: IGSpace.plusCenterX, y: IGSpace.iconCenterY)
            chromeButton("heart", label: "Activity", action: onActivity)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(WrappedColor.likeRed)
                        .frame(width: IGSpace.unreadDot, height: IGSpace.unreadDot)
                        .offset(x: -IGSpace.unreadDot, y: IGSpace.unreadDot)
                }
                .position(x: IGSpace.heartCenterX, y: IGSpace.iconCenterY)
        }
        .frame(width: WrappedSpace.frameWidth, height: IGSpace.topBarHeight)
        .background(WrappedColor.igBackground)
    }

    private func chromeButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(IGFont.icon)
                .foregroundStyle(WrappedColor.igWhite)
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
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.clear
            }
        }
        .frame(width: IGSpace.wordmarkWidth, height: IGSpace.wordmarkHeight)
        .accessibilityHidden(true)
    }

    private static var asset: UIImage? {
        UIImage(named: "Wordmark") ?? UIImage(named: "ig-wordmark")
    }
}
