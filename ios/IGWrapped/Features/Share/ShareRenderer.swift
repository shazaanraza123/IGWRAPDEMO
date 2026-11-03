import SwiftUI
import UIKit

enum ShareStyle: Equatable {
    case bold
}

enum ShareFormat: Equatable {
    case story
    case post
    case square

    var pixels: CGSize {
        switch self {
        case .story: CGSize(width: ShareSpace.storyWidth, height: ShareSpace.storyHeight)
        case .post: CGSize(width: ShareSpace.storyWidth, height: ShareSpace.postHeight)
        case .square: CGSize(width: ShareSpace.square, height: ShareSpace.square)
        }
    }

    var safeTop: CGFloat { self == .story ? ShareSpace.storySafeTop : 0 }
    var safeBottom: CGFloat { self == .story ? ShareSpace.storySafeBottom : 0 }

    var storageName: String {
        switch self {
        case .story: return "story"
        case .post: return "post"
        case .square: return "square"
        }
    }
}

enum ShareTarget: Equatable {
    case identity
    case numbers
    case journey(Int)

    static let journeyNumbers = [3, 4, 5, 6, 7, 9, 10, 12]
}

struct ShareToggles: Equatable {
    var handle = true
    var stats = true
    var omittedStats: Set<String> = []
    var secondPersonality = false
    var coverPhoto = true

    static let interestID = "top-interest"

    static func id(for stat: TextPair) -> String {
        stat.label.isEmpty ? stat.value : stat.label
    }
}

enum ShareError: Error, Equatable {
    case notShareable
    case formatUnavailable
    case renderFailed
}

enum ShareKind: Equatable {
    case identity
    case numbers
    case journey(Int)
}

struct ShareScript: Equatable {
    var kind: ShareKind
    var handle: String?
    var year: String?
    var kicker: String?
    var headline: String
    var side: String?
    var prose: [String]
    var stats: [TextPair]
    var interestTitle: String?
    var interest: String?
    var showsFooter: Bool
    var showsCoverPhoto: Bool
    var photoName: String?
    var archetype: PersonalityArchetype

    var lines: [String] {
        var result: [String] = []
        if let handle { result.append(handle) }
        if let year { result.append(year) }
        if let kicker { result.append(kicker) }
        if !headline.isEmpty { result.append(headline) }
        if let side { result.append(side) }
        result.append(contentsOf: prose)
        for stat in stats {
            result.append(stat.value)
            if !stat.label.isEmpty { result.append(stat.label) }
        }
        if let interestTitle { result.append(interestTitle) }
        if let interest { result.append(interest) }
        if showsFooter {
            result.append("Wrapped")
            result.append("INSTAGRAM.COM/WRAPPED")
        }
        return result
    }

    static func make(
        bundle: RunBundle,
        target: ShareTarget,
        format: ShareFormat,
        toggles: ShareToggles
    ) throws -> ShareScript {
        var script: ShareScript
        switch target {
        case .identity:
            script = try identity(bundle, format: format, toggles: toggles)
        case .numbers:
            script = try numbers(bundle, format: format, toggles: toggles)
        case .journey(let number):
            guard ShareTarget.journeyNumbers.contains(number) else { throw ShareError.notShareable }
            guard format == .story else { throw ShareError.formatUnavailable }
            guard bundle.card(number: number)?.shareable == true else { throw ShareError.notShareable }
            script = try journey(bundle, number: number, toggles: toggles)
        }
        script.stats.removeAll { toggles.omittedStats.contains(ShareToggles.id(for: $0)) }
        if toggles.omittedStats.contains(ShareToggles.interestID) {
            script.interestTitle = nil
            script.interest = nil
        }
        return script
    }

    private static func identity(_ bundle: RunBundle, format: ShareFormat, toggles: ShareToggles) throws -> ShareScript {
        let share = try shareCard(bundle)
        let reveal = bundle.card(number: 12) ?? .placeholder(type: "personalityReveal", number: 12)
        let square = format == .square
        let stat = share.payload.identity?.stat
        return ShareScript(
            kind: .identity,
            handle: shownHandle(bundle, toggles),
            year: square ? nil : share.payload.copy?.identityYear,
            kicker: square ? nil : "My Instagram personality",
            headline: reveal.payload.copy?.name ?? "",
            side: toggles.secondPersonality ? reveal.payload.copy?.side : nil,
            prose: [],
            stats: toggles.stats && !square ? stat.map { [$0] } ?? [] : [],
            interestTitle: nil,
            interest: nil,
            showsFooter: !square,
            showsCoverPhoto: false,
            photoName: nil,
            archetype: PersonalityArchetype(rawValue: reveal.payload.primary ?? "") ?? .curator
        )
    }

