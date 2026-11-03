import SwiftUI

enum HubInk: Equatable {
    case ink
    case white

    var color: Color {
        switch self {
        case .ink: return WrappedColor.ink
        case .white: return WrappedColor.igWhite
        }
    }
}

enum HubFill: Equatable {
    case raised
    case yellow
    case orange
    case magenta
    case pink
    case paper
    case violet
    case green
    case navy
    case ghost

    var color: Color {
        switch self {
        case .raised: return WrappedColor.surfaceRaised
        case .yellow: return WrappedColor.igYellow
        case .orange: return WrappedColor.igOrange
        case .magenta: return WrappedColor.igMagenta
        case .pink: return WrappedColor.igPink
        case .paper: return WrappedColor.paper
        case .violet: return WrappedColor.igViolet
        case .green: return WrappedColor.closeGreen
        case .navy: return WrappedColor.nightNavy
        case .ghost: return WrappedColor.ghostInk
        }
    }
}

struct HubHighlight: Equatable, Identifiable {
    var card: Int
    var kicker: String
    var title: String
    var detail: String
    var fill: HubFill
    var ink: HubInk

    var id: Int { card }
}

struct HubTileModel: Equatable, Identifiable {
    var card: Int
    var index: String
    var title: String
    var fill: HubFill
    var ink: HubInk
    var locked: Bool

    var id: Int { card }
}

struct HubTool: Equatable, Identifiable {
    var id: String
    var title: String
    var detail: String
    var dot: HubFill
    var feature: Feature
}

enum HubBoard {
    static let disclaimer = "Concept prototype. Not affiliated with Instagram. Sample data."

    static let tools: [HubTool] = [
        HubTool(id: "remix", title: "Remix", detail: "Restyle every card in 4 looks", dot: .pink, feature: .remix),
        HubTool(id: "together", title: "Wrapped Together", detail: "Make a joint recap with a friend", dot: .orange, feature: .together),
        HubTool(id: "quiz", title: "Guess My Wrapped", detail: "Turn your year into a Story quiz", dot: .yellow, feature: .quiz),
        HubTool(id: "privacy", title: "Privacy", detail: "Choose what is included and shared", dot: .violet, feature: .privacy),
        HubTool(id: "past-years", title: "Past years", detail: "Your recaps from before", dot: .magenta, feature: .pastYears),
    ]

    static func highlights(in bundle: RunBundle, hidden: Set<Int>) -> [HubHighlight] {
        var items: [HubHighlight] = []
        if !hidden.contains(2),
           let title = bundle.card(number: 2)?.payload.copy?.hubHighlight,
           let detail = bundle.card(number: 2)?.payload.copy?.hubDetail {
            items.append(HubHighlight(card: 2, kicker: "YOUR YEAR IN MEMORIES", title: title, detail: detail, fill: .raised, ink: .white))
        }
        if !hidden.contains(6),
           let title = bundle.card(number: 6)?.payload.copy?.hubHighlight,
           let detail = bundle.card(number: 6)?.payload.copy?.hubDetail {
            items.append(HubHighlight(card: 6, kicker: "MAIN CHARACTER POST", title: title, detail: detail, fill: .yellow, ink: .ink))
        }
        if !hidden.contains(10),
           let title = bundle.card(number: 10)?.payload.category,
           let detail = bundle.card(number: 5)?.payload.copy?.hubDetail {
            items.append(HubHighlight(card: 10, kicker: "PLOT TWIST", title: title, detail: detail, fill: .orange, ink: .ink))
        }
        if !hidden.contains(12),
           let title = flat(bundle.card(number: 12)?.payload.copy?.name),
           let detail = bundle.card(number: 12)?.payload.copy?.side {
            items.append(HubHighlight(card: 12, kicker: "YOUR PERSONALITY", title: title, detail: detail, fill: .magenta, ink: .white))
        }
        return items
    }

    static func tiles(in bundle: RunBundle, hidden: Set<Int>) -> [HubTileModel] {
        bundle.deckNumbers.filter { !hidden.contains($0) }.map { number in
            HubTileModel(
                card: number,
                index: String(format: "%02d", number),
                title: title(in: bundle, card: number),
                fill: fill(for: number),
                ink: ink(for: number),
                locked: number == 8
            )
        }
    }

    static func viewAllTitle(count: Int) -> String {
        "View all \(count)"
    }

