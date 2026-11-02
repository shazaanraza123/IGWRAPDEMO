import SwiftUI
import UIKit

struct MayaBar: Equatable {
    var label: String
    var fraction: CGFloat
    var strong: Bool
}

enum MayaPlot {
    static let eyebrow = "One more thing"
    static let headline = "PLOT\nTWIST."
    static let sentence = "In June you fell into ceramics and never climbed out."
    static let chartTitle = "Ceramics posts you liked and saved, by month"
    static let provenance = "Measured · likes and saves"
    static let bars: [MayaBar] = [
        MayaBar(label: "J", fraction: 3.0 / 80.0, strong: false),
        MayaBar(label: "F", fraction: 2.0 / 80.0, strong: false),
        MayaBar(label: "M", fraction: 4.0 / 80.0, strong: false),
        MayaBar(label: "A", fraction: 3.0 / 80.0, strong: false),
        MayaBar(label: "M", fraction: 5.0 / 80.0, strong: false),
        MayaBar(label: "J", fraction: 22.0 / 80.0, strong: true),
        MayaBar(label: "J", fraction: 41.0 / 80.0, strong: true),
        MayaBar(label: "A", fraction: 58.0 / 80.0, strong: true),
        MayaBar(label: "S", fraction: 64.0 / 80.0, strong: true),
        MayaBar(label: "O", fraction: 71.0 / 80.0, strong: true),
        MayaBar(label: "N", fraction: 80.0 / 80.0, strong: true)
    ]
}

enum MayaTeaser {
    static let eyebrow = "Before we tell you"
    static let headline = "THREE CLUES. ONE\nPERSONALITY."
    static let clues: [(index: String, text: String)] = [
        ("01", "You saved 1,214 posts"),
        ("02", "You posted 38 times all year"),
        ("03", "You watched 96% of friends\u{2019} Stories")
    ]
}

enum MayaReveal {
    static let eyebrow = "Your Instagram personality"
    static let name = "THE\nCURATOR"
    static let side = "with a side of The Ghost"
    static let primary = PersonalityArchetype.curator
    static let secondary = PersonalityArchetype.ghost
    static let primaryMatch = "70% Curator match"
    static let secondaryMatch = "30% Ghost match"
    static let reasons: [(value: String, label: String)] = [
        ("1,214", "posts saved"),
        ("38", "posts all year"),
        ("96%", "of friends\u{2019} Stories watched")
    ]
    static let shareTitle = "Share your personality"
    static let shareCards = "See your share cards"
}

enum MayaShare {
    static let handle = "@maya.lens"
    static let year = "MY 2026"
    static let eyebrow = "My Instagram personality"
    static let name = "THE\nCURATOR"
    static let statValue = "1,214"
    static let statLabel = "posts saved"
    static let photo = "year-card"
    static let numbersTitle = "2026 IN NUMBERS"
    static let stats: [(value: String, label: String)] = [
        ("412", "Stories"),
        ("38", "Posts"),
        ("1,206", "Reels sent"),
        ("1,214", "Saves")
    ]
    static let interestLabel = "Top interest"
    static let interest = "Streetwear"
    static let link = "INSTAGRAM.COM/WRAPPED"
    static let hub = "Go to your Hub"
}

struct PlotTwistCard: View {
    var onShare: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var grown = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            WrappedColor.igYellow.ignoresSafeArea().allowsHitTesting(false)
            VStack(alignment: .leading, spacing: CardSpace.plotGap) {
                CardText(
                    text: MayaPlot.eyebrow,
                    size: CardSpace.eyebrowSize,
                    weight: CardSpace.strong,
                    width: CardSpace.regular,
                    tracking: CardSpace.eyebrowTracking,
                    color: WrappedColor.ink,
                    uppercase: true
                )
                DisplayHeadline(
                    copy: MayaPlot.headline,
                    size: CardSpace.plotHeadline,
                    lineHeight: CardSpace.plotHeadlineLine,
                    tracking: CardSpace.plotHeadlineTracking,
                    color: WrappedColor.ink
                )
                CardText(
                    text: MayaPlot.sentence,
                    size: CardSpace.plotSentence,
                    weight: CardSpace.strong,
                    width: CardSpace.regular,
                    lineHeight: CardSpace.plotSentenceLine,
                    color: WrappedColor.ink
                )
                .frame(maxWidth: CardSpace.plotSentenceWidth, alignment: .leading)
                chart
                    .padding(.top, CardSpace.plotGap)
            }
            .allowsHitTesting(false)
            .padding(.horizontal, WrappedSpace.gutter)
            .padding(.top, WrappedSpace.contentTop)

