import SwiftUI
import UIKit

struct IGStoryViewer: View {
    var story: FriendStory
    var zoom: Namespace.ID
    var onClose: () -> Void
    var onUnavailable: () -> Void

    @State private var resting = false
    @State private var drag: CGFloat = 0
    @State private var nameWidth: CGFloat = 0

    var body: some View {
        ZStack {
            storyImage
                .allowsHitTesting(false)
                .accessibilityIdentifier("story-viewer")
                .accessibilityLabel("\(story.handle) story")
            StoryPanCatcher(
                onChange: { drag = $0 },
                onEnd: { travel, velocity in
                    if travel > IGSpace.viewerDismissTravel || velocity > IGSpace.viewerDismissVelocity {
                        onClose()
                    } else {
                        withAnimation(.easeOut(duration: IGSpace.viewerOpen)) {
                            drag = 0
                        }
                    }
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            chrome
                .zIndex(1)
        }
        .scaleEffect(dragScale, anchor: .center)
        .offset(y: drag)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .matchedGeometryEffect(id: story.handle, in: zoom)
        .onAppear {
            withAnimation(.easeOut(duration: IGSpace.viewerOpen)) {
                resting = true
            }
        }
    }

    private var storyImage: some View {
        photo
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .background(WrappedColor.igBackground)
    }

    private var photo: Image {
        guard let url = Bundle.main.url(forResource: story.photo, withExtension: "jpg"),
              let image = UIImage(contentsOfFile: url.path) else {
            return Image(systemName: "photo")
        }
        return Image(uiImage: image)
    }

    private var chrome: some View {
        ZStack {
            Capsule()
                .fill(WrappedColor.igWhite)
                .frame(height: IGSpace.viewerProgressHeight)
                .padding(.horizontal, IGSpace.viewerProgressInset)
                .padding(.top, IGSpace.viewerProgressTop)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .accessibilityHidden(true)
            header
            replyField
            replyIcons
        }
    }

    private var header: some View {
        ZStack {
            Text(story.handle)
                .font(WrappedTextStyle.igUsername.font)
                .foregroundStyle(WrappedColor.igWhite)
                .lineLimit(1)
                .background {
                    GeometryReader { proxy in
                        Color.clear.preference(key: NameWidthKey.self, value: proxy.size.width)
                    }
                }
                .offset(x: nameShift)
            PersonAvatar(handle: story.handle, photo: PersonAvatar.photoName(for: story.handle))
                .frame(width: IGSpace.postAvatar, height: IGSpace.postAvatar)
                .overlay {
                    Circle().stroke(WrappedColor.igWhite, lineWidth: IGSpace.viewerReplyStroke)
                }
                .offset(x: -(WrappedSpace.frameWidth / 2) + IGSpace.postInset + IGSpace.postAvatar / 2)
            chromeButton("ellipsis", label: "More", action: onUnavailable)
                .offset(x: WrappedSpace.frameWidth / 2 - IGSpace.postInset - IGSpace.iconHit * 1.5)
            chromeButton("xmark", label: "Close", identifier: "story-close", action: onClose)
                .offset(x: WrappedSpace.frameWidth / 2 - IGSpace.postInset - IGSpace.iconHit / 2)
        }
        .frame(height: IGSpace.iconHit)
        .padding(.top, IGSpace.viewerProgressTop + IGSpace.viewerProgressHeight + IGSpace.viewerHeaderGap)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onPreferenceChange(NameWidthKey.self) { nameWidth = $0 }
    }

    private var nameShift: CGFloat {
        guard nameWidth > 0 else { return 0 }
        let left = IGSpace.postInset + IGSpace.postAvatar + IGSpace.postInset
        return left + nameWidth / 2 - WrappedSpace.frameWidth / 2
    }

    private var replyField: some View {
        ZStack {
            Capsule().fill(WrappedColor.igBackground.opacity(0.45))
            Capsule().stroke(WrappedColor.igWhite.opacity(0.45), lineWidth: IGSpace.viewerReplyStroke)
            Text("Send message...")
                .font(WrappedTextStyle.igMeta.font)
                .foregroundStyle(WrappedColor.igIcon)
                .lineLimit(1)
                .offset(x: -(IGSpace.viewerReplyIcon + IGSpace.postInset))
        }
        .frame(height: IGSpace.iconHit)
        .padding(.leading, IGSpace.postInset)
        .padding(.trailing, IGSpace.viewerReplyIcon * 3 + IGSpace.postInset * 2)
        .padding(.bottom, IGSpace.viewerReplyBottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .onTapGesture(perform: onUnavailable)
        .accessibilityLabel("Send message")
    }

    private var replyIcons: some View {
        ZStack {
            chromeButton("heart", label: "Like", size: IGSpace.viewerReplyIcon, action: onUnavailable)
                .offset(x: WrappedSpace.frameWidth / 2 - IGSpace.postInset - IGSpace.viewerReplyIcon * 2.5)
            chromeButton("bubble.right", label: "Comment", size: IGSpace.viewerReplyIcon, action: onUnavailable)
                .offset(x: WrappedSpace.frameWidth / 2 - IGSpace.postInset - IGSpace.viewerReplyIcon * 1.5)
            chromeButton("paperplane", label: "Send", size: IGSpace.viewerReplyIcon, action: onUnavailable)
                .offset(x: WrappedSpace.frameWidth / 2 - IGSpace.postInset - IGSpace.viewerReplyIcon / 2)
        }
        .frame(height: IGSpace.iconHit)
        .padding(.bottom, IGSpace.viewerReplyBottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private func chromeButton(
        _ symbol: String,
        label: String,
        identifier: String? = nil,
        size: CGFloat = IGSpace.iconHit,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(IGFont.icon)
                .foregroundStyle(WrappedColor.igWhite)
                .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .modifier(StoryControlIdentifier(identifier: identifier))
    }

    private var dragScale: CGFloat {
        let progress = min(drag / IGSpace.viewerDismissTravel, 1)
        return 1 - progress * (1 - IGSpace.viewerDismissScale)
    }

    private var cornerRadius: CGFloat {
        let settled: CGFloat = resting ? 0 : IGSpace.viewerCardRadius
        let pulled = min(max(drag, 0) / IGSpace.viewerDismissTravel, 1) * IGSpace.viewerCardRadius
        return max(settled, pulled)
    }
}

private struct StoryPanCatcher: UIViewRepresentable {
    var onChange: (CGFloat) -> Void
    var onEnd: (CGFloat, CGFloat) -> Void

    func makeUIView(context: Context) -> PanSurface {
        let view = PanSurface()
        view.backgroundColor = .clear
        view.isOpaque = false
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.pan(_:)))
        view.addGestureRecognizer(pan)
        return view
    }

    func updateUIView(_ uiView: PanSurface, context: Context) {
        context.coordinator.onChange = onChange
        context.coordinator.onEnd = onEnd
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: PanSurface, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? WrappedSpace.frameWidth, height: proposal.height ?? WrappedSpace.frameHeight)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onChange: onChange, onEnd: onEnd)
    }

    @MainActor
    final class Coordinator: NSObject {
        var onChange: (CGFloat) -> Void
        var onEnd: (CGFloat, CGFloat) -> Void

        init(onChange: @escaping (CGFloat) -> Void, onEnd: @escaping (CGFloat, CGFloat) -> Void) {
            self.onChange = onChange
            self.onEnd = onEnd
        }

        @objc func pan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: nil)
            let velocity = gesture.velocity(in: nil)
            guard translation.y > 0, translation.y > abs(translation.x) else {
                if gesture.state == .ended || gesture.state == .cancelled {
                    onEnd(0, 0)
                }
                return
            }
            if gesture.state == .changed, translation.y >= IGSpace.viewerDragMinimum {
                onChange(translation.y)
            } else if gesture.state == .ended || gesture.state == .cancelled {
                onEnd(translation.y, velocity.y)
            }
        }
    }
}

private final class PanSurface: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let header = IGSpace.viewerProgressTop + IGSpace.viewerProgressHeight + IGSpace.viewerHeaderGap + IGSpace.iconHit
        let replyTop = bounds.height - IGSpace.viewerReplyBottom - IGSpace.iconHit
        if point.y < header || point.y > replyTop {
            return nil
        }
        return super.hitTest(point, with: event)
    }
}

private struct NameWidthKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct StoryControlIdentifier: ViewModifier {
    var identifier: String?

    func body(content: Content) -> some View {
        if let identifier {
            content.accessibilityIdentifier(identifier)
        } else {
            content
        }
    }
}
