import SwiftUI
import UIKit

struct IGFeedPost: View {
    @State private var liked = false
    @State private var burst = false

    var body: some View {
        VStack(alignment: .leading, spacing: IGSpace.storyLabelGap) {
            HStack(spacing: IGSpace.postInset) {
                Circle()
                    .fill(WrappedColor.storyRing)
                    .frame(width: IGSpace.postAvatar, height: IGSpace.postAvatar)
                VStack(alignment: .leading, spacing: WrappedSpace.gridGap) {
                    Text("jules.mp")
                        .wrappedType(.igUsername)
                        .foregroundStyle(WrappedColor.igWhite)
                    Text("Chicago, Illinois")
                        .wrappedType(.igMeta)
                        .foregroundStyle(WrappedColor.igIcon)
                }
                Spacer()
                Image(systemName: "ellipsis")
                    .font(IGFont.icon)
                    .foregroundStyle(WrappedColor.igWhite)
            }
            .padding(.horizontal, IGSpace.postInset)
            media
            HStack(spacing: IGSpace.postInset) {
                Image(systemName: liked ? "heart.fill" : "heart")
                    .foregroundStyle(liked ? WrappedColor.likeRed : WrappedColor.igWhite)
                Image(systemName: "bubble.right")
                Image(systemName: "arrow.triangle.2.circlepath")
                Image(systemName: "paperplane")
                Spacer()
                Image(systemName: "bookmark")
            }
            .font(IGFont.icon)
            .foregroundStyle(WrappedColor.igWhite)
            .padding(.horizontal, IGSpace.postInset)
        }
        .padding(.top, IGSpace.postTopGap)
    }

    private var media: some View {
        feedImage
            .resizable()
            .scaledToFill()
            .frame(width: WrappedSpace.frameWidth, height: WrappedSpace.frameWidth / IGSpace.postAspect)
            .clipped()
            .overlay {
                Image(systemName: "heart.fill")
                    .font(IGFont.iconSelected)
                    .foregroundStyle(WrappedColor.igWhite)
                    .scaleEffect(burst ? 1 : 0.4)
                    .opacity(burst ? 1 : 0)
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                liked = true
                burst = true
                Task {
                    try? await Task.sleep(for: .milliseconds(700))
                    burst = false
                }
            }
            .accessibilityLabel("Photo by jules.mp")
    }

    private var feedImage: Image {
        guard let url = Bundle.main.url(forResource: "feed-chicago", withExtension: "jpg"),
              let image = UIImage(contentsOfFile: url.path) else {
            return Image(systemName: "photo")
        }
        return Image(uiImage: image)
    }
}