            VStack {
                Spacer(minLength: 0).allowsHitTesting(false)
                HStack(spacing: CardSpace.blockGap) {
                    Text(MayaPlot.provenance)
                        .wrappedType(.caption)
                        .foregroundStyle(WrappedColor.ink)
                        .allowsHitTesting(false)
                    SharePill(action: onShare)
                }
                .padding(.horizontal, WrappedSpace.gutter)
                .padding(.bottom, WrappedSpace.pillBottomInset)
            }
        }
        .onAppear {
            guard !reduceMotion else {
                grown = true
                return
            }
            withAnimation(.easeInOut(duration: WrappedMotion.chartGrow)) {
                grown = true
            }
        }
    }

    private var chart: some View {
        VStack(alignment: .leading, spacing: CardSpace.chipGap) {
            Text(MayaPlot.chartTitle)
                .font(ArchivoFont.font(size: CardSpace.plotChartTitle, weight: CardSpace.medium, width: CardSpace.regular))
                .foregroundStyle(WrappedColor.ink)
            HStack(alignment: .bottom, spacing: CardSpace.plotBarGap) {
                ForEach(Array(MayaPlot.bars.enumerated()), id: \.offset) { _, bar in
                    RoundedRectangle(cornerRadius: CardSpace.plotBarRadius)
                        .fill(bar.strong ? WrappedColor.ink : WrappedColor.ink.opacity(CardSpace.barDim))
                        .frame(height: max(CardSpace.plotMinBar, CardSpace.plotChartHeight * bar.fraction * (grown ? 1 : 0)))
                }
            }
            .frame(height: CardSpace.plotChartHeight, alignment: .bottom)
            HStack(spacing: CardSpace.plotBarGap) {
                ForEach(Array(MayaPlot.bars.enumerated()), id: \.offset) { _, bar in
                    Text(bar.label)
                        .font(ArchivoFont.font(size: CardSpace.plotLabel, weight: CardSpace.strong, width: CardSpace.regular))
                        .foregroundStyle(WrappedColor.ink)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(MayaPlot.chartTitle)
    }
}

struct PersonalityTeaserCard: View {
    var onReveal: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            WrappedColor.ink.ignoresSafeArea().allowsHitTesting(false)
            VStack(alignment: .leading, spacing: CardSpace.yearCopyGap) {
                Eyebrow(text: MayaTeaser.eyebrow)
                DisplayHeadline(
                    copy: MayaTeaser.headline,
                    size: CardSpace.teaserHeadline,
                    lineHeight: CardSpace.teaserHeadlineLine,
                    tracking: CardSpace.teaserHeadlineTracking,
                    color: WrappedColor.igWhite
                )
            }
            .allowsHitTesting(false)
            .padding(.horizontal, WrappedSpace.gutter)
            .padding(.top, WrappedSpace.contentTop)

            orbit
                .allowsHitTesting(false)
                .padding(.top, CardSpace.teaserOrbitTop)

            VStack(spacing: CardSpace.clueGap) {
                ForEach(Array(MayaTeaser.clues.enumerated()), id: \.offset) { _, clue in
                    ClueRow(index: clue.index, text: clue.text)
                }
            }
            .allowsHitTesting(false)
            .padding(.horizontal, WrappedSpace.gutter)
            .padding(.top, CardSpace.clueTop)

            VStack {
                Spacer(minLength: 0).allowsHitTesting(false)
                Button(action: onReveal) {
                    HStack(spacing: CardSpace.yearCopyGap) {
                        Text("Reveal my personality")
                            .font(ArchivoFont.font(size: CardSpace.revealLabel, weight: CardSpace.heavy, width: CardSpace.regular))
                        Image(systemName: "arrow.right")
                            .font(.system(size: CardSpace.hintIcon, weight: .bold))
                    }
                    .foregroundStyle(WrappedColor.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: CardSpace.revealButton)
                    .background(Capsule().fill(WrappedColor.igWhite))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("reveal-personality")
                .padding(.horizontal, WrappedSpace.gutter)
                .padding(.bottom, WrappedSpace.pillBottomInset)
            }
        }
    }

    private var orbit: some View {
        ZStack {
            ForEach(Array(PersonalityArchetype.allCases.enumerated()), id: \.element) { index, archetype in
                let angle = (Double(index) / Double(PersonalityArchetype.allCases.count)) * Double.pi * 2 - Double.pi / 2
                let fill = archetype == .ghost ? WrappedColor.muted : archetype.field
                Circle()
                    .fill(fill)
                    .frame(width: CardSpace.orbitMark, height: CardSpace.orbitMark)
                    .opacity(CardSpace.orbitOpacity)
                    .offset(
                        x: CGFloat(cos(angle)) * CardSpace.orbitRadius,
                        y: CGFloat(sin(angle)) * CardSpace.orbitRadius
                    )
            }
            Circle()
                .stroke(
                    WrappedColor.igWhite,
                    style: StrokeStyle(
                        lineWidth: CardSpace.questionStroke,
                        dash: [CardSpace.questionDash, CardSpace.questionGap]
                    )
                )
                .frame(width: CardSpace.questionRing, height: CardSpace.questionRing)
            CardText(
                text: "?",
                size: CardSpace.questionSize,
                color: WrappedColor.igWhite
            )
        }
        .frame(width: CardSpace.teaserOrbit, height: CardSpace.teaserOrbit)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Eight dim personality marks circling a question mark")
    }
}

struct PersonalityRevealCard: View {
    var onShare: () -> Void
    var onShareCards: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false

    var body: some View {
        ZStack(alignment: .top) {
            WrappedColor.igMagenta.allowsHitTesting(false)
            VStack(spacing: CardSpace.chipGap) {
                mark
                CardText(
                    text: MayaReveal.eyebrow,
                    size: CardSpace.eyebrowSize,
                    weight: CardSpace.strong,
                    width: CardSpace.regular,
                    tracking: CardSpace.eyebrowTracking,
                    color: WrappedColor.igWhite,
                    uppercase: true,
                    alignment: .center
                )
                DisplayHeadline(
                    copy: MayaReveal.name,
                    size: CardSpace.revealName,
                    lineHeight: CardSpace.revealNameLine,
                    tracking: CardSpace.revealNameTracking,
                    color: WrappedColor.igWhite,
                    alignment: .center
                )
                .scaleEffect(revealed ? 1 : WrappedMotion.revealStart)
                CardText(
                    text: MayaReveal.side,
                    size: CardSpace.revealSide,
                    weight: CardSpace.support,
                    width: CardSpace.regular,
                    color: WrappedColor.igWhite,
                    alignment: .center
                )
                VStack(spacing: CardSpace.chipGap) {
                    MatchBar(primary: CardSpace.primaryWidth)
                    HStack {
                        Text(MayaReveal.primaryMatch)
                        Spacer(minLength: 0)
                        Text(MayaReveal.secondaryMatch)
                    }
                    .font(ArchivoFont.font(size: CardSpace.plotChartTitle, weight: CardSpace.medium, width: CardSpace.regular))
                    .foregroundStyle(WrappedColor.igWhite)
                }
                .padding(.top, CardSpace.chipGap)
                HStack(alignment: .top, spacing: CardSpace.chipGap) {
                    ForEach(Array(MayaReveal.reasons.enumerated()), id: \.offset) { _, reason in
                        VStack(alignment: .leading, spacing: CardSpace.reasonGap) {
                            CardText(
                                text: reason.value,
                                size: CardSpace.reasonValue,
                                width: CardSpace.titleWidth,
                                color: WrappedColor.igWhite
                            )
                            CardText(
                                text: reason.label,
                                size: CardSpace.reasonLabel,
                                weight: CardSpace.support,
                                width: CardSpace.regular,
                                lineHeight: CardSpace.reasonLine,
                                color: WrappedColor.igWhite
                            )
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, CardSpace.chipGap)
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(WrappedColor.ink)
                                .frame(height: CardSpace.reasonRule)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .allowsHitTesting(false)
            .padding(.horizontal, CardSpace.identityInset)
            .padding(.top, WrappedSpace.contentTop)
            .padding(.bottom, CardSpace.shareDock)

            VStack(spacing: WrappedSpace.gridGap) {
                Spacer(minLength: 0).allowsHitTesting(false)
                SharePill(title: MayaReveal.shareTitle, expands: true, action: onShare)
                    .frame(maxWidth: .infinity)
                Button(action: onShareCards) {
                    Text(MayaReveal.shareCards)
                        .font(ArchivoFont.font(size: CardSpace.footerLink, weight: CardSpace.medium, width: CardSpace.regular))
                        .foregroundStyle(WrappedColor.igWhite)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: WrappedSpace.minHit)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("see-share-cards")
            }
            .padding(.horizontal, WrappedSpace.gutter)
            .padding(.bottom, WrappedSpace.pillBottomInset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            guard !reduceMotion else {
                revealed = true
                return
            }
            withAnimation(.easeInOut(duration: WrappedMotion.revealSpin)) {
                revealed = true
            }
        }
    }

    private var mark: some View {
        ZStack {
            Circle()
                .stroke(
                    WrappedColor.ink,
                    style: StrokeStyle(
                        lineWidth: CardSpace.revealRing,
                        dash: [CardSpace.revealDash, CardSpace.revealDashGap]
                    )
                )
                .frame(width: CardSpace.revealMark, height: CardSpace.revealMark)
                .rotationEffect(.degrees(revealed ? 360 : 0))
            Circle()
                .fill(WrappedColor.ink)
                .frame(width: CardSpace.revealInner, height: CardSpace.revealInner)
            PersonalityMark(archetype: MayaReveal.primary, size: CardSpace.revealInner)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(MayaReveal.primary.accessibilityLabel)
    }
}

struct ShareCardsCard: View {
    var onShare: () -> Void
    var onHub: () -> Void
    var startsOnNumbers: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var face: Int
    @State private var safeBottom: CGFloat = 0
    @State private var dockReserve: CGFloat = CardSpace.shareDock

    init(onShare: @escaping () -> Void, onHub: @escaping () -> Void, startsOnNumbers: Bool = false) {
        self.onShare = onShare
        self.onHub = onHub
        self.startsOnNumbers = startsOnNumbers
        _face = State(initialValue: startsOnNumbers ? 1 : 0)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                shareField
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                IdentityFace(bottomReserve: dockReserve)
                    .opacity(face == 0 ? 1 : 0)
                    .accessibilityElement(children: .ignore)
                    .accessibilityIdentifier("share-identity")
                    .accessibilityHidden(face != 0)
                    .allowsHitTesting(false)
                NumbersFace(bottomReserve: dockReserve)
                    .opacity(face == 1 ? 1 : 0)
                    .accessibilityElement(children: .ignore)
                    .accessibilityIdentifier("share-numbers")
                    .accessibilityHidden(face != 1)
                    .allowsHitTesting(false)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .overlay(alignment: .bottom) { dock }
        }
        .onPreferenceChange(ShareDockHeightKey.self) { height in
            if height > 0, abs(height - dockReserve) > 0.5 {
                dockReserve = height
            }
        }
        .animation(crossfade, value: face)
    }

    private var dock: some View {
        VStack(spacing: CardSpace.dockGap) {
            SegmentedToggle(
                options: ["Identity card", "Numbers card"],
                selection: $face
            )
            SharePill(title: "Share", identifier: "share-card", action: onShare)
            Button(action: onHub) {
                Text(MayaShare.hub)
                    .font(ArchivoFont.font(size: CardSpace.footerLink, weight: CardSpace.strong, width: CardSpace.regular))
                    .foregroundStyle(face == 0 ? WrappedColor.igWhite : WrappedColor.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: WrappedSpace.minHit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("go-to-hub")
        }
        .padding(.horizontal, WrappedSpace.gutter)
        .padding(.bottom, safeBottom + CardSpace.dockBottom)
        .background {
            WindowSafeBottom { bottom in
                if abs(bottom - safeBottom) > 0.5 {
                    safeBottom = bottom
                }
            }
        }
        .background {
            GeometryReader { geo in
                Color.clear.preference(key: ShareDockHeightKey.self, value: geo.size.height)
            }
        }
    }

    private var shareField: some View {
        ZStack(alignment: .top) {
            WrappedColor.paper
            WrappedColor.igMagenta.opacity(face == 0 ? 1 : 0)
            WrappedColor.igPink
                .frame(maxWidth: .infinity)
                .frame(height: CardSpace.numbersHeader)
                .opacity(face == 1 ? 1 : 0)
        }
    }

    private var crossfade: Animation {
        reduceMotion
            ? .easeOut(duration: WrappedMotion.reduceMotion)
            : .easeInOut(duration: WrappedMotion.shareCrossfade)
    }
}

private struct IdentityFace: View {
    var bottomReserve: CGFloat

    var body: some View {
        identityStack
    }

    private var identityStack: some View {
        VStack(spacing: CardSpace.chipGap) {
            HStack {
                Text(MayaShare.handle)
                Spacer(minLength: 0)
                Text(MayaShare.year)
            }
            .font(ArchivoFont.font(size: CardSpace.shareSize, weight: CardSpace.strong, width: CardSpace.regular))
            .foregroundStyle(WrappedColor.igWhite)
            .padding(.top, WrappedSpace.contentTop)

            ZStack {
                Circle()
                    .stroke(
                        WrappedColor.ink,
                        style: StrokeStyle(
                            lineWidth: CardSpace.revealRing,
                            dash: [CardSpace.revealDash, CardSpace.revealDashGap]
                        )
                    )
                Circle().fill(WrappedColor.ink).padding(CardSpace.revealRing)
                PersonalityMark(archetype: MayaReveal.primary, size: CardSpace.revealInner)
            }
            .frame(width: CardSpace.revealMark, height: CardSpace.revealMark)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(MayaReveal.primary.accessibilityLabel)

            CardText(
                text: MayaShare.eyebrow,
                size: CardSpace.identityKicker,
                weight: CardSpace.strong,
                width: CardSpace.regular,
                tracking: CardSpace.identityKickerTracking,
                color: WrappedColor.igWhite,
                uppercase: true,
                alignment: .center
            )
            DisplayHeadline(
                copy: MayaShare.name,
                size: CardSpace.identityName,
                lineHeight: CardSpace.identityNameLine,
                tracking: CardSpace.identityNameTracking,
                color: WrappedColor.igWhite,
                alignment: .center
            )
            Spacer(minLength: 0)
            HStack(alignment: .firstTextBaseline, spacing: CardSpace.yearCopyGap) {
                CardText(
                    text: MayaShare.statValue,
                    size: CardSpace.identityStat,
                    lineHeight: CardSpace.identityStatLine,
                    color: WrappedColor.igWhite
                )
                CardText(
                    text: MayaShare.statLabel,
                    size: CardSpace.identityCaption,
                    weight: CardSpace.strong,
                    width: CardSpace.regular,
                    color: WrappedColor.igWhite
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.top, CardSpace.stickerPadH)
            .overlay(alignment: .top) {
                Rectangle().fill(WrappedColor.ink).frame(height: CardSpace.identityRule)
            }
            cardFooter(markBorder: WrappedColor.igMagenta, word: WrappedColor.igWhite)
        }
        .padding(.horizontal, CardSpace.identityInset)
        .padding(.bottom, bottomReserve)
    }
}

private struct NumbersFace: View {
    var bottomReserve: CGFloat

    var body: some View {
        numbersStack
    }

    private var numbersStack: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: CardSpace.chipGap) {
                HStack {
                    Text(MayaShare.handle)
                    Spacer(minLength: 0)
                    Text(MayaShare.year)
                }
                .font(ArchivoFont.font(size: CardSpace.shareSize, weight: CardSpace.strong, width: CardSpace.regular))
                .foregroundStyle(WrappedColor.igWhite)
                .padding(.top, WrappedSpace.topRowMaxY)
                photo
            }
            .padding(.horizontal, CardSpace.identityInset)
            .frame(maxWidth: .infinity)
            .frame(height: CardSpace.numbersHeader, alignment: .top)

            DisplayHeadline(
                copy: MayaShare.numbersTitle,
                size: CardSpace.numbersTitle,
                lineHeight: CardSpace.numbersTitleLine,
                tracking: CardSpace.algorithmHeadlineTracking,
                color: WrappedColor.ink
            )
            .padding(.horizontal, CardSpace.identityInset)
            .padding(.top, CardSpace.identityInset)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: CardSpace.numbersColumn),
                    GridItem(.flexible(), spacing: CardSpace.numbersColumn)
                ],
                spacing: CardSpace.openingSupport
            ) {
                ForEach(Array(MayaShare.stats.enumerated()), id: \.offset) { _, stat in
                    VStack(alignment: .leading, spacing: CardSpace.reasonGap) {
                        CardText(
                            text: stat.value,
                            size: CardSpace.numbersValue,
                            lineHeight: CardSpace.numbersValueLine,
                            color: WrappedColor.ink
                        )
                        CardText(
                            text: stat.label,
                            size: CardSpace.numbersLabel,
                            weight: CardSpace.strong,
                            width: CardSpace.regular,
                            color: WrappedColor.ink
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, CardSpace.chipGap)
                    .overlay(alignment: .top) {
                        Rectangle().fill(WrappedColor.ink).frame(height: CardSpace.identityRule)
                    }
                }
            }
            .padding(.horizontal, CardSpace.identityInset)
            .padding(.top, CardSpace.openingSupport)

            HStack(alignment: .firstTextBaseline) {
                CardText(
                    text: MayaShare.interestLabel,
                    size: CardSpace.numbersLabel,
                    weight: CardSpace.strong,
                    width: CardSpace.regular,
                    color: WrappedColor.ink
                )
                Spacer(minLength: 0)
                CardText(
                    text: MayaShare.interest,
                    size: CardSpace.numbersInterest,
                    color: WrappedColor.ink,
                    uppercase: true
                )
            }
            .padding(.top, CardSpace.yearCopyGap)
            .overlay(alignment: .top) {
                Rectangle().fill(WrappedColor.ink).frame(height: CardSpace.identityRule)
            }
            .padding(.horizontal, CardSpace.identityInset)
            .padding(.top, CardSpace.openingSupport)

            Spacer(minLength: 0)
            cardFooter(markBorder: WrappedColor.paper, word: WrappedColor.ink)
                .padding(.horizontal, CardSpace.identityInset)
                .padding(.bottom, bottomReserve)
        }
    }

    private var photo: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            WrappedColor.igYellow,
                            WrappedColor.igOrange,
                            WrappedColor.igViolet,
                            WrappedColor.igYellow
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: CardSpace.numbersRing, dash: [CardSpace.numbersDash, CardSpace.numbersGap])
                )
                .frame(width: CardSpace.numbersRingBox, height: CardSpace.numbersRingBox)
            Group {
                if let image = BundlePhoto.image(named: MayaShare.photo) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    MonthTone.gradient(2)
                }
            }
            .frame(width: CardSpace.numbersPhoto, height: CardSpace.numbersPhoto)
            .clipShape(Circle())
            .overlay(Circle().stroke(WrappedColor.igPink, lineWidth: CardSpace.openingBadgeBorder))
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Your photo of the year")
    }
}

