import SwiftUI
import UIKit

struct PlotTwistCard: View {
    var card: RunCard
    var onShare: () -> Void

    private var bars: [(label: String, fraction: CGFloat, strong: Bool)] {
        let values = card.payload.monthly ?? []
        let peak = CGFloat(values.max() ?? 0)
        let turn = card.payload.turnMonth ?? 1
        return values.enumerated().map { index, value in
            let label = index < MonthLabel.letters.count ? MonthLabel.letters[index] : ""
            let fraction = peak > 0 ? CGFloat(value) / peak : 0
            return (label, fraction, index + 1 >= turn)
        }
    }

    private var chartTitle: String {
        "\(card.payload.category ?? "") posts you liked and saved, by month"
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var grown = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            WrappedColor.igYellow.ignoresSafeArea().allowsHitTesting(false)
            VStack(alignment: .leading, spacing: CardSpace.plotGap) {
                CardText(
                    text: "One more thing",
                    size: CardSpace.eyebrowSize,
                    weight: CardSpace.strong,
                    width: CardSpace.regular,
                    tracking: CardSpace.eyebrowTracking,
                    color: WrappedColor.ink,
                    uppercase: true
                )
                DisplayHeadline(
                    copy: card.headline,
                    size: CardSpace.plotHeadline,
                    lineHeight: CardSpace.plotHeadlineLine,
                    tracking: CardSpace.plotHeadlineTracking,
                    color: WrappedColor.ink
                )
                CardText(
                    text: card.payload.sentence ?? "",
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
                    Text("Measured · likes and saves")
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
            Text(chartTitle)
                .font(ArchivoFont.font(size: CardSpace.plotChartTitle, weight: CardSpace.medium, width: CardSpace.regular))
                .foregroundStyle(WrappedColor.ink)
            HStack(alignment: .bottom, spacing: CardSpace.plotBarGap) {
                ForEach(Array(bars.enumerated()), id: \.offset) { _, bar in
                    RoundedRectangle(cornerRadius: CardSpace.plotBarRadius)
                        .fill(bar.strong ? WrappedColor.ink : WrappedColor.ink.opacity(CardSpace.barDim))
                        .frame(height: max(CardSpace.plotMinBar, CardSpace.plotChartHeight * bar.fraction * (grown ? 1 : 0)))
                }
            }
            .frame(height: CardSpace.plotChartHeight, alignment: .bottom)
            HStack(spacing: CardSpace.plotBarGap) {
                ForEach(Array(bars.enumerated()), id: \.offset) { _, bar in
                    Text(bar.label)
                        .font(ArchivoFont.font(size: CardSpace.plotLabel, weight: CardSpace.strong, width: CardSpace.regular))
                        .foregroundStyle(WrappedColor.ink)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(chartTitle)
    }
}

struct PersonalityTeaserCard: View {
    var card: RunCard
    var onReveal: () -> Void

    private var clues: [(index: String, text: String)] {
        (card.payload.copy?.clues ?? []).enumerated().map { index, text in
            (String(format: "%02d", index + 1), text)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            WrappedColor.ink.ignoresSafeArea().allowsHitTesting(false)
            VStack(alignment: .leading, spacing: CardSpace.yearCopyGap) {
                Eyebrow(text: "Before we tell you")
                DisplayHeadline(
                    copy: card.headline,
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
                ForEach(Array(clues.enumerated()), id: \.offset) { _, clue in
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
    var card: RunCard
    var onShare: () -> Void
    var onShareCards: () -> Void

    private var archetype: PersonalityArchetype {
        PersonalityArchetype(rawValue: card.payload.primary ?? "") ?? .curator
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false

    var body: some View {
        ZStack(alignment: .top) {
            WrappedColor.igMagenta.allowsHitTesting(false)
            VStack(spacing: CardSpace.chipGap) {
                mark
                CardText(
                    text: "Your Instagram personality",
                    size: CardSpace.eyebrowSize,
                    weight: CardSpace.strong,
                    width: CardSpace.regular,
                    tracking: CardSpace.eyebrowTracking,
                    color: WrappedColor.igWhite,
                    uppercase: true,
                    alignment: .center
                )
                DisplayHeadline(
                    copy: card.payload.copy?.name ?? "",
                    size: CardSpace.revealName,
                    lineHeight: CardSpace.revealNameLine,
                    tracking: CardSpace.revealNameTracking,
                    color: WrappedColor.igWhite,
                    alignment: .center
                )
                .scaleEffect(revealed ? 1 : WrappedMotion.revealStart)
                CardText(
                    text: card.payload.copy?.side ?? "",
                    size: CardSpace.revealSide,
                    weight: CardSpace.support,
                    width: CardSpace.regular,
                    color: WrappedColor.igWhite,
                    alignment: .center
                )
                VStack(spacing: CardSpace.chipGap) {
                    MatchBar(primary: CardSpace.primaryWidth)
                    HStack {
                        Text(card.payload.copy?.primaryMatch ?? "")
                        Spacer(minLength: 0)
                        Text(card.payload.copy?.secondaryMatch ?? "")
                    }
                    .font(ArchivoFont.font(size: CardSpace.plotChartTitle, weight: CardSpace.medium, width: CardSpace.regular))
                    .foregroundStyle(WrappedColor.igWhite)
                }
                .padding(.top, CardSpace.chipGap)
                HStack(alignment: .top, spacing: CardSpace.chipGap) {
                    ForEach(Array((card.payload.reasons ?? []).enumerated()), id: \.offset) { _, reason in
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
                SharePill(title: "Share your personality", expands: true, action: onShare)
                    .frame(maxWidth: .infinity)
                Button(action: onShareCards) {
                    Text("See your share cards")
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
            PersonalityMark(archetype: archetype, size: CardSpace.revealInner)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(archetype.accessibilityLabel)
    }
}

struct ShareCardsCard: View {
    var card: RunCard
    var reveal: RunCard
    var handle: String
    var onShare: (Bool) -> Void
    var onHub: () -> Void
    var startsOnNumbers: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var face: Int
    @State private var safeBottom: CGFloat = 0
    @State private var dockReserve: CGFloat = CardSpace.shareDock

    init(card: RunCard, reveal: RunCard, handle: String, onShare: @escaping (Bool) -> Void, onHub: @escaping () -> Void, startsOnNumbers: Bool = false) {
        self.card = card
        self.reveal = reveal
        self.handle = handle
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
                IdentityFace(card: card, reveal: reveal, handle: handle, bottomReserve: dockReserve)
                    .opacity(face == 0 ? 1 : 0)
                    .accessibilityElement(children: .ignore)
                    .accessibilityIdentifier("share-identity")
                    .accessibilityHidden(face != 0)
                    .allowsHitTesting(false)
                NumbersFace(card: card, handle: handle, bottomReserve: dockReserve)
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
            SharePill(title: "Share", identifier: "share-card") { onShare(face == 1) }
            Button(action: onHub) {
                Text("Go to your Hub")
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

struct IdentityFace: View {
    var card: RunCard
    var reveal: RunCard
    var handle: String
    var bottomReserve: CGFloat

    private var archetype: PersonalityArchetype {
        PersonalityArchetype(rawValue: reveal.payload.primary ?? "") ?? .curator
    }

    var body: some View {
        identityStack
    }

    private var identityStack: some View {
        VStack(spacing: CardSpace.chipGap) {
            HStack {
                Text("@\(handle)")
                Spacer(minLength: 0)
                Text(card.payload.copy?.identityYear ?? "")
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
                PersonalityMark(archetype: archetype, size: CardSpace.revealInner)
            }
            .frame(width: CardSpace.revealMark, height: CardSpace.revealMark)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(archetype.accessibilityLabel)

            CardText(
                text: "My Instagram personality",
                size: CardSpace.identityKicker,
                weight: CardSpace.strong,
                width: CardSpace.regular,
                tracking: CardSpace.identityKickerTracking,
                color: WrappedColor.igWhite,
                uppercase: true,
                alignment: .center
            )
            DisplayHeadline(
                copy: reveal.payload.copy?.name ?? "",
                size: CardSpace.identityName,
                lineHeight: CardSpace.identityNameLine,
                tracking: CardSpace.identityNameTracking,
                color: WrappedColor.igWhite,
                alignment: .center
            )
            Spacer(minLength: 0)
            HStack(alignment: .firstTextBaseline, spacing: CardSpace.yearCopyGap) {
                CardText(
                    text: card.payload.identity?.stat.value ?? "",
                    size: CardSpace.identityStat,
                    lineHeight: CardSpace.identityStatLine,
                    color: WrappedColor.igWhite
                )
                CardText(
                    text: card.payload.identity?.stat.label ?? "",
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
    var card: RunCard
    var handle: String
    var bottomReserve: CGFloat

    var body: some View {
        numbersStack
    }

    private var numbersStack: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: CardSpace.chipGap) {
                HStack {
                    Text("@\(handle)")
                    Spacer(minLength: 0)
                    Text(card.payload.copy?.identityYear ?? "")
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
                copy: card.payload.copy?.numbersTitle ?? "",
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
                ForEach(Array((card.payload.numbers?.stats ?? []).enumerated()), id: \.offset) { _, stat in
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
                    text: "Top interest",
                    size: CardSpace.numbersLabel,
                    weight: CardSpace.strong,
                    width: CardSpace.regular,
                    color: WrappedColor.ink
                )
                Spacer(minLength: 0)
                CardText(
                    text: card.payload.numbers?.topInterest ?? "",
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
                if let image = BundlePhoto.image(named: card.payload.numbers?.photo ?? "") {
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
        Text("INSTAGRAM.COM/WRAPPED")
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
