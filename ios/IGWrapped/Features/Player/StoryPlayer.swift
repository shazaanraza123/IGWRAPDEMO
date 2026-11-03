import SwiftUI
import UIKit

struct StoryPlayer: View {
    var onHub: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model: StoryPlayerModel
    @State private var showsInfo = false
    @State private var showsShare = false
    @State private var shareCard = 13
    @State private var shareNumbers = false
    @State private var isMuted = false
    @State private var dismissDrag: CGFloat = 0
    @State private var chapterDrag: CGFloat = 0
    @State private var openMonth: MonthFace?
    @State private var showsMontage = false
    @State private var showsPost = false
    @State private var showsStory = false
    @State private var revealPulse = 0
    private let startsOnNumbers: Bool
    private let deck: RunBundle
    private let audio = AudioService.shared

    init(onHub: @escaping () -> Void, bundle: RunBundle? = nil, omitted: Set<Int> = [], startCard: Int? = nil) {
        self.onHub = onHub
        let arguments = ProcessInfo.processInfo.arguments
        let resolved: RunBundle
        if let bundle {
            resolved = bundle
        } else if arguments.contains("--teen") {
            resolved = (try? RunBundle.load(named: "maya-teen")) ?? .empty
        } else {
            resolved = (try? RunBundle.load(named: "maya")) ?? .empty
        }
        deck = resolved
        var model = StoryPlayerModel()
        if !resolved.cards.isEmpty {
            model.included = resolved.deckNumbers
        }
        if let flag = arguments.firstIndex(of: "--player-card"),
           flag + 1 < arguments.count,
           let number = Int(arguments[flag + 1]),
           (1 ... StoryPlayerModel.cardCount).contains(number) {
            model.card = number
        }
        if let startCard, (1 ... StoryPlayerModel.cardCount).contains(startCard) {
            model.card = startCard
        }
        if arguments.contains("--player-paused") {
            model.autoplay = false
        }
        if bundle == nil, arguments.contains("--teen") {
            model.omitted = []
        } else {
            model.omitted = omitted
        }
        model.omitted.formUnion(HiddenCards.load())
        if !model.sequence.contains(model.card), let fallback = model.sequence.first {
            model.card = fallback
        }
        startsOnNumbers = arguments.contains("--numbers")
        _model = State(initialValue: model)
    }

