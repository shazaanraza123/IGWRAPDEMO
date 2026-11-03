import SwiftUI

enum ShareChoice: Equatable, Identifiable {
    case journey(Int)
    case identity
    case numbers

    var id: String {
        switch self {
        case .journey(let number): "journey-\(number)"
        case .identity: "identity"
        case .numbers: "numbers"
        }
    }

    var title: String {
        switch self {
        case .journey(let number): Self.journeyTitle(number)
        case .identity: "Identity card"
        case .numbers: "Numbers card"
        }
    }

    var target: ShareTarget {
        switch self {
        case .journey(let number): .journey(number)
        case .identity: .identity
        case .numbers: .numbers
        }
    }

    var locksStory: Bool {
        if case .journey = self { return true }
        return false
    }

    static func choices(openedFrom card: Int) -> [ShareChoice] {
        switch card {
        case 3, 4, 5, 6, 7, 9, 10:
            return [.journey(card), .identity, .numbers]
        case 12, 13:
            return [.identity, .numbers]
        default:
            return []
        }
    }

    static func journeyTitle(_ number: Int) -> String {
        switch number {
        case 3: "Feed color"
        case 4: "Algorithm"
        case 5: "Reels"
        case 6: "This post"
        case 7: "This Story"
        case 9: "3AM"
        case 10: "Plot twist"
        default: "This card"
        }
    }
}

struct ShareSheet: View {
    var bundle: RunBundle
    var openedFrom: Int
    var preferNumbers: Bool
    var onMessage: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var choice: ShareChoice
    @State private var format: ShareFormat = .story
    @State private var toggles = ShareToggles()
    @State private var notice: String?
    @State private var settingsLink = false

