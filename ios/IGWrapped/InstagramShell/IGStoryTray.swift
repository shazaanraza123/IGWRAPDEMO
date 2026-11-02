import SwiftUI

struct FriendStory: Identifiable, Hashable {
    let handle: String
    /// Sample photo already in `design/photos`. Friend headshots are not in the repo.
    let photo: String

    var id: String { handle }

    static let samples: [FriendStory] = [
        FriendStory(handle: "dee.films", photo: "tile-1"),
        FriendStory(handle: "jules.mp", photo: "tile-2"),
        FriendStory(handle: "nico_k", photo: "tile-3"),
        FriendStory(handle: "sam.wav", photo: "tile-4"),
        FriendStory(handle: "tori.eats", photo: "tile-5")
    ]
}

struct IGStoryTray: View {
    var zoom: Namespace.ID
    var openHandle: String?
    var onWrapped: () -> Void
    var onFriend: (FriendStory) -> Void

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
                ForEach(FriendStory.samples) { story in
                    Button {
                        onFriend(story)
                    } label: {
                        storyBubble(title: story.handle, ring: .unseen) {
                            Circle().fill(WrappedColor.surfaceRaised)
                        } badge: {
                            EmptyView()
                        }
                    }
                    .buttonStyle(.plain)
                    .matchedGeometryEffect(id: story.handle, in: zoom, isSource: openHandle != story.handle)
                    .accessibilityIdentifier("story-\(story.handle)")
                }
            }
            .padding(.leading, IGSpace.storyLeading)
            .padding(.top, IGSpace.storyTopGap)
        }
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
