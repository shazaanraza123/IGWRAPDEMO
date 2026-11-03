import SwiftUI

struct AlgorithmCard: View {
    var card: RunCard
    var onShare: () -> Void
    var onSaved: () -> Void

    private var feedback: FeedbackStore { FeedbackStore.shared }

    var body: some View {
        ZStack(alignment: .topLeading) {
            WrappedColor.igViolet.ignoresSafeArea().allowsHitTesting(false)
            VStack(alignment: .leading, spacing: 0) {
                copy.allowsHitTesting(false)
                topics
                    .padding(.top, CardSpace.topicGap)
                Spacer(minLength: 0).allowsHitTesting(false)
                mosaic.allowsHitTesting(false)
                SharePill(title: "Share this story", inverted: true, action: onShare)
                    .frame(maxWidth: .infinity)
                    .padding(.top, CardSpace.blockGap)
                    .padding(.bottom, WrappedSpace.pillBottomInset)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            if feedback.didWrite {
                Color.clear
                    .frame(width: WrappedSpace.minHit, height: WrappedSpace.minHit)
                    .accessibilityIdentifier("feedback-written")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task { await feedback.loadRemote() }
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: CardSpace.blockGap) {
            CardText(
                text: "YOUR HABITS",
                size: WrappedTextStyle.eyebrow.size,
                weight: WrappedTextStyle.eyebrow.weight,
                width: WrappedTextStyle.eyebrow.width,
                tracking: WrappedTextStyle.eyebrow.tracking,
                color: WrappedColor.igYellow
            )
            DisplayHeadline(
                copy: card.headline,
                size: CardSpace.algorithmHeadline,
                lineHeight: CardSpace.algorithmHeadlineLine,
                tracking: CardSpace.algorithmHeadlineTracking,
                color: WrappedColor.igWhite
            )
            HStack(spacing: CardSpace.chipGap) {
                Text("Inferred")
                    .font(CardTypeface.font(size: WrappedTextStyle.caption.size, weight: WrappedTextStyle.caption.weight, width: CardSpace.regular))
                    .foregroundStyle(WrappedColor.igWhite)
                    .padding(.horizontal, CardSpace.openingBadgePad)
                    .padding(.vertical, CardSpace.chipPadV)
                    .overlay {
                        Capsule().stroke(
                            WrappedColor.igWhite,
                            style: StrokeStyle(lineWidth: CardSpace.dashedStroke, dash: [CardSpace.chipPadV, CardSpace.chipPadV])
                        )
                    }
                CardText(
                    text: "Your taps tune Explore. Undo in Settings.",
                    size: WrappedTextStyle.caption.size,
                    weight: WrappedTextStyle.caption.weight,
                    width: WrappedTextStyle.caption.width,
                    color: WrappedColor.igWhite
                )
            }
        }
        .padding(.horizontal, WrappedSpace.gutter)
        .padding(.top, CardSpace.yearCopyTop)
    }

    private var topics: some View {
        VStack(alignment: .leading, spacing: CardSpace.topicGap) {
            ForEach(Array((card.payload.topics ?? []).enumerated()), id: \.element.id) { offset, topic in
                topicRow(topic, offset: offset)
            }
        }
        .padding(.horizontal, WrappedSpace.gutter)
    }

    private func topicTitle(_ topic: TopicSlot) -> String {
        topic.isUndercut == true ? "...\(topic.name.lowercased())?" : topic.name
    }

    private func topicRow(_ topic: TopicSlot, offset: Int) -> some View {
        VStack(alignment: .leading, spacing: CardSpace.topicRowGap) {
            HStack(alignment: .firstTextBaseline, spacing: CardSpace.topicRowGap) {
                CardText(
                    text: String(format: "%02d", offset + 1),
                    size: CardSpace.topicIndex,
                    weight: CardSpace.strong,
                    width: CardSpace.regular,
                    color: WrappedColor.igYellow
                )
                .allowsHitTesting(false)
                CardText(
                    text: topicTitle(topic),
                    size: CardSpace.topicName,
                    width: CardSpace.titleWidth,
                    lineHeight: 1,
                    color: topic.isUndercut == true ? WrappedColor.igYellow : WrappedColor.igWhite,
                    uppercase: true
                )
                .allowsHitTesting(false)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            HStack(spacing: CardSpace.chipGap) {
                if topic.isUndercut == true {
                    choice("Guilty", kind: FeedbackKind.guilty, topic: topic, identifier: "feedback-guilty-\(offset)")
                    CardText(
                        text: card.payload.copy?.undercut ?? "",
                        size: CardSpace.undercutSize,
                        weight: WrappedTextStyle.body.weight,
                        width: WrappedTextStyle.body.width,
                        color: WrappedColor.igWhite
                    )
                    .allowsHitTesting(false)
                } else {
                    choice("More of this", kind: FeedbackKind.moreOfThis, topic: topic, identifier: "feedback-more-\(offset)")
                    choice("Not me", kind: FeedbackKind.notMe, topic: topic, identifier: "feedback-not-\(offset)")
                }
            }
            .padding(.leading, CardSpace.topicButtonInset)
        }
    }

    private func choice(_ title: String, kind: String, topic: TopicSlot, identifier: String) -> some View {
        let selected = feedback.selection(for: topic.name) == kind
        return Button {
            Task {
                if await feedback.choose(target: topic.name, kind: kind) {
                    onSaved()
                }
            }
        } label: {
            HStack(spacing: CardSpace.chipGap) {
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: CardSpace.topicIndex, weight: .bold))
                }
                Text(title)
                    .font(CardTypeface.font(
                        size: WrappedTextStyle.caption.size,
                        weight: selected ? CardSpace.strong : CardSpace.medium,
                        width: CardSpace.regular
                    ))
            }
            .foregroundStyle(selected ? WrappedColor.igViolet : WrappedColor.igWhite)
            .padding(.horizontal, CardSpace.chipTextPad)
            .frame(height: CardSpace.chipHeight)
            .background {
                if selected {
                    Capsule().fill(WrappedColor.igWhite)
                } else {
                    Capsule().strokeBorder(
                        WrappedColor.igWhite.opacity(CardSpace.quietStroke),
                        lineWidth: CardSpace.dashedStroke
                    )
                }
            }
            .frame(minHeight: WrappedSpace.minHit)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var mosaic: some View {
        HStack(spacing: WrappedSpace.gridGap) {
            VStack(spacing: WrappedSpace.gridGap) {
                mosaicCell(WrappedColor.algorithmTileA)
                mosaicCell(WrappedColor.algorithmTileB) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: CardSpace.mosaicHeart, weight: .bold))
                        .foregroundStyle(WrappedColor.igWhite)
                }
            }
            mosaicCell(WrappedColor.algorithmTileB) {
                Image(systemName: "play.fill")
                    .font(.system(size: CardSpace.mosaicIcon, weight: .bold))
                    .foregroundStyle(WrappedColor.igWhite)
            }
            VStack(spacing: WrappedSpace.gridGap) {
                mosaicCell(WrappedColor.algorithmTileC)
                mosaicCell(WrappedColor.algorithmTileA)
            }
        }
        .frame(height: CardSpace.algorithmMosaicHeight)
        .padding(.horizontal, WrappedSpace.gutter)
    }

    private func mosaicCell<Icon: View>(_ color: Color, @ViewBuilder icon: () -> Icon = { EmptyView() }) -> some View {
        ZStack {
            color
            icon()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: CardSpace.mosaicRadius))
    }
}