    static func title(in bundle: RunBundle, card: Int) -> String {
        switch card {
        case 1:
            return flat(bundle.card(number: 1)?.payload.copy?.headline) ?? "Opening"
        case 2:
            return "Year in memories"
        case 3:
            return bundle.card(number: 3)?.payload.paletteName ?? "Feed color"
        case 4:
            return bundle.card(number: 4)?.payload.topics?.first { $0.isUndercut == true }?.name ?? "Your algorithm"
        case 5:
            return "Rabbit hole"
        case 6:
            return "Main character"
        case 7:
            return "Broke the chat"
        case 8:
            return "Your circle"
        case 9:
            return "3AM club"
        case 10:
            return "Plot twist"
        case 11:
            return "Three clues"
        case 12:
            return flat(bundle.card(number: 12)?.payload.copy?.name) ?? "Your personality"
        case 13:
            return "Share cards"
        default:
            return ""
        }
    }

    private static func flat(_ text: String?) -> String? {
        let value = text?
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    private static func fill(for card: Int) -> HubFill {
        switch card {
        case 1: return .pink
        case 2, 11: return .ghost
        case 3, 13: return .paper
        case 4: return .violet
        case 5, 8: return .orange
        case 6, 10: return .yellow
        case 7: return .green
        case 9: return .navy
        case 12: return .magenta
        default: return .raised
        }
    }

    private static func ink(for card: Int) -> HubInk {
        switch card {
        case 2, 4, 9, 11, 12: return .white
        default: return .ink
        }
    }
}

struct WrappedHub: View {
    var bundle: RunBundle
    var onBack: () -> Void
    var onOpen: (Int) -> Void

    @State private var showsShare = false
    @State private var toast: String?
    private var hidden: Set<Int> { HiddenCards.load() }
    private var highlights: [HubHighlight] { HubBoard.highlights(in: bundle, hidden: hidden) }
    private var tiles: [HubTileModel] { HubBoard.tiles(in: bundle, hidden: hidden) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HubSpace.sectionGap) {
                header
                edition
                hero
                if !highlights.isEmpty {
                    highlightSection
                }
                explore
                tools
                Text(HubBoard.disclaimer)
                    .font(ArchivoFont.font(size: HubSpace.footer, weight: CardSpace.support, width: CardSpace.regular))
                    .foregroundStyle(WrappedColor.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("hub-disclaimer")
            }
            .padding(.horizontal, HubSpace.horizontal)
            .padding(.top, HubSpace.top)
            .padding(.bottom, HubSpace.bottom)
        }
        .background {
            WrappedColor.ink
                .accessibilityIdentifier("wrapped-hub")
                .accessibilityLabel("Wrapped Hub")
        }
        .sheet(isPresented: $showsShare) {
            ShareSheet(bundle: bundle, openedFrom: 13, preferNumbers: false) { message in
                toast = message
            }
        }
        .overlay(alignment: .bottom) {
            if let toast {
                Text(toast)
                    .wrappedType(.caption)
                    .foregroundStyle(WrappedColor.ink)
                    .padding(.horizontal, WrappedSpace.gutter)
                    .frame(minHeight: WrappedSpace.minHit)
                    .background(Capsule().fill(WrappedColor.igWhite))
                    .padding(.bottom, HubSpace.bottom)
                    .accessibilityIdentifier("hub-toast")
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: CardSpace.chromeIcon, weight: .semibold))
                    .foregroundStyle(WrappedColor.igWhite)
                    .frame(width: WrappedSpace.minHit, height: WrappedSpace.minHit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .accessibilityIdentifier("hub-back")
            Spacer()
            HStack(spacing: CardSpace.chipGap) {
                ZStack {
                    Circle().stroke(WrappedColor.storyRing, lineWidth: CardSpace.ringWidth)
                    Circle().stroke(WrappedColor.ink, lineWidth: CardSpace.ringWidth).padding(CardSpace.ringWidth)
                    Text("26")
                        .font(ArchivoFont.font(size: CardSpace.markDigits, weight: CardSpace.heavy, width: CardSpace.regular))
                        .foregroundStyle(WrappedColor.igWhite)
                }
                .frame(width: HubSpace.mark, height: HubSpace.mark)
                .accessibilityHidden(true)
                Text("Wrapped")
                    .font(ArchivoFont.font(size: HubSpace.word, weight: CardSpace.heavy, width: CardSpace.regular))
                    .foregroundStyle(WrappedColor.igWhite)
            }
            Spacer()
            Color.clear.frame(width: WrappedSpace.minHit, height: WrappedSpace.minHit)
        }
    }

    private var edition: some View {
        HStack(spacing: HubSpace.toggleInset) {
            editionButton("Personal", identifier: "hub-edition-personal", selected: true) {}
            editionButton("Creator", identifier: "hub-edition-creator", selected: false) {
                guard let message = Feature.toast(for: .creator) else { return }
                toast = message
            }
        }
        .padding(HubSpace.toggleInset)
        .background(RoundedRectangle(cornerRadius: HubSpace.toggleRadius).fill(WrappedColor.surfaceRaised))
    }