    init(bundle: RunBundle, openedFrom: Int, preferNumbers: Bool, onMessage: @escaping (String) -> Void) {
        self.bundle = bundle
        self.openedFrom = openedFrom
        self.preferNumbers = preferNumbers
        self.onMessage = onMessage
        let choices = ShareChoice.choices(openedFrom: openedFrom)
        let initial: ShareChoice = (openedFrom == 13 && preferNumbers) ? .numbers : (choices.first ?? .identity)
        _choice = State(initialValue: initial)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ShareSheetSpace.sectionGap) {
            Capsule()
                .fill(WrappedColor.sheetLine)
                .frame(width: ShareSheetSpace.grabberWidth, height: ShareSheetSpace.grabberHeight)
                .frame(maxWidth: .infinity)
            header
            ScrollView {
                VStack(alignment: .leading, spacing: ShareSheetSpace.sectionGap) {
                    picker
                    previewRow
                    styles
                    chips
                }
            }
            if let notice {
                noticeLine(notice)
            }
            actions
        }
        .padding(.horizontal, WrappedSpace.gutter)
        .padding(.top, ShareSheetSpace.sheetTop)
        .padding(.bottom, ShareSheetSpace.sheetBottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            WrappedColor.sheet
                .accessibilityIdentifier("share-sheet")
                .accessibilityLabel("Share sheet")
        }
        .presentationDetents([.fraction(ShareSheetSpace.detent)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(WrappedColor.sheet)
        .presentationCornerRadius(WrappedSpace.sheetRadius)
    }

    private var header: some View {
        HStack {
            Text("Share your Wrapped")
                .font(ArchivoFont.font(size: ShareSheetSpace.title, weight: CardSpace.heavy, width: ShareSheetSpace.titleWidth))
                .foregroundStyle(WrappedColor.igWhite)
            Spacer(minLength: 0)
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: CardSpace.shareSize, weight: .bold))
                    .foregroundStyle(WrappedColor.igWhite)
                    .frame(width: WrappedSpace.minHit, height: WrappedSpace.minHit)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cancel")
            .accessibilityIdentifier("share-cancel")
        }
    }

    private var picker: some View {
        let choices = ShareChoice.choices(openedFrom: openedFrom)
        return HStack(spacing: WrappedSpace.gridGap) {
            ForEach(choices) { item in
                Button {
                    choice = item
                    if item.locksStory { format = .story }
                    notice = nil
                    settingsLink = false
                } label: {
                    Text(item.title)
                        .font(ArchivoFont.font(
                            size: CardSpace.footerLink,
                            weight: choice == item ? CardSpace.strong : CardSpace.medium,
                            width: CardSpace.regular
                        ))
                        .foregroundStyle(choice == item ? WrappedColor.ink : WrappedColor.onInkSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: WrappedSpace.minHit)
                        .background(
                            RoundedRectangle(cornerRadius: CardSpace.stickerRadius)
                                .fill(choice == item ? WrappedColor.igWhite : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("share-choice-\(item.id)")
                .accessibilityAddTraits(choice == item ? .isSelected : [])
            }
        }
        .padding(WrappedSpace.gridGap)
        .background(RoundedRectangle(cornerRadius: CardSpace.stickerRadius).fill(WrappedColor.surfaceRaised))
    }

    private var previewRow: some View {
        HStack(alignment: .top, spacing: WrappedSpace.gutter) {
            SharePreview(bundle: bundle, target: choice.target, format: format, toggles: toggles)
                .frame(width: ShareSheetSpace.previewWidth, height: ShareSheetSpace.previewHeight)
                .clipShape(RoundedRectangle(cornerRadius: ShareSheetSpace.previewRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: ShareSheetSpace.previewRadius)
                        .stroke(WrappedColor.sheetLine, lineWidth: CardSpace.hairline)
                )
            VStack(alignment: .leading, spacing: ShareSheetSpace.rowGap) {
                sectionLabel("Format")
                formatButton("Story", ratio: "9:16", format: .story, enabled: true)
                formatButton("Post", ratio: "4:5", format: .post, enabled: !choice.locksStory)
                formatButton("Square", ratio: "1:1", format: .square, enabled: !choice.locksStory)
            }
        }
    }

    private var styles: some View {
        VStack(alignment: .leading, spacing: ShareSheetSpace.rowGap) {
            sectionLabel("Style")
            HStack(spacing: ShareSheetSpace.rowGap) {
                styleSwatch("Bold", colors: [WrappedColor.igMagenta, WrappedColor.ink], enabled: true)
                if !Pitch.active {
                    styleSwatch("Scrapbook", colors: [WrappedColor.paper, WrappedColor.paletteCamel], enabled: false)
                    styleSwatch("Numbers", colors: [WrappedColor.ink, WrappedColor.igYellow], enabled: false)
                    styleSwatch("Photo Film", colors: [WrappedColor.igViolet, WrappedColor.igPink], enabled: false)
                }
            }
        }
    }

    private var chips: some View {
        VStack(alignment: .leading, spacing: ShareSheetSpace.rowGap) {
            sectionLabel("Show on card")
            chipFlow
        }
    }

    private var chipFlow: some View {
        let full = try? ShareScript.make(
            bundle: bundle,
            target: choice.target,
            format: .story,
            toggles: ShareToggles()
        )
        return ChipFlow(spacing: ShareSheetSpace.rowGap) {
            ToggleChip(title: "@handle", isOn: toggles.handle) {
                toggles.handle.toggle()
            }
            .accessibilityIdentifier("share-chip-handle")
            if let full {
                ForEach(Array(full.stats.enumerated()), id: \.offset) { _, stat in
                    let chipID = ShareToggles.id(for: stat)
                    ToggleChip(title: chipID, isOn: !toggles.omittedStats.contains(chipID)) {
                        toggleStat(chipID)
                    }
                    .accessibilityIdentifier("share-chip-\(chipID)")
                }
                if full.interest != nil {
                    ToggleChip(title: "Top interest", isOn: !toggles.omittedStats.contains(ShareToggles.interestID)) {
                        toggleStat(ShareToggles.interestID)
                    }
                    .accessibilityIdentifier("share-chip-interest")
                }
            }
            if showsSide {
                ToggleChip(title: "Second personality", isOn: toggles.secondPersonality) {
                    toggles.secondPersonality.toggle()
                }
                .accessibilityIdentifier("share-chip-side")
            }
            if case .numbers = choice {
                ToggleChip(title: "Cover photo", isOn: toggles.coverPhoto) {
                    toggles.coverPhoto.toggle()
                }
                .accessibilityIdentifier("share-chip-photo")
            }
        }
    }

    private func toggleStat(_ id: String) {
        if toggles.omittedStats.contains(id) {
            toggles.omittedStats.remove(id)
        } else {
            toggles.omittedStats.insert(id)
        }
    }

    private var showsSide: Bool {
        switch choice {
        case .identity, .journey(12): true
        default: false
        }
    }

    private var actions: some View {
        HStack(spacing: ShareSheetSpace.rowGap) {
            action("Your story", symbol: "plus", ring: true, identifier: "share-your-story", action: yourStory)
            action("Send", symbol: "paperplane", ring: false, identifier: "share-send", action: send)
            action("Save", symbol: "square.and.arrow.down", ring: false, identifier: "share-save", action: save)
            action("Copy link", symbol: "link", ring: false, identifier: "share-copy-link", action: copyLink)
        }
        .frame(maxWidth: .infinity)
    }

    private func yourStory() {
        guard let png = rendered() else { return }
        let colors = StoryShare.colors(for: choice.target)
        let result = StoryShare.yourStory(png: png, top: colors.top, bottom: colors.bottom, client: StoryShare.liveClient())
        switch result {
        case .needsAppID:
            show(StoryShare.missingAppID)
        case .instagramMissing:
            show(StoryShare.missingInstagram)
        case .opened:
            _ = ShareLog.append(ShareLog.story)
            notice = nil
            settingsLink = false
        default:
            break
        }
    }

    private func send() {
        guard let png = rendered() else { return }
        StoryShare.presentSend(png)
        _ = ShareLog.append(ShareLog.send)
    }

    private func save() {
        guard let png = rendered() else { return }
        Task {
            let result = await StoryShare.saveToPhotos(png)
            switch result {
            case .saved:
                _ = ShareLog.append(ShareLog.save)
                show(StoryShare.saved)
            case .saveDenied:
                show(StoryShare.photoDenied, settings: true)
            case .saveFailed:
                show(StoryShare.photoDenied, settings: true)
            default:
                break
            }
        }
    }

    private func copyLink() {
        guard let png = rendered() else { return }
        let cardType = ShareLink.cardType(for: choice.target)
        let formatName = format.storageName
        let alt = shareAlt()
        Task {
            let result = await ShareLink.copy(
                png: png,
                cardType: cardType,
                format: formatName,
                alt: alt,
                client: await ShareLink.liveClient()
            )
            guard case .copied(let link) = result else { return }
            UIPasteboard.general.string = link
            _ = ShareLog.append(ShareLog.link)
            show(ShareLink.copied)
        }
    }

    private func shareAlt() -> String {
        let headline = (try? ShareScript.make(
            bundle: bundle,
            target: choice.target,
            format: format,
            toggles: toggles
        ))?.headline.trimmingCharacters(in: .whitespacesAndNewlines)
        if let headline, !headline.isEmpty { return headline }
        return choice.title
    }

    private func show(_ text: String, settings: Bool = false) {
        notice = text
        settingsLink = settings
        onMessage(text)
    }

    private func rendered() -> Data? {
        try? ShareRenderer.png(bundle: bundle, target: choice.target, format: format, toggles: toggles)
    }

    private func noticeLine(_ text: String) -> some View {
        HStack {
            Text(text)
                .wrappedType(.caption)
                .foregroundStyle(WrappedColor.igWhite)
            Spacer(minLength: 0)
            if settingsLink {
                Button("Open Settings") {
                    StoryShare.openSettings()
                }
                .buttonStyle(.plain)
                .wrappedType(.caption)
                .foregroundStyle(WrappedColor.igWhite)
                .accessibilityIdentifier("share-open-settings")
            }
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .wrappedType(.eyebrow)
            .foregroundStyle(WrappedColor.muted)
    }

    private func formatButton(_ title: String, ratio: String, format: ShareFormat, enabled: Bool) -> some View {
        let selected = self.format == format
        return Button {
            guard enabled else { return }
            self.format = format
        } label: {
            HStack {
                Text(title)
                    .font(ArchivoFont.font(
                        size: CardSpace.footerLink,
                        weight: selected ? CardSpace.strong : CardSpace.medium,
                        width: CardSpace.regular
                    ))
                Spacer(minLength: 0)
                Text(ratio)
                    .font(ArchivoFont.font(size: CardSpace.footerLink, weight: CardSpace.support, width: CardSpace.regular))
                    .foregroundStyle(selected ? WrappedColor.sheetDash : WrappedColor.muted)
            }
            .foregroundStyle(selected ? WrappedColor.ink : WrappedColor.igWhite)
            .padding(.horizontal, CardSpace.blockGap)
            .frame(height: ShareSheetSpace.formatHeight)
            .background(
                RoundedRectangle(cornerRadius: ShareSheetSpace.formatRadius)
                    .fill(selected ? WrappedColor.igWhite : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ShareSheetSpace.formatRadius)
                    .stroke(selected ? Color.clear : WrappedColor.sheetLine, lineWidth: CardSpace.hairline)
            )
            .opacity(enabled ? 1 : CardSpace.barDim)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("share-format-\(formatName(format))")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func styleSwatch(_ name: String, colors: [Color], enabled: Bool) -> some View {
        VStack(alignment: .leading, spacing: CardSpace.chipGap) {
            RoundedRectangle(cornerRadius: ShareSheetSpace.styleRadius)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: ShareSheetSpace.styleHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: ShareSheetSpace.styleRadius)
                        .stroke(enabled ? WrappedColor.igWhite : Color.clear, lineWidth: CardSpace.ringWidth)
                )
            Text(name)
                .wrappedType(.caption)
                .foregroundStyle(WrappedColor.igWhite)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(name)
        .accessibilityIdentifier("share-style-\(name.lowercased().replacingOccurrences(of: " ", with: "-"))")
        .accessibilityAddTraits(enabled ? .isSelected : [])
    }

    private func action(_ title: String, symbol: String, ring: Bool, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: ShareSheetSpace.rowGap) {
                ZStack {
                    if ring {
                        Circle().stroke(WrappedColor.storyRing, lineWidth: CardSpace.footerRingPad)
                            .padding(CardSpace.ringWidth)
                    }
                    Circle().fill(WrappedColor.surfaceRaised)
                        .padding(ring ? CardSpace.chipPadV : 0)
                    Image(systemName: symbol)
                        .font(.system(size: CardSpace.shareSize, weight: .semibold))
                        .foregroundStyle(WrappedColor.igWhite)
                }
                .frame(width: ShareSheetSpace.action, height: ShareSheetSpace.action)
                Text(title)
                    .font(ArchivoFont.font(
                        size: CardSpace.undercutSize,
                        weight: ring ? CardSpace.strong : CardSpace.medium,
                        width: CardSpace.regular
                    ))
                    .foregroundStyle(WrappedColor.igWhite)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }

    private func formatName(_ format: ShareFormat) -> String {
        switch format {
        case .story: "story"
        case .post: "post"
        case .square: "square"
        }
    }
}

struct SharePreview: View {
    var bundle: RunBundle
    var target: ShareTarget
    var format: ShareFormat
    var toggles: ShareToggles

    var body: some View {
        let measure = ShareMeasure(format: format)
        let scale = min(
            ShareSheetSpace.previewWidth / measure.canvas.width,
            ShareSheetSpace.previewHeight / measure.canvas.height
        )
        Group {
            if let script = try? ShareScript.make(bundle: bundle, target: target, format: format, toggles: toggles) {
                ShareExport(script: script, measure: measure)
                    .frame(width: measure.canvas.width, height: measure.canvas.height)
                    .scaleEffect(scale)
                    .frame(width: measure.canvas.width * scale, height: measure.canvas.height * scale)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Wraps chips onto as many rows as they need.
private struct ChipFlow: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? WrappedSpace.frameWidth
        let rows = rows(width: width, subviews: subviews)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for row in rows(width: bounds.width, subviews: subviews) {
            subviews[row.index].place(
                at: CGPoint(x: bounds.minX + row.x, y: bounds.minY + row.y),
                proposal: ProposedViewSize(width: row.width, height: row.height)
            )
        }
    }

    private func rows(width: CGFloat, subviews: Subviews) -> [(index: Int, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat)] {
        var placed: [(index: Int, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat)] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for (index, view) in subviews.enumerated() {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            placed.append((index, x, y, size.width, size.height))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return placed
    }
}
