import SwiftUI

struct ReelsCard: View {
    var card: RunCard
    var onShare: () -> Void

    private var categories: [NamedPercent] { card.payload.categories ?? [] }

    private func barWidth(_ category: NamedPercent) -> CGFloat {
        let first = CGFloat(categories.first?.percent ?? 0)
        guard first > 0 else { return 0 }
        return CGFloat(category.percent) / first
    }
    @State private var selected: String?

    var body: some View {
        ZStack(alignment: .topLeading) {
            WrappedColor.igOrange.ignoresSafeArea().allowsHitTesting(false)
            VStack(alignment: .leading, spacing: 0) {
                header.allowsHitTesting(false)
                bars
                if selected != nil {
                    samples.allowsHitTesting(false)
                }
                Spacer(minLength: 0).allowsHitTesting(false)
                rising.allowsHitTesting(false)
                CardText(
                    text: card.payload.copy?.sent ?? "",
                    size: CardSpace.openingSupport,
                    weight: CardSpace.medium,
                    width: CardSpace.regular,
                    color: WrappedColor.ink
                )
                .allowsHitTesting(false)
                .padding(.horizontal, WrappedSpace.gutter)
                .padding(.top, CardSpace.blockGap)
                SharePill(title: "Share this story", action: onShare)
                    .frame(maxWidth: .infinity)
                    .padding(.top, CardSpace.blockGap)
                    .padding(.bottom, WrappedSpace.pillBottomInset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: CardSpace.yearCopyGap) {
            CardText(
                text: "YOUR REELS",
                size: WrappedTextStyle.eyebrow.size,
                weight: WrappedTextStyle.eyebrow.weight,
                width: WrappedTextStyle.eyebrow.width,
                tracking: WrappedTextStyle.eyebrow.tracking,
                color: WrappedColor.ink
            )
            DisplayHeadline(
                copy: card.headline,
                size: CardSpace.reelsHeadline,
                lineHeight: CardSpace.openingHeadlineLine,
                tracking: CardSpace.yearHeadlineTracking,
                color: WrappedColor.ink
            )
            CardText(
                text: "What kept you watching, by share of your Reels time.",
                size: CardSpace.yearSupportSize,
                weight: WrappedTextStyle.body.weight,
                width: WrappedTextStyle.body.width,
                color: WrappedColor.ink
            )
        }
        .padding(.horizontal, WrappedSpace.gutter)
        .padding(.top, CardSpace.yearCopyTop)
    }

    private var bars: some View {
        VStack(alignment: .leading, spacing: CardSpace.yearCopyGap) {
            ForEach(Array(categories.enumerated()), id: \.element.name) { index, category in
                Button {
                    selected = selected == category.name ? nil : category.name
                } label: {
                    VStack(alignment: .leading, spacing: CardSpace.chipPadV) {
                        HStack {
                            CardText(
                                text: category.name,
                                size: CardSpace.reelsName,
                                width: CardSpace.semiCondensed,
                                color: WrappedColor.ink,
                                uppercase: true
                            )
                            Spacer(minLength: 0)
                            CardText(
                                text: "\(category.percent)%",
                                size: CardSpace.yearSupportSize,
                                weight: CardSpace.strong,
                                width: CardSpace.regular,
                                color: WrappedColor.ink
                            )
                        }
                        GeometryReader { proxy in
                            RoundedRectangle(cornerRadius: CardSpace.chipRadius)
                                .fill(WrappedColor.ink.opacity(CardSpace.barTrack))
                            RoundedRectangle(cornerRadius: CardSpace.chipRadius)
                                .fill(WrappedColor.ink)
                                .frame(width: proxy.size.width * barWidth(category))
                        }
                        .frame(height: CardSpace.reelsBar)
                    }
                    .frame(minHeight: WrappedSpace.minHit)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("reel-cat-\(index)")
                .accessibilityLabel("\(category.name), \(category.percent)%")
            }
        }
        .padding(.horizontal, WrappedSpace.gutter)
        .padding(.top, CardSpace.topicGap)
    }

    private var samples: some View {
        HStack(spacing: WrappedSpace.gridGap) {
            ForEach(0 ..< 3, id: \.self) { index in
                RoundedRectangle(cornerRadius: CardSpace.swatchRadius)
                    .fill(WrappedColor.ink.opacity(0.2))
                    .frame(height: WrappedSpace.minHit)
                    .overlay {
                        Image(systemName: "play.fill")
                            .foregroundStyle(WrappedColor.ink)
                    }
                    .accessibilityIdentifier("reel-sample-\(index)")
            }
        }
        .padding(.horizontal, WrappedSpace.gutter)
        .padding(.top, CardSpace.chipGap)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("reel-samples")
    }

    private var rising: some View {
        HStack(spacing: CardSpace.yearCopyGap) {
            Image(systemName: "arrow.up.right")
                .font(.system(size: CardSpace.stickerName, weight: .bold))
                .foregroundStyle(WrappedColor.igYellow)
            VStack(alignment: .leading, spacing: 0) {
                CardText(
                    text: "FASTEST RISING",
                    size: CardSpace.markDigits,
                    weight: CardSpace.strong,
                    width: CardSpace.regular,
                    tracking: CardSpace.kickerTracking,
                    color: WrappedColor.igYellow
                )
                CardText(
                    text: card.payload.copy?.fastestRising ?? "",
                    size: CardSpace.openingHandleSize,
                    width: CardSpace.semiCondensed,
                    color: WrappedColor.igWhite,
                    uppercase: true
                )
            }
        }
        .padding(CardSpace.blockGap)
        .background(RoundedRectangle(cornerRadius: CardSpace.stickerRadius).fill(WrappedColor.ink))
        .rotationEffect(.degrees(-3))
        .padding(.horizontal, WrappedSpace.gutter)
    }
}

struct MainCharacterCard: View {
    var card: RunCard
    var handle: String
    var onShare: () -> Void
    var onOpenPost: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            WrappedColor.igYellow.ignoresSafeArea().allowsHitTesting(false)
            VStack(alignment: .leading, spacing: CardSpace.blockGap) {
                CardText(
                    text: "YOUR MOMENTS",
                    size: WrappedTextStyle.eyebrow.size,
                    weight: WrappedTextStyle.eyebrow.weight,
                    width: WrappedTextStyle.eyebrow.width,
                    tracking: WrappedTextStyle.eyebrow.tracking,
                    color: WrappedColor.ink
                )
                DisplayHeadline(
                    copy: card.headline,
                    size: CardSpace.postHeadline,
                    lineHeight: CardSpace.openingHeadlineLine,
                    tracking: CardSpace.algorithmHeadlineTracking,
                    color: WrappedColor.ink
                )
            }
            .allowsHitTesting(false)
            .padding(.horizontal, WrappedSpace.gutter)
            .padding(.top, CardSpace.yearCopyTop)

            Button(action: onOpenPost) {
                postCard
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("main-post")
            .rotationEffect(.degrees(-3))
            .padding(.leading, 35)
            .padding(.top, 292)

            likeBubble
                .allowsHitTesting(false)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 22)
                .padding(.top, 272)

            CardText(
                text: card.payload.copy?.comments ?? "",
                size: CardSpace.yearSupportSize,
                weight: CardSpace.medium,
                width: CardSpace.regular,
                color: WrappedColor.igWhite
            )
            .allowsHitTesting(false)
            .padding(CardSpace.blockGap)
            .background(
                RoundedRectangle(cornerRadius: 18).fill(WrappedColor.ink)
            )
            .rotationEffect(.degrees(-2))
            .padding(.leading, 14)
            .padding(.top, 626)

            VStack {
                Spacer(minLength: 0).allowsHitTesting(false)
                CardText(
                    text: card.payload.copy?.average ?? "",
                    size: CardSpace.averageLine,
                    weight: CardSpace.strong,
                    width: CardSpace.regular,
                    color: WrappedColor.ink
                )
                .allowsHitTesting(false)
                .padding(.horizontal, WrappedSpace.gutter)
                HStack(spacing: CardSpace.blockGap) {
                    Text(card.payload.copy?.posted ?? "")
                        .wrappedType(.caption)
                        .foregroundStyle(WrappedColor.ink)
                        .allowsHitTesting(false)
                    SharePill(action: onShare)
                }
                .padding(.bottom, WrappedSpace.pillBottomInset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var postCard: some View {
        VStack(alignment: .leading, spacing: CardSpace.yearCopyGap) {
            photo(card.payload.photo ?? "")
                .frame(width: 300, height: 250)
                .clipped()
            HStack {
                CardText(text: "@\(handle)", size: WrappedTextStyle.caption.size, weight: WrappedTextStyle.caption.weight, width: CardSpace.regular, color: WrappedColor.ink)
                Spacer()
                CardText(text: card.payload.copy?.dateChip ?? "", size: WrappedTextStyle.caption.size, weight: WrappedTextStyle.caption.weight, width: CardSpace.regular, color: WrappedColor.muted)
            }
        }
        .padding(CardSpace.openingBadgePad)
        .frame(width: 320)
        .background(WrappedColor.igWhite)
        .shadow(color: WrappedColor.ink.opacity(CardSpace.stickerShadow), radius: CardSpace.stickerRadius, y: CardSpace.openingBadgePad)
    }

    private var likeBubble: some View {
        HStack(spacing: CardSpace.chipGap) {
            Image(systemName: "heart.fill")
                .foregroundStyle(WrappedColor.igWhite)
            CardText(text: CountText.string(card.payload.likes ?? 0), size: CardSpace.postLikes, width: CardSpace.titleWidth, color: WrappedColor.igWhite)
        }
        .padding(CardSpace.blockGap)
        .background(RoundedRectangle(cornerRadius: CardSpace.stickerRadius).fill(WrappedColor.likeRed))
        .rotationEffect(.degrees(4))
    }

    private func photo(_ name: String) -> some View {
        Group {
            if let image = BundlePhoto.image(named: name) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                WrappedColor.ink.opacity(0.15)
            }
        }
    }
}

struct PostDetailCover: View {
    var card: RunCard
    var handle: String
    var onClose: () -> Void

    var body: some View {
        ZStack {
            WrappedColor.igBackground.ignoresSafeArea()
            VStack(spacing: CardSpace.blockGap) {
                if let image = BundlePhoto.image(named: card.payload.photo ?? "") {
                    Image(uiImage: image).resizable().scaledToFit()
                }
                CardText(text: "@\(handle)", size: CardSpace.openingHandleSize, width: CardSpace.regular, color: WrappedColor.igWhite)
                CardText(text: CountText.string(card.payload.likes ?? 0), size: CardSpace.stickerName, color: WrappedColor.igWhite)
                CardText(text: card.payload.copy?.comments ?? "", size: CardSpace.yearSupportSize, weight: WrappedTextStyle.body.weight, width: CardSpace.regular, color: WrappedColor.igWhite)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: onClose)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("post-detail")
        .accessibilityLabel(card.payload.copy?.comments ?? "")
        .accessibilityAddTraits(.isButton)
    }
}

struct GroupChatCard: View {
    var card: RunCard
    var onShare: () -> Void
    var onOpenStory: () -> Void

    private let bubbles: [(CGFloat, Bool)] = [
        (120, true), (84, false), (140, true), (64, false), (104, true)
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            WrappedColor.closeGreen.ignoresSafeArea().allowsHitTesting(false)
            VStack(alignment: .leading, spacing: CardSpace.yearCopyGap) {
                CardText(text: "YOUR MOMENTS", size: WrappedTextStyle.eyebrow.size, weight: WrappedTextStyle.eyebrow.weight, width: WrappedTextStyle.eyebrow.width, tracking: WrappedTextStyle.eyebrow.tracking, color: WrappedColor.ink)
                DisplayHeadline(copy: card.headline, size: CardSpace.chatHeadline, lineHeight: CardSpace.openingHeadlineLine, tracking: CardSpace.algorithmHeadlineTracking, color: WrappedColor.ink)
            }
            .allowsHitTesting(false)
            .padding(.horizontal, WrappedSpace.gutter)
            .padding(.top, CardSpace.yearCopyTop)

            Button(action: onOpenStory) {
                storyThumb
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("chat-story")
            .rotationEffect(.degrees(-4))
            .padding(.leading, 28)
            .padding(.top, 360)

            VStack(alignment: .trailing, spacing: CardSpace.chipGap) {
                ForEach(Array(bubbles.enumerated()), id: \.offset) { _, bubble in
                    RoundedRectangle(cornerRadius: 15)
                        .fill(bubble.1 ? WrappedColor.ink : WrappedColor.igWhite)
                        .frame(width: bubble.0, height: 30)
                }
            }
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 22)
            .padding(.top, 352)

            VStack(alignment: .leading, spacing: 0) {
                CardText(text: card.payload.replies.map(String.init) ?? "", size: CardSpace.chatReplies, tracking: CardSpace.openingYearTracking, lineHeight: 0.85, color: WrappedColor.ink)
                CardText(text: "replies in a day", size: CardSpace.chatCaption, weight: CardSpace.strong, width: CardSpace.regular, color: WrappedColor.ink)
            }
            .allowsHitTesting(false)
            .padding(.leading, 216)
            .padding(.top, 556)

            VStack {
                Spacer(minLength: 0).allowsHitTesting(false)
                CardText(text: "Your most-replied Story of the year. Who said what stays in your DMs.", size: CardSpace.yearSupportSize, weight: WrappedTextStyle.body.weight, width: WrappedTextStyle.body.width, color: WrappedColor.ink)
                    .allowsHitTesting(false)
                    .padding(.horizontal, WrappedSpace.gutter)
                SharePill(title: "Share this story", action: onShare)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, WrappedSpace.pillBottomInset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var storyThumb: some View {
        ZStack(alignment: .bottomLeading) {
            MonthTone.gradient(2)
            if let image = BundlePhoto.image(named: card.payload.photo ?? "") {
                Image(uiImage: image).resizable().scaledToFill()
            }
            CardText(text: card.payload.copy?.storyChip ?? "", size: CardSpace.storyChipSize, weight: CardSpace.strong, width: CardSpace.regular, tracking: CardSpace.chipTracking, color: WrappedColor.igWhite)
                .padding(CardSpace.openingBadgePad)
        }
        .frame(width: 168, height: 280)
        .clipShape(RoundedRectangle(cornerRadius: CardSpace.blockGap))
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 16).fill(WrappedColor.storyRing))
    }
}

struct StoryReplayCover: View {
    var card: RunCard
    var onClose: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            MonthTone.gradient(2).ignoresSafeArea()
            if let image = BundlePhoto.image(named: card.payload.photo ?? "") {
                Image(uiImage: image).resizable().scaledToFill().ignoresSafeArea()
            }
            Capsule()
                .fill(WrappedColor.igWhite)
                .frame(height: WrappedSpace.progressThickness)
                .padding(.horizontal, CardSpace.chromeLeading)
                .padding(.top, WrappedSpace.progressTop)
            CardText(text: card.payload.copy?.storyChip ?? "", size: CardSpace.openingHandleSize, weight: CardSpace.strong, width: CardSpace.regular, color: WrappedColor.igWhite)
                .padding(.top, WrappedSpace.contentTop)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: onClose)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("story-replay")
        .accessibilityLabel(card.payload.copy?.storyChip ?? "")
        .accessibilityAddTraits(.isButton)
    }
}

struct CircleCard: View {
    var card: RunCard
    @State private var enlarged: String?

    var body: some View {
        ZStack(alignment: .topLeading) {
            WrappedColor.igOrange.ignoresSafeArea().allowsHitTesting(false)
            VStack(alignment: .leading, spacing: CardSpace.blockGap) {
                CardText(text: "YOUR PEOPLE", size: WrappedTextStyle.eyebrow.size, weight: WrappedTextStyle.eyebrow.weight, width: WrappedTextStyle.eyebrow.width, tracking: WrappedTextStyle.eyebrow.tracking, color: WrappedColor.ink)
                DisplayHeadline(copy: card.headline, size: CardSpace.openingHeadline, lineHeight: CardSpace.openingHeadlineLine, tracking: CardSpace.openingHeadlineTracking, color: WrappedColor.ink)
                CardText(text: card.payload.copy?.note ?? "", size: CardSpace.openingSupport, weight: WrappedTextStyle.body.weight, width: CardSpace.regular, lineHeight: 1.3, color: WrappedColor.ink)
            }
            .allowsHitTesting(false)
            .padding(.horizontal, WrappedSpace.gutter)
            .padding(.top, CardSpace.yearCopyTop)

            people
                .padding(.top, 328)

            VStack {
                Spacer(minLength: 0).allowsHitTesting(false)
                CardText(text: card.payload.copy?.privacy ?? "", size: CardSpace.undercutSize, weight: WrappedTextStyle.body.weight, width: CardSpace.regular, color: WrappedColor.ink, alignment: .center)
                    .allowsHitTesting(false)
                    .padding(.horizontal, WrappedSpace.gutter)
                PrivatePill()
                    .padding(.bottom, 28)
            }
            if let enlarged {
                enlargedAvatar(enlarged)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var people: some View {
        let columns = [GridItem(.adaptive(minimum: 98), spacing: 18)]
        return LazyVGrid(columns: columns, spacing: 18) {
            ForEach(card.payload.handles ?? [], id: \.self) { handle in
                Button {
                    enlarged = handle
                } label: {
                    VStack(spacing: CardSpace.chipGap) {
                        avatar(handle)
                            .frame(width: 98, height: 98)
                        CardText(text: handle, size: CardSpace.yearSupportSize, weight: CardSpace.strong, width: CardSpace.regular, color: WrappedColor.ink)
                    }
                    .frame(minHeight: WrappedSpace.minHit)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("circle-\(handle)")
                .accessibilityLabel(handle)
            }
        }
        .padding(.horizontal, WrappedSpace.gutter)
    }

    private func avatar(_ handle: String) -> some View {
        ZStack {
            Circle().stroke(WrappedColor.storyRing, lineWidth: 4)
            PersonAvatar(handle: handle, photo: PersonAvatar.photoName(for: handle))
                .padding(4)
        }
    }

    private func enlargedAvatar(_ handle: String) -> some View {
        ZStack {
            WrappedColor.ink.opacity(0.72).ignoresSafeArea()
            VStack(spacing: CardSpace.blockGap) {
                avatar(handle).frame(width: 220, height: 220)
                CardText(text: handle, size: CardSpace.topicName, width: CardSpace.titleWidth, color: WrappedColor.igWhite)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { enlarged = nil }
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("circle-enlarged")
        .accessibilityLabel(handle)
        .accessibilityAddTraits(.isButton)
    }
}

struct ThreeAMCard: View {
    var card: RunCard
    var onShare: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            WrappedColor.nightNavy.ignoresSafeArea().allowsHitTesting(false)
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: CardSpace.yearCopyGap) {
                    CardText(text: "YOUR HABITS", size: WrappedTextStyle.eyebrow.size, weight: WrappedTextStyle.eyebrow.weight, width: WrappedTextStyle.eyebrow.width, tracking: WrappedTextStyle.eyebrow.tracking, color: WrappedColor.igYellow)
                    DisplayHeadline(copy: card.headline, size: CardSpace.yearHeadline, lineHeight: CardSpace.openingHeadlineLine, tracking: CardSpace.yearHeadlineTracking, color: WrappedColor.igWhite)
                }
                .allowsHitTesting(false)
                .padding(.top, CardSpace.yearCopyTop)
                clock
                    .frame(maxWidth: .infinity)
                    .padding(.top, CardSpace.topicGap)
                    .allowsHitTesting(false)
                VStack(alignment: .leading, spacing: CardSpace.chipGap) {
                    CardText(text: "LATEST SCROLL", size: WrappedTextStyle.caption.size, weight: CardSpace.strong, width: CardSpace.regular, tracking: 1.2, color: WrappedColor.igYellow)
                    CardText(text: card.payload.copy?.time ?? "", size: CardSpace.nightTime, tracking: CardSpace.openingYearTracking, lineHeight: 0.85, color: WrappedColor.igWhite)
                    CardText(text: card.payload.copy?.note ?? "", size: CardSpace.openingSupport, weight: WrappedTextStyle.body.weight, width: CardSpace.regular, color: WrappedColor.onInkSecondary)
                }
                .allowsHitTesting(false)
                .padding(.top, CardSpace.topicGap)
                Spacer(minLength: 0).allowsHitTesting(false)
                SharePill(title: "Share this story", inverted: true, action: onShare)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, WrappedSpace.pillBottomInset)
            }
            .padding(.horizontal, WrappedSpace.gutter)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear { shown = true }
    }

    private var clock: some View {
        ZStack {
            Circle().stroke(WrappedColor.igWhite.opacity(0.18), lineWidth: 18).frame(width: 224, height: 224)
            Circle().trim(from: 0, to: 0.31).stroke(WrappedColor.igYellow, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .frame(width: 224, height: 224)
                .rotationEffect(.degrees(-90))
            Circle().fill(WrappedColor.ink).frame(width: 176, height: 176)
            Rectangle().fill(WrappedColor.igWhite).frame(width: 6, height: 52)
                .offset(y: -26)
                .rotationEffect(.degrees(reduceMotion || shown ? CardSpace.clockHour : 0))
            Rectangle().fill(WrappedColor.igYellow).frame(width: CardSpace.openingBadgeBorder, height: 70)
                .offset(y: -35)
                .rotationEffect(.degrees(reduceMotion || shown ? CardSpace.clockMinute : 0))
            Circle().fill(WrappedColor.igYellow).frame(width: 14, height: 14)
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 1.2), value: shown)
        .accessibilityLabel("A clock showing \(card.payload.copy?.time ?? "")")
    }
}