    private static func numbers(_ bundle: RunBundle, format: ShareFormat, toggles: ShareToggles) throws -> ShareScript {
        let share = try shareCard(bundle)
        let square = format == .square
        let rows = share.payload.numbers?.stats ?? []
        return ShareScript(
            kind: .numbers,
            handle: shownHandle(bundle, toggles),
            year: square ? nil : share.payload.copy?.identityYear,
            kicker: nil,
            headline: share.payload.copy?.numbersTitle ?? "",
            side: nil,
            prose: [],
            stats: toggles.stats && !square ? rows : [],
            interestTitle: toggles.stats && !square ? "Top interest" : nil,
            interest: toggles.stats && !square ? share.payload.numbers?.topInterest : nil,
            showsFooter: !square,
            showsCoverPhoto: toggles.coverPhoto,
            photoName: share.payload.numbers?.photo,
            archetype: .curator
        )
    }

    private static func journey(_ bundle: RunBundle, number: Int, toggles: ShareToggles) throws -> ShareScript {
        let card = try required(bundle.card(number: number))
        let share = try shareCard(bundle)
        let reveal = bundle.card(number: 12)
        let parts = journeyParts(card, toggles: toggles, reveal: reveal)
        return ShareScript(
            kind: .journey(number),
            handle: shownHandle(bundle, toggles),
            year: share.payload.copy?.identityYear,
            kicker: nil,
            headline: parts.headline,
            side: number == 12 && toggles.secondPersonality ? reveal?.payload.copy?.side : nil,
            prose: parts.prose,
            stats: toggles.stats ? parts.stats : [],
            interestTitle: nil,
            interest: nil,
            showsFooter: true,
            showsCoverPhoto: false,
            photoName: nil,
            archetype: PersonalityArchetype(rawValue: reveal?.payload.primary ?? "") ?? .curator
        )
    }

    private static func shareCard(_ bundle: RunBundle) throws -> RunCard {
        let card = try required(bundle.card(number: 13))
        guard card.shareable else { throw ShareError.notShareable }
        return card
    }

    private static func required(_ card: RunCard?) throws -> RunCard {
        guard let card else { throw ShareError.notShareable }
        return card
    }

    private static func shownHandle(_ bundle: RunBundle, _ toggles: ShareToggles) -> String? {
        guard toggles.handle, let handle = bundle.card(number: 1)?.payload.handle, !handle.isEmpty else { return nil }
        return "@\(handle)"
    }

    private static func journeyParts(
        _ card: RunCard,
        toggles: ShareToggles,
        reveal: RunCard?
    ) -> (headline: String, prose: [String], stats: [TextPair]) {
        let copy = card.payload.copy
        switch card.type {
        case "feedColor":
            return (
                copy?.headline ?? "",
                [copy?.footnote, card.payload.paletteName].compactMap { $0 },
                (card.payload.swatches ?? []).map { TextPair(value: "\($0.pct)%", label: $0.hex) }
            )
        case "yourAlgorithm":
            let names = (card.payload.topics ?? []).map(\.name)
            return (
                copy?.headline ?? "",
                ([copy?.undercut].compactMap { $0 }) + names,
                []
            )
        case "reelsRabbitHole":
            return (
                copy?.headline ?? "",
                [copy?.fastestRising, copy?.sent].compactMap { $0 },
                (card.payload.categories ?? []).map { TextPair(value: "\($0.percent)%", label: $0.name) }
            )
        case "mainCharacterPost":
            let likes = card.payload.likes.map { TextPair(value: CountText.string($0), label: "") }
            return (
                copy?.headline ?? "",
                [copy?.comments, copy?.average, copy?.posted, copy?.dateChip].compactMap { $0 },
                likes.map { [$0] } ?? []
            )
        case "brokeTheGroupChat":
            let replies = card.payload.replies.map { TextPair(value: String($0), label: "replies in a day") }
            return (
                copy?.headline ?? "",
                [copy?.storyChip].compactMap { $0 },
                replies.map { [$0] } ?? []
            )
        case "threeAmClub":
            let time = copy?.time.map { TextPair(value: $0, label: "latest scroll") }
            return (
                copy?.headline ?? "",
                [copy?.note].compactMap { $0 },
                time.map { [$0] } ?? []
            )
        case "plotTwist":
            let title = card.payload.category.map { "\($0) posts you liked and saved, by month" }
            return (copy?.headline ?? "", [card.payload.sentence, title].compactMap { $0 }, [])
        case "personalityReveal":
            let reasons = toggles.stats ? (card.payload.reasons ?? []) : []
            return (
                copy?.name ?? "",
                [copy?.primaryMatch, copy?.secondaryMatch].compactMap { $0 },
                reasons
            )
        default:
            return (copy?.headline ?? "", [], [])
        }
    }
}