    var body: some View {
        ZStack(alignment: .top) {
            PlayerGestureSurface(
                onTap: { fraction in
                    var step = PlayerAdvance.same
                    withAnimation(cardAnimation) {
                        step = model.tap(xFraction: fraction)
                    }
                    if step == .finished {
                        exit()
                    }
                },
                onHoldBegan: {
                    model.isHolding = true
                    model.clearToast()
                },
                onHoldEnded: {
                    model.isHolding = false
                },
                onPanChanged: { dx, dy in
                    follow(dx: dx, dy: dy)
                },
                onPanEnded: { dx, dy, velocityX, velocityY in
                    resolve(dx: dx, dy: dy, velocityX: velocityX, velocityY: velocityY)
                }
            )
            .accessibilityHidden(true)
            cube
            chrome
            if let openMonth {
                MonthCover(month: openMonth) {
                    self.openMonth = nil
                }
            }
            if showsMontage, montageReady, let yearCard {
                YearMontage(card: yearCard) {
                    showsMontage = false
                }
            }
            if showsPost {
                PostDetailCover(card: faceCard(6), handle: deck.card(number: 1)?.payload.handle ?? "") { showsPost = false }
            }
            if showsStory {
                StoryReplayCover(card: faceCard(7)) { showsStory = false }
            }
            if let toast = model.toast {
                Text(toast)
                    .wrappedType(.caption)
                    .foregroundStyle(WrappedColor.ink)
                    .padding(.horizontal, WrappedSpace.gutter)
                    .frame(minHeight: WrappedSpace.minHit)
                    .background(Capsule().fill(WrappedColor.igWhite))
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, WrappedSpace.pillBottomInset + WrappedSpace.pillHeight)
                    .allowsHitTesting(false)
                    .accessibilityIdentifier("player-toast")
            }
            referenceOverlay
        }
        .scaleEffect(dismissScale, anchor: .center)
        .offset(y: dismissDrag)
        .onAppear {
            audio.play(model.chapter)
        }
        .onChange(of: model.chapter) { _, chapter in
            audio.play(chapter)
        }
        .onChange(of: model.isHolding) { _, holding in
            if holding {
                audio.pause()
            } else if !model.infoOpen {
                audio.resume()
            }
        }
        .onChange(of: showsInfo) { _, open in
            model.infoOpen = open
            if open {
                model.clearToast()
                audio.pause()
            } else if !model.isHolding && !model.shareOpen {
                audio.resume()
            }
        }
        .onChange(of: showsShare) { _, open in
            model.shareOpen = open
            if open {
                model.clearToast()
                audio.pause()
            } else if !model.isHolding && !model.infoOpen {
                audio.resume()
            }
        }
        .onChange(of: openMonth) { _, _ in
            syncCover()
        }
        .onChange(of: showsMontage) { _, playing in
            syncCover()
            audio.setDucked(playing)
        }
        .onChange(of: showsPost) { _, _ in syncCover() }
        .onChange(of: showsStory) { _, _ in syncCover() }
        .sensoryFeedback(.success, trigger: revealPulse)
        .task { await runClock() }
        .sheet(isPresented: $showsInfo) {
            CardInfoSheet(
                metrics: deck.metrics(for: faceCard(model.card)),
                onLooksWrong: { reason in
                    let code = faceCard(model.card).code
                    showsInfo = false
                    Task {
                        guard await FeedbackStore.shared.reportLooksWrong(card: code, reason: reason) else { return }
                        showToast("Thanks. We'll check it.")
                    }
                },
                onHide: {
                    showsInfo = false
                    hideCurrentCard()
                }
            )
        }
        .sheet(isPresented: $showsShare) {
            ShareSheet(bundle: deck, openedFrom: shareCard, preferNumbers: shareNumbers) { message in
                showToast(message)
            }
        }
    }

    private var cube: some View {
        ZStack {
            if chapterDrag < 0, let next = model.chapter.next {
                face(next.firstCard, angle: cubeAngle + 90)
            }
            if chapterDrag > 0, let previous = model.chapter.previous {
                face(previous.firstCard, angle: cubeAngle - 90)
            }
            face(model.card, angle: cubeAngle, labeled: true)
        }
    }

    private var yearCard: RunCard? { deck.card(number: 2) }

    private var montageReady: Bool {
        MontageGate.ready(yearCard?.payload.months ?? [])
    }

    private func faceCard(_ number: Int) -> RunCard {
        deck.card(number: number) ?? .placeholder(type: "card", number: number)
    }

    private var cubeAngle: Double {
        Double(chapterDrag / WrappedSpace.frameWidth) * 90
    }

    private func face(_ card: Int, angle: Double, labeled: Bool = false) -> some View {
        ZStack {
            cardFill(card)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .modifier(PlayerCardAccess(
                    labeled: labeled,
                    label: "Card \(model.sequenceIndex + 1) of \(model.sequence.count)",
                    summary: CardVoice.summary(bundle: deck, card: card),
                    onNext: { step(model.goForward()) },
                    onPrevious: { step(model.goBack()) },
                    onMagicTap: { model.isHolding.toggle() },
                    onEscape: exit
                ))
            cardContent(card)
        }
        .modifier(CubeFace(angle: reduceMotion ? 0 : angle))
    }

    private func cardFill(_ card: Int) -> Color {
        switch card {
        case 1: WrappedColor.igPink
        case 2: WrappedColor.ink
        case 3: WrappedColor.paper
        case 4: WrappedColor.igViolet
        case 5, 8: WrappedColor.igOrange
        case 6: WrappedColor.igYellow
        case 7: WrappedColor.closeGreen
        case 9: WrappedColor.nightNavy
        case 12: WrappedColor.igMagenta
        case 13: WrappedColor.paper
        default: Chapter.containing(card).field
        }
    }

    @ViewBuilder
    private func cardContent(_ card: Int) -> some View {
        switch card {
        case 1:
            OpeningCard(card: faceCard(1), year: deck.run.year) {
                withAnimation(cardAnimation) { step(model.goForward()) }
            }
        case 2:
            YearMemoriesCard(
                card: faceCard(2),
                onMonth: { openMonth = $0 },
                onPlay: {
                    guard montageReady else { return }
                    showsMontage = true
                }
            )
        case 3:
            FeedColorCard(card: faceCard(3), onShare: { openShare(from: 3) })
        case 4:
            AlgorithmCard(
                card: faceCard(4),
                onShare: { openShare(from: 4) },
                onSaved: { showToast("Got it. We'll tune Explore.") }
            )
        case 5:
            ReelsCard(card: faceCard(5), onShare: { openShare(from: 5) })
        case 6:
            MainCharacterCard(
                card: faceCard(6),
                handle: deck.card(number: 1)?.payload.handle ?? "",
                onShare: { openShare(from: 6) },
                onOpenPost: { showsPost = true }
            )
        case 7:
            GroupChatCard(
                card: faceCard(7),
                onShare: { openShare(from: 7) },
                onOpenStory: { showsStory = true }
            )
        case 8:
            CircleCard(card: faceCard(8))
        case 9:
            ThreeAMCard(card: faceCard(9), onShare: { openShare(from: 9) })
        case 10:
            PlotTwistCard(card: faceCard(10), onShare: { openShare(from: 10) })
        case 11:
            PersonalityTeaserCard(card: faceCard(11), onReveal: revealPersonality)
        case 12:
            PersonalityRevealCard(
                card: faceCard(12),
                onShare: { openShare(from: 12) },
                onShareCards: {
                    withAnimation(cardAnimation) { step(model.goForward()) }
                }
            )
        case 13:
            ShareCardsCard(
                card: faceCard(13),
                reveal: faceCard(12),
                handle: deck.card(number: 1)?.payload.handle ?? "",
                onShare: { numbers in openShare(from: 13, numbers: numbers) },
                onHub: { exit() },
                startsOnNumbers: startsOnNumbers
            )
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var referenceOverlay: some View {
        if let name = referenceName, let image = UIImage(named: name) {
            GeometryReader { geo in
                Image(uiImage: image)
                    .resizable()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .opacity(0.5)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private var referenceName: String? {
        guard !Pitch.active, ProcessInfo.processInfo.arguments.contains("--reference") else { return nil }
        switch model.card {
        case 1: return "01-opening"
        case 2: return "02-year-in-memories"
        case 3: return "03-feed-color"
        case 4: return "04-your-algorithm"
        case 5: return "05-reels-rabbit-hole"
        case 6: return "06-main-character-post"
        case 7: return "07-broke-the-group-chat"
        case 8: return "08-your-circle"
        case 9: return "09-3am-club"
        case 10: return "10-plot-twist"
        case 11: return "11-personality-teaser"
        case 12: return "12-personality-reveal"
        case 13:
            return ProcessInfo.processInfo.arguments.contains("--numbers")
                ? "13b-numbers-card"
                : "13a-identity-card"
        default: return nil
        }
    }

    private func revealPersonality() {
        revealPulse += 1
        withAnimation(cardAnimation) {
            step(model.reveal())
        }
    }

    private func step(_ advance: PlayerAdvance) {
        if advance == .finished {
            exit()
        }
    }

    private var chrome: some View {
        let style = CardChrome.forCard(model.card)
        return VStack(spacing: CardSpace.chromeGap) {
            StoryProgressBars(
                count: model.sequence.count,
                current: model.sequenceIndex,
                progress: model.fraction,
                foreground: style.foreground,
                trackOpacity: style.trackOpacity
            )
            WrappedTopRow(
                showsInfo: model.showsInfoButton,
                isMuted: isMuted,
                foreground: style.foreground,
                mark: style.mark,
                innerBorder: style.innerBorder,
                outerFill: style.outerFill,
                onInfo: { showsInfo = true },
                onMute: toggleMute,
                onClose: exit
            )
        }
        .padding(.top, WrappedSpace.progressTop)
        .padding(.leading, CardSpace.chromeLeading)
        .padding(.trailing, CardSpace.chromeTrailing)
        .opacity(model.isHolding ? 0 : 1)
        .accessibilityHidden(model.isHolding)
        .allowsHitTesting(!model.isHolding)
        .animation(.easeOut(duration: WrappedMotion.reduceMotion), value: model.isHolding)
    }

    private var dismissScale: CGFloat {
        if reduceMotion { return 1 }
        let progress = min(max(dismissDrag, 0) / IGSpace.viewerDismissTravel, 1)
        return 1 - progress * (1 - IGSpace.viewerDismissScale)
    }

    private var cardAnimation: Animation {
        reduceMotion
            ? .easeOut(duration: WrappedMotion.reduceMotion)
            : .spring(response: WrappedMotion.cardEnterResponse, dampingFraction: WrappedMotion.cardEnterDamping)
    }

    private func follow(dx: CGFloat, dy: CGFloat) {
        guard max(abs(dx), abs(dy)) > IGSpace.viewerDragMinimum else { return }
        if abs(dx) > abs(dy) {
            dismissDrag = 0
            chapterDrag = dx
        } else if dy > 0 {
            chapterDrag = 0
            dismissDrag = dy
        }
    }

    private func resolve(dx: CGFloat, dy: CGFloat, velocityX: CGFloat, velocityY: CGFloat) {
        switch model.dragEnded(dx: dx, dy: dy, velocityX: velocityX, velocityY: velocityY) {
        case .tap:
            break
        case .dismiss:
            finishDismiss()
        case .info:
            cancelDrag()
            showsInfo = true
        case .nextChapter:
            finishChapter(forward: true)
        case .previousChapter:
            finishChapter(forward: false)
        case .cancel:
            cancelDrag()
        }
    }

    private func finishChapter(forward: Bool) {
        let target = forward ? model.chapter.next : model.chapter.previous
        guard target != nil else {
            cancelDrag()
            return
        }
        if reduceMotion {
            withAnimation(cardAnimation) {
                _ = model.jumpChapter(forward: forward)
                chapterDrag = 0
            }
            return
        }
        let distance = forward ? -WrappedSpace.frameWidth : WrappedSpace.frameWidth
        withAnimation(.spring(response: WrappedMotion.cardEnterResponse, dampingFraction: WrappedMotion.cardEnterDamping)) {
            chapterDrag = distance
        } completion: {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                _ = model.jumpChapter(forward: forward)
                chapterDrag = 0
            }
        }
    }

    private func finishDismiss() {
        model.clearToast()
        let duration = reduceMotion ? WrappedMotion.reduceMotion : IGSpace.viewerDismiss
        withAnimation(.easeIn(duration: duration)) {
            dismissDrag = WrappedSpace.frameHeight
        }
        Task {
            try? await Task.sleep(for: .seconds(duration))
            exit()
        }
    }

    private func cancelDrag() {
        withAnimation(.easeOut(duration: IGSpace.viewerOpen)) {
            dismissDrag = 0
            chapterDrag = 0
        }
    }

    private func toggleMute() {
        isMuted.toggle()
        audio.setMuted(isMuted)
    }

    private func syncCover() {
        model.coverOpen = openMonth != nil || showsMontage || showsPost || showsStory
    }

    private func openShare(from card: Int, numbers: Bool = false) {
        shareCard = card
        shareNumbers = numbers
        showsShare = true
    }

    private func showUnavailable(_ feature: Feature) {
        guard let message = Feature.toast(for: feature) else { return }
        showToast(message)
    }

    private func hideCurrentCard() {
        let hidden = model.card
        HiddenCards.hide(hidden)
        model.omitted.insert(hidden)
        model.elapsed = 0
        if model.sequence.contains(hidden) { return }
        if let next = model.sequence.first(where: { $0 > hidden }) {
            model.card = next
        } else if let previous = model.sequence.last {
            model.card = previous
        }
    }

    private func showToast(_ message: String) {
        let generation = model.showToast(message)
        Task {
            try? await Task.sleep(for: .seconds(StoryPlayerModel.toastLifetime))
            model.expireToast(generation: generation)
        }
    }

    private func exit() {
        audio.setDucked(false)
        audio.stop()
        PlayerProgressStore.save(PlayerProgress(card: model.card, elapsed: model.elapsed))
        onHub()
    }

    private func runClock() async {
        var last = Date()
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(WrappedMotion.clockTick))
            let now = Date()
            let delta = now.timeIntervalSince(last)
            last = now
            let step = model.tick(delta: delta)
            if step == .finished {
                exit()
                return
            }
        }
    }
}

private struct PlayerGestureSurface: UIViewRepresentable {
    var onTap: (CGFloat) -> Void
    var onHoldBegan: () -> Void
    var onHoldEnded: () -> Void
    var onPanChanged: (CGFloat, CGFloat) -> Void
    var onPanEnded: (CGFloat, CGFloat, CGFloat, CGFloat) -> Void

    func makeUIView(context: Context) -> PlayerGestureView {
        let view = PlayerGestureView()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.isAccessibilityElement = false
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped(_:)))
        let hold = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.held(_:)))
        hold.minimumPressDuration = 0.2
        hold.allowableMovement = IGSpace.viewerDragMinimum
        tap.require(toFail: hold)
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.panned(_:)))
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(hold)
        view.addGestureRecognizer(pan)
        return view
    }

    func updateUIView(_ uiView: PlayerGestureView, context: Context) {
        context.coordinator.onTap = onTap
        context.coordinator.onHoldBegan = onHoldBegan
        context.coordinator.onHoldEnded = onHoldEnded
        context.coordinator.onPanChanged = onPanChanged
        context.coordinator.onPanEnded = onPanEnded
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: PlayerGestureView, context: Context) -> CGSize? {
        CGSize(
            width: proposal.width ?? WrappedSpace.frameWidth,
            height: proposal.height ?? WrappedSpace.frameHeight
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onTap: onTap,
            onHoldBegan: onHoldBegan,
            onHoldEnded: onHoldEnded,
            onPanChanged: onPanChanged,
            onPanEnded: onPanEnded
        )
    }

    @MainActor
    final class Coordinator: NSObject {
        var onTap: (CGFloat) -> Void
        var onHoldBegan: () -> Void
        var onHoldEnded: () -> Void
        var onPanChanged: (CGFloat, CGFloat) -> Void
        var onPanEnded: (CGFloat, CGFloat, CGFloat, CGFloat) -> Void
        private var holding = false

        init(
            onTap: @escaping (CGFloat) -> Void,
            onHoldBegan: @escaping () -> Void,
            onHoldEnded: @escaping () -> Void,
            onPanChanged: @escaping (CGFloat, CGFloat) -> Void,
            onPanEnded: @escaping (CGFloat, CGFloat, CGFloat, CGFloat) -> Void
        ) {
            self.onTap = onTap
            self.onHoldBegan = onHoldBegan
            self.onHoldEnded = onHoldEnded
            self.onPanChanged = onPanChanged
            self.onPanEnded = onPanEnded
        }

        @objc func tapped(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view, view.bounds.width > 0 else { return }
            let point = gesture.location(in: view)
            onTap(point.x / view.bounds.width)
        }

        @objc func held(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began {
                holding = true
                onHoldBegan()
            } else if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
                if holding {
                    holding = false
                    onHoldEnded()
                }
            }
        }

        @objc func panned(_ gesture: UIPanGestureRecognizer) {
            if holding { return }
            let translation = gesture.translation(in: gesture.view)
            let velocity = gesture.velocity(in: gesture.view)
            if gesture.state == .changed {
                onPanChanged(translation.x, translation.y)
            } else if gesture.state == .ended || gesture.state == .cancelled {
                onPanEnded(translation.x, translation.y, velocity.x, velocity.y)
            }
        }
    }
}