private func cardFooter(markBorder: Color, word: Color) -> some View {
    HStack {
        HStack(spacing: CardSpace.chipGap) {
            ZStack {
                Circle().fill(WrappedColor.igWhite)
                Circle().fill(WrappedColor.ink).padding(CardSpace.footerRingPad)
                Circle().stroke(markBorder, lineWidth: CardSpace.ringWidth).padding(CardSpace.footerRingPad)
                Text("26")
                    .font(ArchivoFont.font(size: CardSpace.markDigits, weight: CardSpace.heavy, width: CardSpace.regular))
                    .foregroundStyle(WrappedColor.igWhite)
            }
            .frame(width: CardSpace.footerMark, height: CardSpace.footerMark)
            Text("Wrapped")
                .font(ArchivoFont.font(size: CardSpace.footerWord, weight: CardSpace.heavy, width: CardSpace.regular))
                .foregroundStyle(word)
        }
        Spacer(minLength: 0)
        Text(MayaShare.link)
            .font(ArchivoFont.font(
                size: CardSpace.footerLink,
                weight: CardSpace.strong,
                width: CardSpace.regular
            ))
            .tracking(CardSpace.footerLinkTracking)
            .foregroundStyle(word)
    }
}

private struct ShareDockHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// The shell ignores the safe area, so the dock reads the window inset directly.
private struct WindowSafeBottom: UIViewRepresentable {
    var onChange: (CGFloat) -> Void

    func makeUIView(context: Context) -> Probe {
        let view = Probe()
        view.onChange = onChange
        return view
    }

    func updateUIView(_ uiView: Probe, context: Context) {
        uiView.onChange = onChange
        uiView.report()
    }

    final class Probe: UIView {
        var onChange: (CGFloat) -> Void = { _ in }
        private var reported = CGFloat.greatestFiniteMagnitude

        override func didMoveToWindow() {
            super.didMoveToWindow()
            report()
        }

        override func safeAreaInsetsDidChange() {
            super.safeAreaInsetsDidChange()
            report()
        }

        func report() {
            let bottom = window?.safeAreaInsets.bottom ?? safeAreaInsets.bottom
            guard abs(bottom - reported) > 0.5 else { return }
            reported = bottom
            DispatchQueue.main.async { [onChange] in
                onChange(bottom)
            }
        }
    }
}