struct ShareMeasure: Equatable {
    var format: ShareFormat

    var canvas: CGSize { format.pixels }

    var safeTop: CGFloat { format.safeTop }
    var safeBottom: CGFloat { format.safeBottom }

    var content: CGSize {
        CGSize(width: canvas.width, height: canvas.height - safeTop - safeBottom)
    }

    /// Design-point board before it is scaled onto the export.
    var board: CGSize {
        let width = WrappedSpace.frameWidth
        switch format {
        case .story:
            return CGSize(width: width, height: WrappedSpace.frameHeight)
        case .post:
            return CGSize(width: width, height: width * ShareSpace.postHeight / ShareSpace.storyWidth)
        case .square:
            return CGSize(width: width, height: width)
        }
    }

    /// Uniform scale from the design board onto the safe content box. Never crops.
    var scale: CGFloat {
        min(content.width / board.width, content.height / board.height)
    }

    /// Post is a shorter field, so type from the 9:16 board shrinks to fit it.
    var squeeze: CGFloat {
        guard format == .post else { return 1 }
        return board.height / WrappedSpace.frameHeight
    }

    func px(_ design: CGFloat) -> CGFloat { design * scale * squeeze }
}

@MainActor
enum ShareRenderer {
    static func png(
        bundle: RunBundle,
        target: ShareTarget,
        format: ShareFormat,
        style: ShareStyle = .bold,
        toggles: ShareToggles = ShareToggles()
    ) throws -> Data {
        switch style {
        case .bold:
            break
        }
        let script = try ShareScript.make(bundle: bundle, target: target, format: format, toggles: toggles)
        let measure = ShareMeasure(format: format)
        let view = ShareExport(script: script, measure: measure)
            .frame(width: measure.canvas.width, height: measure.canvas.height)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        renderer.isOpaque = true
        renderer.proposedSize = ProposedViewSize(width: measure.canvas.width, height: measure.canvas.height)
        guard let data = renderer.uiImage?.pngData() else { throw ShareError.renderFailed }
        return data
    }
}

