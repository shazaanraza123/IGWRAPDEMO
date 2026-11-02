import SwiftUI

enum MayaReels {
    static let headline = "DOWN THE\nRABBIT HOLE."
    static let fastestRising = "Ceramics, 4x since June"
    static let sent = "And you sent 1,206 of them to friends."
    static let categories: [(name: String, percent: String, width: CGFloat)] = [
        ("Streetwear", "31%", 1),
        ("Food in Chicago", "22%", 22.0 / 31.0),
        ("Film photography", "18%", 18.0 / 31.0),
        ("Interior design", "12%", 12.0 / 31.0),
        ("Ceramics", "9%", 9.0 / 31.0)
    ]
}

enum MayaPost {
    static let headline = "MAIN CHARACTER\nPOST"
    static let likes = "2,184"
    static let comments = "418 comments. Unhinged ones."
    static let average = "That's 3x your average post."
    static let posted = "Measured · posted Jul 19"
    static let dateChip = "Jul 19"
    static let photo = "main-character"
}

enum MayaChat {
    static let headline = "THE STORY THAT\nBROKE THE\nGROUP CHAT."
    static let replies = "47"
    static let repliesCaption = "replies in a day"
    static let storyChip = "Story · Mar 14"
    static let note = "Your most-replied Story of the year. Who said what stays in your DMs."
    static let photo = "story-0314"
}

enum MayaCircle {
    static let headline = "YOUR CIRCLE."
    static let note = "The five accounts you showed up for most. No ranking, no scores."
    static let privacy = "Want the ranked version? It lives in Privacy, off by default."
    static let handles = ["dee.films", "jules.mp", "nico_k", "sam.wav", "tori.eats"]
}

enum MayaNight {
    static let headline = "WELCOME TO\nTHE 3AM CLUB."
    static let time = "3:42 AM"
    static let note = "A Tuesday in May. We hope it was worth it."
}

struct ReelsCard: View {
    var onShare: () -> Void
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
                    text: MayaReels.sent,
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
                copy: MayaReels.headline,
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
            ForEach(Array(MayaReels.categories.enumerated()), id: \.element.name) { index, category in
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
                                text: category.percent,
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
                                .frame(width: proxy.size.width * category.width)
                        }
                        .frame(height: CardSpace.reelsBar)
                    }
                    .frame(minHeight: WrappedSpace.minHit)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("reel-cat-\(index)")
                .accessibilityLabel("\(category.name), \(category.percent)")
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
                    text: MayaReels.fastestRising,
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
                    copy: MayaPost.headline,
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
                text: MayaPost.comments,
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
                    text: MayaPost.average,
                    size: CardSpace.averageLine,
                    weight: CardSpace.strong,
                    width: CardSpace.regular,
                    color: WrappedColor.ink
                )
                .allowsHitTesting(false)
                .padding(.horizontal, WrappedSpace.gutter)
                HStack(spacing: CardSpace.blockGap) {
                    Text(MayaPost.posted)
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
            photo(MayaPost.photo)
                .frame(width: 300, height: 250)
                .clipped()
            HStack {
                CardText(text: "@\(MayaOpening.handle)", size: WrappedTextStyle.caption.size, weight: WrappedTextStyle.caption.weight, width: CardSpace.regular, color: WrappedColor.ink)
                Spacer()
                CardText(text: MayaPost.dateChip, size: WrappedTextStyle.caption.size, weight: WrappedTextStyle.caption.weight, width: CardSpace.regular, color: WrappedColor.muted)
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
            CardText(text: MayaPost.likes, size: CardSpace.postLikes, width: CardSpace.titleWidth, color: WrappedColor.igWhite)
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
    var onClose: () -> Void

    var body: some View {
        ZStack {
            WrappedColor.igBackground.ignoresSafeArea()
            VStack(spacing: CardSpace.blockGap) {
                if let image = BundlePhoto.image(named: MayaPost.photo) {
                    Image(uiImage: image).resizable().scaledToFit()
                }
                CardText(text: "@\(MayaOpening.handle)", size: CardSpace.openingHandleSize, width: CardSpace.regular, color: WrappedColor.igWhite)
                CardText(text: MayaPost.likes, size: CardSpace.stickerName, color: WrappedColor.igWhite)
                CardText(text: MayaPost.comments, size: CardSpace.yearSupportSize, weight: WrappedTextStyle.body.weight, width: CardSpace.regular, color: WrappedColor.igWhite)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: onClose)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("post-detail")
        .accessibilityLabel(MayaPost.comments)
        .accessibilityAddTraits(.isButton)
    }
}

struct GroupChatCard: View {
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
                DisplayHeadline(copy: MayaChat.headline, size: CardSpace.chatHeadline, lineHeight: CardSpace.openingHeadlineLine, tracking: CardSpace.algorithmHeadlineTracking, color: WrappedColor.ink)
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
                CardText(text: MayaChat.replies, size: CardSpace.chatReplies, tracking: CardSpace.openingYearTracking, lineHeight: 0.85, color: WrappedColor.ink)
                CardText(text: MayaChat.repliesCaption, size: CardSpace.chatCaption, weight: CardSpace.strong, width: CardSpace.regular, color: WrappedColor.ink)
            }
            .allowsHitTesting(false)
            .padding(.leading, 216)
            .padding(.top, 556)

            VStack {
                Spacer(minLength: 0).allowsHitTesting(false)
                CardText(text: MayaChat.note, size: CardSpace.yearSupportSize, weight: WrappedTextStyle.body.weight, width: WrappedTextStyle.body.width, color: WrappedColor.ink)
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
            if let image = BundlePhoto.image(named: MayaChat.photo) {
                Image(uiImage: image).resizable().scaledToFill()
            }
            CardText(text: MayaChat.storyChip, size: CardSpace.storyChipSize, weight: CardSpace.strong, width: CardSpace.regular, tracking: CardSpace.chipTracking, color: WrappedColor.igWhite)
                .padding(CardSpace.openingBadgePad)
        }
        .frame(width: 168, height: 280)
        .clipShape(RoundedRectangle(cornerRadius: CardSpace.blockGap))
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 16).fill(WrappedColor.storyRing))
    }
}