    private func editionButton(_ title: String, identifier: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(ArchivoFont.font(
                    size: HubSpace.summary,
                    weight: selected ? CardSpace.strong : CardSpace.semi,
                    width: CardSpace.regular
                ))
                .foregroundStyle(selected ? WrappedColor.ink : WrappedColor.onInkSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: HubSpace.toggleHeight)
                .background(
                    RoundedRectangle(cornerRadius: HubSpace.toggleButtonRadius)
                        .fill(selected ? WrappedColor.igWhite : Color.clear)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityIdentifier(identifier)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var hero: some View {
        HStack(alignment: .top, spacing: HubSpace.heroGap) {
            Button {
                onOpen(13)
            } label: {
                identityPreview
                    .frame(width: HubSpace.previewWidth, height: HubSpace.previewHeight)
                    .clipShape(RoundedRectangle(cornerRadius: HubSpace.previewRadius))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open your identity card")
            .accessibilityIdentifier("hub-identity")
            VStack(alignment: .leading, spacing: 0) {
                Text(bundle.run.copy.window)
                    .font(ArchivoFont.font(size: HubSpace.windowSize, weight: CardSpace.strong, width: CardSpace.regular))
                    .tracking(HubSpace.windowTracking)
                    .foregroundStyle(WrappedColor.pinkOnDark)
                Text("Your year, in one place.")
                    .font(ArchivoFont.font(size: HubSpace.headline, weight: CardSpace.heavy, width: CardSpace.condensed))
                    .tracking(HubSpace.headlineTracking)
                    .textCase(.uppercase)
                    .foregroundStyle(WrappedColor.igWhite)
                    .padding(.top, CardSpace.chipGap)
                Text(bundle.run.copy.summary)
                    .font(ArchivoFont.font(size: HubSpace.summary, weight: CardSpace.support, width: CardSpace.regular))
                    .foregroundStyle(WrappedColor.onInkSecondary)
                    .padding(.top, CardSpace.chipGap)
                Spacer(minLength: HubSpace.heroGap)
                VStack(spacing: HubSpace.highlightGap) {
                    Button {
                        onOpen(1)
                    } label: {
                        Label("Replay", systemImage: "play.fill")
                            .font(ArchivoFont.font(size: HubSpace.actionText, weight: CardSpace.strong, width: CardSpace.regular))
                            .foregroundStyle(WrappedColor.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: HubSpace.actionHeight)
                            .background(Capsule().fill(WrappedColor.igWhite))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("hub-replay")
                    Button {
                        showsShare = true
                    } label: {
                        Text("Share")
                            .font(ArchivoFont.font(size: HubSpace.actionText, weight: CardSpace.medium, width: CardSpace.regular))
                            .foregroundStyle(WrappedColor.igWhite)
                            .frame(maxWidth: .infinity)
                            .frame(height: HubSpace.actionHeight)
                            .overlay(Capsule().stroke(WrappedColor.sheetDash, lineWidth: HubSpace.stroke))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("hub-share")
                }
            }
            .frame(maxWidth: .infinity, minHeight: HubSpace.previewHeight, alignment: .top)
        }
    }

    @ViewBuilder
    private var identityPreview: some View {
        if let share = bundle.card(number: 13), let reveal = bundle.card(number: 12) {
            IdentityFace(
                card: share,
                reveal: reveal,
                handle: bundle.card(number: 1)?.payload.handle ?? "",
                bottomReserve: 0
            )
            .frame(width: WrappedSpace.frameWidth, height: WrappedSpace.frameHeight, alignment: .top)
            .scaleEffect(HubSpace.previewWidth / WrappedSpace.frameWidth, anchor: .topLeading)
            .frame(width: HubSpace.previewWidth, height: HubSpace.previewHeight, alignment: .topLeading)
            .clipped()
            .allowsHitTesting(false)
        } else {
            RoundedRectangle(cornerRadius: HubSpace.previewRadius).fill(WrappedColor.igMagenta)
        }
    }

    private var highlightSection: some View {
        VStack(alignment: .leading, spacing: CardSpace.chipGap) {
            sectionTitle("Your highlights")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: HubSpace.highlightGap), GridItem(.flexible())], spacing: HubSpace.highlightGap) {
                ForEach(highlights) { item in
                    Button {
                        onOpen(item.card)
                    } label: {
                        highlight(item)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("hub-highlight-\(item.card)")
                }
            }
        }
    }

    private func highlight(_ item: HubHighlight) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(item.kicker)
                .font(ArchivoFont.font(size: HubSpace.highlightKicker, weight: CardSpace.strong, width: CardSpace.regular))
                .tracking(HubSpace.highlightKickerTracking)
                .foregroundStyle(item.ink.color)
            Spacer(minLength: 0)
            Text(item.title)
                .font(ArchivoFont.font(size: HubSpace.highlightBig, weight: CardSpace.heavy, width: CardSpace.condensed))
                .textCase(.uppercase)
                .foregroundStyle(item.ink.color)
            Text(item.detail)
                .font(ArchivoFont.font(size: HubSpace.highlightDetail, weight: CardSpace.medium, width: CardSpace.regular))
                .foregroundStyle(item.ink.color)
        }
        .padding(HubSpace.highlightPad)
        .frame(maxWidth: .infinity, minHeight: HubSpace.highlightHeight, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: HubSpace.highlightRadius).fill(item.fill.color))
    }