private struct CubeFace: ViewModifier {
    var angle: Double

    @ViewBuilder
    func body(content: Content) -> some View {
        if abs(angle) < 0.5 {
            content
        } else {
            content.rotation3DEffect(
                .degrees(angle),
                axis: (x: 0, y: 1, z: 0),
                perspective: WrappedMotion.cubePerspective
            )
        }
    }
}

private struct PlayerCardAccess: ViewModifier {
    var labeled: Bool
    var label: String
    var summary: String
    var onNext: () -> Void
    var onPrevious: () -> Void
    var onMagicTap: () -> Void
    var onEscape: () -> Void

    func body(content: Content) -> some View {
        if labeled {
            content
                .accessibilityElement()
                .accessibilityIdentifier("story-player")
                .accessibilityLabel(label)
                .accessibilityValue(summary)
                .accessibilityAction(named: Text("Next card"), onNext)
                .accessibilityAction(named: Text("Previous card"), onPrevious)
                .accessibilityAction(.magicTap, onMagicTap)
                .accessibilityAction(.escape, onEscape)
                .accessibilityScrollAction { edge in
                    switch edge {
                    case .trailing:
                        onNext()
                    case .leading:
                        onPrevious()
                    default:
                        break
                    }
                }
        } else {
            content.accessibilityHidden(true)
        }
    }
}

private final class PlayerGestureView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if point.y < WrappedSpace.topRowMaxY {
            return nil
        }
        return super.hitTest(point, with: event)
    }
}