struct ShareExport: View {
    var script: ShareScript
    var measure: ShareMeasure

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                Color.clear.frame(height: measure.safeTop)
                board
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Color.clear.frame(height: measure.safeBottom)
            }
        }
        .frame(width: measure.canvas.width, height: measure.canvas.height)
    }

    private var board: some View {
        Group {
            switch script.kind {
            case .identity:
                if measure.format == .square {
                    squareIdentity
                } else {
                    identityBoard
                }
            case .numbers:
                if measure.format == .square {
                    squareNumbers
                } else {
                    numbersBoard
                }
            case .journey:
                journeyBoard
            }
        }
        .frame(
            width: measure.board.width * measure.scale,
            height: measure.board.height * measure.scale
        )
    }

    private var background: some View {
        ZStack(alignment: .top) {
            switch script.kind {
            case .identity:
                WrappedColor.igMagenta
            case .numbers:
                WrappedColor.paper
                if measure.format != .square {
                    WrappedColor.igPink
                        .frame(maxWidth: .infinity)
                        .frame(height: measure.safeTop + measure.px(numbersBand))
                }
            case .journey(let number):
                ShareField.color(number)
            }
        }
        .ignoresSafeArea()
    }

    private var numbersBand: CGFloat {
        script.showsCoverPhoto ? CardSpace.numbersHeader : CardSpace.identityTop + CardSpace.shareSize
    }

    private var foreground: Color {
        switch script.kind {
        case .identity: WrappedColor.igWhite
        case .numbers: WrappedColor.ink
        case .journey(let number): ShareField.foreground(number)
        }
    }

    private var identityBoard: some View {
        VStack(spacing: measure.px(CardSpace.chipGap)) {
            handleRow(color: WrappedColor.igWhite)
            mark
            if let kicker = script.kicker {
                CardText(
                    text: kicker,
                    size: measure.px(CardSpace.identityKicker),
                    weight: CardSpace.strong,
                    width: CardSpace.regular,
                    tracking: measure.px(CardSpace.identityKickerTracking),
                    color: WrappedColor.igWhite,
                    uppercase: true,
                    alignment: .center
                )
            }
            DisplayHeadline(
                copy: script.headline,
                size: measure.px(CardSpace.identityName),
                lineHeight: CardSpace.identityNameLine,
                tracking: measure.px(CardSpace.identityNameTracking),
                color: WrappedColor.igWhite,
                alignment: .center
            )
            if let side = script.side {
                CardText(
                    text: side,
                    size: measure.px(CardSpace.revealSide),
                    weight: CardSpace.strong,
                    width: CardSpace.regular,
                    color: WrappedColor.igWhite,
                    alignment: .center
                )
            }
            Spacer(minLength: 0)
            if let stat = script.stats.first {
                statRow(value: stat.value, label: stat.label, color: WrappedColor.igWhite)
            }
            if script.showsFooter {
                ShareFooter(markBorder: WrappedColor.igMagenta, word: WrappedColor.igWhite, measure: measure)
            }
        }
        .padding(.horizontal, measure.px(CardSpace.identityInset))
        .padding(.top, measure.px(measure.format == .story ? CardSpace.identityTop : WrappedSpace.gutter))
        .padding(.bottom, measure.px(measure.format == .story ? CardSpace.shareClearance : WrappedSpace.gutter))
    }

    private var numbersBoard: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: measure.px(CardSpace.chipGap)) {
                handleRow(color: WrappedColor.igWhite)
                if script.showsCoverPhoto {
                    cover
                }
            }
            .padding(.horizontal, measure.px(CardSpace.identityInset))
            .padding(.top, measure.px(CardSpace.identityTop))
            .frame(maxWidth: .infinity)
            .frame(height: measure.px(script.showsCoverPhoto ? CardSpace.numbersHeader : CardSpace.identityTop + CardSpace.shareSize), alignment: .top)
            .background(WrappedColor.igPink)

            DisplayHeadline(
                copy: script.headline,
                size: measure.px(CardSpace.numbersTitle),
                lineHeight: CardSpace.numbersTitleLine,
                tracking: measure.px(CardSpace.algorithmHeadlineTracking),
                color: WrappedColor.ink
            )
            .padding(.horizontal, measure.px(CardSpace.identityInset))
            .padding(.top, measure.px(CardSpace.identityInset))

            if !script.stats.isEmpty {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: measure.px(CardSpace.numbersColumn)),
                        GridItem(.flexible(), spacing: measure.px(CardSpace.numbersColumn))
                    ],
                    spacing: measure.px(CardSpace.openingSupport)
                ) {
                    ForEach(Array(script.stats.enumerated()), id: \.offset) { _, stat in
                        VStack(alignment: .leading, spacing: measure.px(CardSpace.reasonGap)) {
                            CardText(
                                text: stat.value,
                                size: measure.px(CardSpace.numbersValue),
                                lineHeight: CardSpace.numbersValueLine,
                                color: WrappedColor.ink
                            )
                            CardText(
                                text: stat.label,
                                size: measure.px(CardSpace.numbersLabel),
                                weight: CardSpace.strong,
                                width: CardSpace.regular,
                                color: WrappedColor.ink
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, measure.px(CardSpace.chipGap))
                        .overlay(alignment: .top) {
                            Rectangle().fill(WrappedColor.ink).frame(height: measure.px(CardSpace.identityRule))
                        }
                    }
                }
                .padding(.horizontal, measure.px(CardSpace.identityInset))
                .padding(.top, measure.px(CardSpace.openingSupport))
            }

            if let title = script.interestTitle, let interest = script.interest {
                HStack(alignment: .firstTextBaseline) {
                    CardText(
                        text: title,
                        size: measure.px(CardSpace.numbersLabel),
                        weight: CardSpace.strong,
                        width: CardSpace.regular,
                        color: WrappedColor.ink
                    )
                    Spacer(minLength: 0)
                    CardText(
                        text: interest,
                        size: measure.px(CardSpace.numbersInterest),
                        color: WrappedColor.ink,
                        uppercase: true
                    )
                }
                .padding(.top, measure.px(CardSpace.yearCopyGap))
                .overlay(alignment: .top) {
                    Rectangle().fill(WrappedColor.ink).frame(height: measure.px(CardSpace.identityRule))
                }
                .padding(.horizontal, measure.px(CardSpace.identityInset))
                .padding(.top, measure.px(CardSpace.openingSupport))
            }

            Spacer(minLength: 0)
            if script.showsFooter {
                ShareFooter(markBorder: WrappedColor.paper, word: WrappedColor.ink, measure: measure)
                    .padding(.horizontal, measure.px(CardSpace.identityInset))
                    .padding(.bottom, measure.px(measure.format == .story ? CardSpace.shareClearance : WrappedSpace.gutter))
            }
        }
    }

    private var squareIdentity: some View {
        VStack(spacing: measure.px(CardSpace.chipGap)) {
            if script.handle != nil {
                handleRow(color: WrappedColor.igWhite)
            }
            Spacer(minLength: 0)
            mark
            DisplayHeadline(
                copy: script.headline,
                size: measure.px(CardSpace.revealName),
                lineHeight: CardSpace.revealNameLine,
                tracking: measure.px(CardSpace.revealNameTracking),
                color: WrappedColor.igWhite,
                alignment: .center
            )
            if let side = script.side {
                CardText(
                    text: side,
                    size: measure.px(CardSpace.revealSide),
                    weight: CardSpace.strong,
                    width: CardSpace.regular,
                    color: WrappedColor.igWhite,
                    alignment: .center
                )
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, measure.px(CardSpace.identityInset))
        .padding(.vertical, measure.px(WrappedSpace.gutter))
    }

    private var squareNumbers: some View {
        VStack(spacing: measure.px(CardSpace.blockGap)) {
            if script.handle != nil {
                handleRow(color: WrappedColor.igWhite)
            }
            Spacer(minLength: 0)
            if script.showsCoverPhoto {
                cover
            }
            DisplayHeadline(
                copy: script.headline,
                size: measure.px(CardSpace.numbersTitle),
                lineHeight: CardSpace.numbersTitleLine,
                tracking: measure.px(CardSpace.algorithmHeadlineTracking),
                color: WrappedColor.ink,
                alignment: .center
            )
            Spacer(minLength: 0)
        }
        .padding(.horizontal, measure.px(CardSpace.identityInset))
        .padding(.vertical, measure.px(WrappedSpace.gutter))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            VStack(spacing: 0) {
                WrappedColor.igPink.frame(maxHeight: .infinity)
                WrappedColor.paper.frame(maxHeight: .infinity)
            }
        }
    }

    private var journeyBoard: some View {
        VStack(alignment: .leading, spacing: measure.px(CardSpace.blockGap)) {
            handleRow(color: foreground)
            DisplayHeadline(
                copy: script.headline,
                size: measure.px(CardSpace.feedHeadline),
                lineHeight: CardSpace.openingHeadlineLine,
                tracking: measure.px(CardSpace.feedHeadlineTracking),
                color: foreground
            )
            if let side = script.side {
                CardText(
                    text: side,
                    size: measure.px(CardSpace.revealSide),
                    weight: CardSpace.strong,
                    width: CardSpace.regular,
                    color: foreground
                )
            }
            ForEach(Array(script.prose.enumerated()), id: \.offset) { _, line in
                CardText(
                    text: line,
                    size: measure.px(CardSpace.plotSentence),
                    weight: CardSpace.strong,
                    width: CardSpace.regular,
                    color: foreground
                )
            }
            ForEach(Array(script.stats.enumerated()), id: \.offset) { _, stat in
                HStack(alignment: .firstTextBaseline, spacing: measure.px(CardSpace.chipGap)) {
                    CardText(
                        text: stat.value,
                        size: measure.px(CardSpace.numbersValue),
                        lineHeight: CardSpace.numbersValueLine,
                        color: foreground
                    )
                    if !stat.label.isEmpty {
                        CardText(
                            text: stat.label,
                            size: measure.px(CardSpace.numbersLabel),
                            weight: CardSpace.strong,
                            width: CardSpace.regular,
                            color: foreground
                        )
                    }
                }
            }
            Spacer(minLength: 0)
            if script.showsFooter {
                let border = script.kind == .journey(12) ? WrappedColor.igMagenta : foreground
                ShareFooter(markBorder: border, word: foreground, measure: measure)
            }
        }
        .padding(.horizontal, measure.px(CardSpace.identityInset))
        .padding(.top, measure.px(CardSpace.identityTop))
        .padding(.bottom, measure.px(CardSpace.shareClearance))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var mark: some View {
        ZStack {
            Circle()
                .stroke(
                    WrappedColor.ink,
                    style: StrokeStyle(
                        lineWidth: measure.px(CardSpace.revealRing),
                        dash: [measure.px(CardSpace.revealDash), measure.px(CardSpace.revealDashGap)]
                    )
                )
            Circle().fill(WrappedColor.ink).padding(measure.px(CardSpace.revealRing))
            PersonalityMark(archetype: script.archetype, size: measure.px(CardSpace.revealInner))
        }
        .frame(width: measure.px(CardSpace.identityMark), height: measure.px(CardSpace.identityMark))
        .frame(maxWidth: .infinity)
    }

    private var cover: some View {
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
                    style: StrokeStyle(
                        lineWidth: measure.px(CardSpace.numbersRing),
                        dash: [measure.px(CardSpace.numbersDash), measure.px(CardSpace.numbersGap)]
                    )
                )
                .frame(width: measure.px(CardSpace.numbersRingBox), height: measure.px(CardSpace.numbersRingBox))
            Group {
                if let name = script.photoName, let image = BundlePhoto.image(named: name) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    MonthTone.gradient(2)
                }
            }
            .frame(width: measure.px(CardSpace.numbersPhoto), height: measure.px(CardSpace.numbersPhoto))
            .clipShape(Circle())
            .overlay(Circle().stroke(WrappedColor.igPink, lineWidth: measure.px(CardSpace.openingBadgeBorder)))
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Your photo of the year")
    }

    private func handleRow(color: Color) -> some View {
        HStack {
            if let handle = script.handle {
                Text(handle)
            }
            Spacer(minLength: 0)
            if let year = script.year {
                Text(year)
            }
        }
        .font(CardTypeface.font(size: measure.px(CardSpace.shareSize), weight: CardSpace.strong, width: CardSpace.regular))
        .foregroundStyle(color)
    }

    private func statRow(value: String, label: String, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: measure.px(CardSpace.yearCopyGap)) {
            CardText(
                text: value,
                size: measure.px(CardSpace.identityStat),
                lineHeight: CardSpace.identityStatLine,
                color: color
            )
            CardText(
                text: label,
                size: measure.px(CardSpace.identityCaption),
                weight: CardSpace.strong,
                width: CardSpace.regular,
                color: color
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, measure.px(CardSpace.stickerPadH))
        .overlay(alignment: .top) {
            Rectangle().fill(WrappedColor.ink).frame(height: measure.px(CardSpace.identityRule))
        }
    }
}