    private var explore: some View {
        VStack(alignment: .leading, spacing: CardSpace.chipGap) {
            HStack(alignment: .firstTextBaseline) {
                sectionTitle("Explore your year")
                Spacer()
                Button {
                    onOpen(1)
                } label: {
                    Text(HubBoard.viewAllTitle(count: tiles.count))
                        .font(ArchivoFont.font(size: HubSpace.summary, weight: CardSpace.medium, width: CardSpace.regular))
                        .foregroundStyle(WrappedColor.pinkOnDark)
                        .frame(minHeight: WrappedSpace.minHit)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("hub-view-all")
            }
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: HubSpace.tileGap), count: 3),
                spacing: HubSpace.tileGap
            ) {
                ForEach(tiles) { tile in
                    Button {
                        onOpen(tile.card)
                    } label: {
                        tileFace(tile)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tile.locked ? "\(tile.title). Private" : tile.title)
                    .accessibilityIdentifier("hub-tile-\(tile.card)")
                }
            }
        }
    }

    private func tileFace(_ tile: HubTileModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(tile.index)
                    .font(ArchivoFont.font(size: HubSpace.tileIndex, weight: CardSpace.heavy, width: CardSpace.regular))
                Spacer()
                if tile.locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: HubSpace.lock, weight: .semibold))
                        .accessibilityHidden(true)
                }
            }
            Spacer(minLength: 0)
            Text(tile.title)
                .font(ArchivoFont.font(size: HubSpace.tileTitle, weight: CardSpace.heavy, width: CardSpace.condensed))
                .textCase(.uppercase)
                .lineLimit(2)
        }
        .foregroundStyle(tile.ink.color)
        .padding(HubSpace.tilePad)
        .frame(maxWidth: .infinity, minHeight: HubSpace.tileHeight, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: HubSpace.tileRadius).fill(tile.fill.color))
    }

    private var tools: some View {
        VStack(alignment: .leading, spacing: CardSpace.chipGap) {
            sectionTitle("Make it yours")
            VStack(spacing: 0) {
                ForEach(HubBoard.tools) { tool in
                    Button {
                        guard let message = Feature.toast(for: tool.feature) else { return }
                        toast = message
                    } label: {
                        HStack(spacing: HubSpace.toolGap) {
                            RoundedRectangle(cornerRadius: HubSpace.toolDotRadius)
                                .fill(tool.dot.color)
                                .frame(width: HubSpace.toolDot, height: HubSpace.toolDot)
                            VStack(alignment: .leading, spacing: HubSpace.toolLine) {
                                Text(tool.title)
                                    .font(ArchivoFont.font(size: HubSpace.actionText, weight: CardSpace.medium, width: CardSpace.regular))
                                    .foregroundStyle(WrappedColor.igWhite)
                                Text(tool.detail)
                                    .font(ArchivoFont.font(size: HubSpace.footer, weight: CardSpace.support, width: CardSpace.regular))
                                    .foregroundStyle(WrappedColor.muted)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.system(size: HubSpace.chevron, weight: .semibold))
                                .foregroundStyle(WrappedColor.chevron)
                        }
                        .padding(.horizontal, HubSpace.horizontal)
                        .frame(minHeight: HubSpace.toolHeight)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(tool.title). \(tool.detail)")
                    .accessibilityIdentifier("hub-tool-\(tool.id)")
                    if tool.id != HubBoard.tools.last?.id {
                        Rectangle().fill(WrappedColor.ghostInk).frame(height: HubSpace.hairline)
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: HubSpace.toolRadius).fill(WrappedColor.surface))
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(ArchivoFont.font(size: HubSpace.sectionTitle, weight: CardSpace.heavy, width: CardSpace.regular))
            .foregroundStyle(WrappedColor.igWhite)
    }
}
