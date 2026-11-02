import SwiftUI

struct IGStoryTray: View {
    var onWrapped: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: IGSpace.storyGap) {
                storyBubble(title: "Your story", ring: .seen) {
                    Circle().fill(WrappedColor.surfaceRaised)
                } badge: {
                    Circle()
                        .fill(WrappedColor.igWhite)
                        .frame(width: IGSpace.storyBadge, height: IGSpace.storyBadge)
                        .overlay {
                            Image(systemName: "plus")
                                .font(IGFont.badge)
                                .foregroundStyle(WrappedColor.igBackground)
                        }
                }
                Button(action: onWrapped) {
                    storyBubble(title: "Wrapped", ring: .unseen) {
                        ZStack {
                            Circle().fill(WrappedColor.igPink)
                            Text("26")
                                .wrappedType(.title)
                                .foregroundStyle(WrappedColor.igWhite)
                        }
                    } badge: {
                        EmptyView()
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("wrapped-bubble")
                ForEach(friendNames, id: \.self) { name in
                    storyBubble(title: name, ring: .unseen) {
                        Circle().fill(WrappedColor.surfaceRaised)
                    } badge: {
                        EmptyView()
                    }
                }
            }
            .padding(.leading, IGSpace.storyLeading)
            .padding(.top, IGSpace.storyTopGap)
        }
    }

    private var friendNames: [String] {
        ["dee.films", "jules.mp", "nico_k", "sam.wav", "tori.eats"]
    }

    private func storyBubble<Face: View, Badge: View>(
        title: String,
        ring: StoryRing,
        @ViewBuilder face: () -> Face,
        @ViewBuilder badge: () -> Badge
    ) -> some View {
        VStack(spacing: IGSpace.storyLabelGap) {
            ZStack {
                face()
                    .frame(
                        width: IGSpace.storyDiameter - IGSpace.ringStroke * 4,
                        height: IGSpace.storyDiameter - IGSpace.ringStroke * 4
                    )
                    .clipShape(Circle())
            }
            .frame(width: IGSpace.storyDiameter, height: IGSpace.storyDiameter)
            .overlay { ringStroke(ring) }
            .overlay(alignment: .bottomTrailing) { badge() }
            Text(title)
                .wrappedType(.igStoryName)
                .foregroundStyle(WrappedColor.igWhite)
                .lineLimit(1)
                .frame(width: IGSpace.storyDiameter)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private func ringStroke(_ ring: StoryRing) -> some View {
        switch ring {
        case .seen:
            Circle().stroke(WrappedColor.igRingSeen, lineWidth: IGSpace.ringStroke)
        case .unseen:
            Circle().stroke(WrappedColor.storyRing, lineWidth: IGSpace.ringStroke)
        }
    }
}

private enum StoryRing {
    case seen
    case unseen
}
