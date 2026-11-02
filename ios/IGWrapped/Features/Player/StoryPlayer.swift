import SwiftUI
import UIKit

struct StoryPlayer: View {
    var onExit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model: StoryPlayerModel
    @State private var showsInfo = false
    @State private var isMuted = false
    @State private var dismissDrag: CGFloat = 0
    @State private var chapterDrag: CGFloat = 0
    @State private var openMonth: MayaMonth?
    @State private var showsMontage = false
    @State private var showsPost = false
    @State private var showsStory = false
    @State private var toast: String?
    @State private var revealPulse = 0
    private let startsOnNumbers: Bool
    private let audio = AudioService.shared

    init(onExit: @escaping () -> Void, omitted: Set<Int> = []) {
        self.onExit = onExit
        var model = StoryPlayerModel()
        let arguments = ProcessInfo.processInfo.arguments
        if let flag = arguments.firstIndex(of: "--player-card"),
           flag + 1 < arguments.count,
           let number = Int(arguments[flag + 1]),
           (1 ... StoryPlayerModel.cardCount).contains(number) {
            model.card = number
        }
        if arguments.contains("--player-paused") {
            model.autoplay = false
        }
        if arguments.contains("--teen") {
            model.omitted = [8, 9]
        } else {
            model.omitted = omitted
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
            if showsMontage {
                YearMontage {
                    showsMontage = false
                }
            }
            if showsPost {
                PostDetailCover { showsPost = false }
            }
            if showsStory {
                StoryReplayCover { showsStory = false }
            }
            if let toast {
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
                audio.pause()
            } else if !model.isHolding {
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
            CardInfoSheet()
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
        default: Chapter.containing(card).field
        }
    }

    @ViewBuilder
    private func cardContent(_ card: Int) -> some View {
        switch card {
        case 1:
            OpeningCard {
                withAnimation(cardAnimation) { step(model.goForward()) }
            }
        case 2:
            YearMemoriesCard(
                onMonth: { openMonth = $0 },
                onPlay: { showsMontage = true }
            )
        case 3:
            FeedColorCard(onShare: { showToast("Not part of this demo") })
        case 4:
            AlgorithmCard(
                onShare: { showToast("Not part of this demo") },
                onSaved: { showToast("Got it. We'll tune Explore.") }
            )
        case 5:
            ReelsCard(onShare: { showToast("Not part of this demo") })
        case 6:
            MainCharacterCard(
                onShare: { showToast("Not part of this demo") },
                onOpenPost: { showsPost = true }
            )
        case 7:
            GroupChatCard(
                onShare: { showToast("Not part of this demo") },
                onOpenStory: { showsStory = true }
            )
        case 8:
            CircleCard()
        case 9:
            ThreeAMCard(onShare: { showToast("Not part of this demo") })
        case 10:
            PlotTwistCard(onShare: { showToast("Not part of this demo") })
        case 11:
            PersonalityTeaserCard(onReveal: revealPersonality)
        case 12:
            PersonalityRevealCard(
                onShare: { showToast("Not part of this demo") },
                onShareCards: {
                    withAnimation(cardAnimation) { step(model.goForward()) }
                }
            )
        case 13:
            ShareCardsCard(
                onShare: { showToast("Not part of this demo") },
                onHub: { showToast("Not part of this demo") },
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
        guard ProcessInfo.processInfo.arguments.contains("--reference") else { return nil }
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
            .accessibilityHidden(true)
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
        withAnimation(.easeIn(duration: IGSpace.viewerDismiss)) {
            dismissDrag = WrappedSpace.frameHeight
        }
        Task {
            try? await Task.sleep(for: .seconds(IGSpace.viewerDismiss))
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

    private func showToast(_ message: String) {
        toast = message
        Task {
            try? await Task.sleep(for: .seconds(2))
            if toast == message {
                toast = nil
            }
        }
    }

    private func exit() {
        audio.setDucked(false)
        audio.stop()
        PlayerProgressStore.save(PlayerProgress(card: model.card, elapsed: model.elapsed))
        onExit()
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