private struct ShareFooter: View {
    var markBorder: Color
    var word: Color
    var measure: ShareMeasure

    var body: some View {
        HStack {
            HStack(spacing: measure.px(CardSpace.chipGap)) {
                ZStack {
                    Circle().fill(WrappedColor.igWhite)
                    Circle().fill(WrappedColor.ink).padding(measure.px(CardSpace.footerRingPad))
                    Circle().stroke(markBorder, lineWidth: measure.px(CardSpace.ringWidth)).padding(measure.px(CardSpace.footerRingPad))
                    Text("26")
                        .font(CardTypeface.font(size: measure.px(CardSpace.markDigits), weight: CardSpace.heavy, width: CardSpace.regular))
                        .foregroundStyle(WrappedColor.igWhite)
                }
                .frame(width: measure.px(CardSpace.footerMark), height: measure.px(CardSpace.footerMark))
                Text("Wrapped")
                    .font(CardTypeface.font(size: measure.px(CardSpace.footerWord), weight: CardSpace.heavy, width: CardSpace.regular))
                    .foregroundStyle(word)
            }
            Spacer(minLength: 0)
            Text("INSTAGRAM.COM/WRAPPED")
                .font(CardTypeface.font(size: measure.px(CardSpace.footerLink), weight: CardSpace.strong, width: CardSpace.regular))
                .tracking(measure.px(CardSpace.footerLinkTracking))
                .foregroundStyle(word)
        }
    }
}

private enum ShareField {
    static func color(_ number: Int) -> Color {
        switch number {
        case 3: WrappedColor.paper
        case 4: WrappedColor.igViolet
        case 5: WrappedColor.igOrange
        case 6, 10: WrappedColor.igYellow
        case 7: WrappedColor.closeGreen
        case 9: WrappedColor.nightNavy
        case 12: WrappedColor.igMagenta
        default: WrappedColor.ink
        }
    }

    static func foreground(_ number: Int) -> Color {
        switch number {
        case 4, 9, 12: WrappedColor.igWhite
        default: WrappedColor.ink
        }
    }
}