struct StoryReplayCover: View {
    var onClose: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            MonthTone.gradient(2).ignoresSafeArea()
            if let image = BundlePhoto.image(named: MayaChat.photo) {
                Image(uiImage: image).resizable().scaledToFill().ignoresSafeArea()
            }
            Capsule()
                .fill(WrappedColor.igWhite)
                .frame(height: WrappedSpace.progressThickness)
                .padding(.horizontal, CardSpace.chromeLeading)
                .padding(.top, WrappedSpace.progressTop)
            CardText(text: MayaChat.storyChip, size: CardSpace.openingHandleSize, weight: CardSpace.strong, width: CardSpace.regular, color: WrappedColor.igWhite)
                .padding(.top, WrappedSpace.contentTop)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: onClose)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("story-replay")
        .accessibilityLabel(MayaChat.storyChip)
        .accessibilityAddTraits(.isButton)
    }
}

struct CircleCard: View {
    @State private var enlarged: String?

    var body: some View {
        ZStack(alignment: .topLeading) {
            WrappedColor.igOrange.ignoresSafeArea().allowsHitTesting(false)
            VStack(alignment: .leading, spacing: CardSpace.blockGap) {
                CardText(text: "YOUR PEOPLE", size: WrappedTextStyle.eyebrow.size, weight: WrappedTextStyle.eyebrow.weight, width: WrappedTextStyle.eyebrow.width, tracking: WrappedTextStyle.eyebrow.tracking, color: WrappedColor.ink)
                DisplayHeadline(copy: MayaCircle.headline, size: CardSpace.openingHeadline, lineHeight: CardSpace.openingHeadlineLine, tracking: CardSpace.openingHeadlineTracking, color: WrappedColor.ink)
                CardText(text: MayaCircle.note, size: CardSpace.openingSupport, weight: WrappedTextStyle.body.weight, width: CardSpace.regular, lineHeight: 1.3, color: WrappedColor.ink)
            }
            .allowsHitTesting(false)
            .padding(.horizontal, WrappedSpace.gutter)
            .padding(.top, CardSpace.yearCopyTop)

            people
                .padding(.top, 328)

            VStack {
                Spacer(minLength: 0).allowsHitTesting(false)
                CardText(text: MayaCircle.privacy, size: CardSpace.undercutSize, weight: WrappedTextStyle.body.weight, width: CardSpace.regular, color: WrappedColor.ink, alignment: .center)
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
            ForEach(MayaCircle.handles, id: \.self) { handle in
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
    var onShare: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            WrappedColor.nightNavy.ignoresSafeArea().allowsHitTesting(false)
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: CardSpace.yearCopyGap) {
                    CardText(text: "YOUR HABITS", size: WrappedTextStyle.eyebrow.size, weight: WrappedTextStyle.eyebrow.weight, width: WrappedTextStyle.eyebrow.width, tracking: WrappedTextStyle.eyebrow.tracking, color: WrappedColor.igYellow)
                    DisplayHeadline(copy: MayaNight.headline, size: CardSpace.yearHeadline, lineHeight: CardSpace.openingHeadlineLine, tracking: CardSpace.yearHeadlineTracking, color: WrappedColor.igWhite)
                }
                .allowsHitTesting(false)
                .padding(.top, CardSpace.yearCopyTop)
                clock
                    .frame(maxWidth: .infinity)
                    .padding(.top, CardSpace.topicGap)
                    .allowsHitTesting(false)
                VStack(alignment: .leading, spacing: CardSpace.chipGap) {
                    CardText(text: "LATEST SCROLL", size: WrappedTextStyle.caption.size, weight: CardSpace.strong, width: CardSpace.regular, tracking: 1.2, color: WrappedColor.igYellow)
                    CardText(text: MayaNight.time, size: CardSpace.nightTime, tracking: CardSpace.openingYearTracking, lineHeight: 0.85, color: WrappedColor.igWhite)
                    CardText(text: MayaNight.note, size: CardSpace.openingSupport, weight: WrappedTextStyle.body.weight, width: CardSpace.regular, color: WrappedColor.onInkSecondary)
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
        .accessibilityLabel("A clock showing \(MayaNight.time)")
    }
}
