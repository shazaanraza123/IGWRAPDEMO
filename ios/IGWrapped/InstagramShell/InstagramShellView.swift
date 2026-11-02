import SwiftUI
import UIKit

struct InstagramShellView: View {
    @Namespace private var storyZoom
    @State private var tab = IGTab.home
    @State private var showsLogin = false
    @State private var showsBanner = !ProcessInfo.processInfo.arguments.contains("--reference")
    @State private var openStory: FriendStory?
    @State private var showsPlayer = false
    @State private var showsEntry = false
    @State private var toast: String?

    var body: some View {
        GeometryReader { geo in
            shell(in: geo.size)
                .frame(width: geo.size.width, height: geo.size.height)
                .overlay {
                    if let referenceImage {
                        referenceImage
                            .resizable()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .opacity(0.5)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
        }
        .ignoresSafeArea()
        .task {
            if ProcessInfo.processInfo.arguments.contains("--reset-session") {
                await SessionStore.shared.signOut()
                WrappedIntro.clear()
            }
        }
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("--friend-story"), openStory == nil {
                openStory = FriendStory.samples.first { $0.handle == "jules.mp" }
            }
            if ProcessInfo.processInfo.arguments.contains("--player") {
                showsPlayer = true
            }
        }
        .fullScreenCover(isPresented: $showsLogin) {
            PersonaLoginView {
                showsLogin = false
                showsEntry = true
            }
        }
    }

    private func shell(in size: CGSize) -> some View {
        ZStack {
            WrappedColor.igBackground
            switch tab {
            case .home:
                home
            default:
                placeholder
            }
            VStack(spacing: 0) {
                if tab == .home {
                    IGTopBar(onCreate: { showToast() }, onActivity: { showToast() })
                }
                Spacer()
                IGTabBar(selection: $tab)
                    .padding(.bottom, IGSpace.tabBarBottom)
            }
            if let toast {
                Text(toast)
                    .wrappedType(.caption)
                    .foregroundStyle(WrappedColor.ink)
                    .padding(.horizontal, WrappedSpace.gutter)
                    .frame(minHeight: IGSpace.iconHit)
                    .background(Capsule().fill(WrappedColor.igWhite))
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, IGSpace.tabClearance)
            }
            if let openStory {
                IGStoryViewer(
                    story: openStory,
                    zoom: storyZoom,
                    onClose: closeStory,
                    onUnavailable: { showToast() }
                )
            }
            if showsPlayer {
                StoryPlayer {
                    showsPlayer = false
                }
                .frame(width: size.width, height: size.height, alignment: .top)
            }
            if showsEntry {
                WrappedEntryFlow {
                    showsEntry = false
                }
            }
        }
    }

    private var home: some View {
        ScrollView {
            VStack(spacing: 0) {
                Color.clear.frame(height: IGSpace.topBarHeight)
                IGStoryTray(
                    zoom: storyZoom,
                    openHandle: openStory?.handle,
                    onWrapped: { openWrapped() },
                    onFriend: open
                )
                if showsBanner {
                    WrappedBanner(onOpen: { openWrapped() }, onDismiss: { showsBanner = false })
                        .padding(.horizontal, IGSpace.bannerInset)
                        .padding(.top, IGSpace.bannerGap)
                }
                IGFeedPost()
                Color.clear.frame(height: IGSpace.tabClearance)
            }
        }
        .ignoresSafeArea()
        .scrollIndicators(.hidden)
    }

    private var placeholder: some View {
        Text(tab.title)
            .wrappedType(.title)
            .foregroundStyle(WrappedColor.igWhite)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var referenceImage: Image? {
        guard ProcessInfo.processInfo.arguments.contains("--reference"), !showsPlayer else { return nil }
        let name = openStory == nil ? "01-home" : "05-story-viewer"
        guard let image = UIImage(named: name) else { return nil }
        return Image(uiImage: image)
    }

    private func open(_ story: FriendStory) {
        withAnimation(.easeOut(duration: IGSpace.viewerOpen)) {
            openStory = story
        }
    }

    private func closeStory() {
        withAnimation(.easeIn(duration: IGSpace.viewerDismiss)) {
            openStory = nil
        }
    }

    private func openWrapped() {
        Task {
            if await SessionStore.shared.hasSession() {
                showsEntry = true
            } else {
                showsLogin = true
            }
        }
    }

    private func showToast() {
        toast = "Not part of this demo"
        Task {
            try? await Task.sleep(for: .seconds(2))
            toast = nil
        }
    }
}

private struct WrappedBanner: View {
    var onOpen: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: IGSpace.storyLabelGap) {
                    Text("NEW · ONLY ON YOUR ACCOUNT")
                        .wrappedType(.caption)
                        .foregroundStyle(WrappedColor.ink)
                    DisplayHeadline(
                        copy: "YOUR 2026\nWRAPPED IS HERE",
                        size: WrappedTextStyle.bannerTitle.size,
                        lineHeight: WrappedTextStyle.bannerTitle.lineHeight,
                        weight: WrappedTextStyle.bannerTitle.weight,
                        width: WrappedTextStyle.bannerTitle.width,
                        tracking: WrappedTextStyle.bannerTitle.tracking,
                        color: WrappedColor.ink
                    )
                    HStack(spacing: IGSpace.bannerGap) {
                        Text("Open your Wrapped")
                            .wrappedType(.igUsername)
                            .foregroundStyle(WrappedColor.igWhite)
                            .padding(.horizontal, WrappedSpace.gutter)
                            .frame(minHeight: WrappedSpace.compactControl)
                            .background(Capsule().fill(WrappedColor.ink))
                        Text("About 2 min")
                            .wrappedType(.igUsername)
                            .foregroundStyle(WrappedColor.ink)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(IGSpace.bannerInset)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("wrapped-banner")
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(IGFont.badge)
                    .foregroundStyle(WrappedColor.ink)
                    .frame(width: IGSpace.iconHit, height: IGSpace.iconHit)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Hide banner")
        }
        .background {
            RoundedRectangle(cornerRadius: IGSpace.bannerRadius, style: .continuous)
                .fill(WrappedColor.igPink)
            Circle()
                .stroke(WrappedColor.storyRing, lineWidth: IGSpace.ringStroke * 3)
                .frame(width: IGSpace.storyDiameter, height: IGSpace.storyDiameter)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: IGSpace.bannerInset, y: -IGSpace.bannerGap)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: IGSpace.bannerRadius, style: .continuous))
    }
}
