import SwiftUI

enum StyleguideSection: String, CaseIterable, Identifiable {
    case colors
    case type
    case components
    case controls
    case marks
    case overlay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .colors: "Colors"
        case .type: "Type"
        case .components: "Components"
        case .controls: "Controls"
        case .marks: "Marks"
        case .overlay: "Overlay"
        }
    }

    static func launched() -> StyleguideSection {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flag = arguments.firstIndex(of: "--styleguide") else { return .colors }
        let next = arguments.index(after: flag)
        guard arguments.indices.contains(next), let section = StyleguideSection(rawValue: arguments[next]) else {
            return .colors
        }
        return section
    }
}

/// Names from the UI brief, plus the canvas and the debug overlay.
enum StyleguideCatalog {
    static let componentNames = [
        "StoryProgressBars",
        "WrappedTopRow",
        "CardShell",
        "Eyebrow",
        "DisplayHeadline",
        "BigNumber",
        "PhotoTile",
        "SwatchStrip",
        "CategoryBar",
        "StickerChip",
        "LikeBubble",
        "CommentBubble",
        "StoryThumb",
        "ReplyBubbles",
        "AvatarRing",
        "ClockFace",
        "MonthBars",
        "ClueRow",
        "PersonalityMark",
        "MatchBar",
        "SharePill",
        "PrivatePill",
        "ProvenanceBadge",
        "SegmentedToggle",
        "ToggleChip",
        "HubTile",
        "HighlightTile",
        "ToolRow",
        "ShareActionButton",
        "DesignCanvas",
        "ReferenceOverlay"
    ]
}

struct StyleguideView: View {
    @State private var section: StyleguideSection
    @State private var segment = 0
    @State private var chipOn = true

    init() {
        ArchivoFont.registerIfNeeded()
        _section = State(initialValue: StyleguideSection.launched())
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(StyleguideSection.allCases) { item in
                        Button {
                            section = item
                        } label: {
                            Text(item.title)
                                .wrappedType(.caption)
                                .foregroundStyle(section == item ? WrappedColor.ink : .white)
                                .padding(.horizontal, 12)
                                .frame(height: WrappedSpace.compactControl)
                                .background(Capsule().fill(section == item ? Color.white : WrappedColor.surfaceRaised))
                                .frame(minHeight: WrappedSpace.minHit)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(item.title)
                        .accessibilityAddTraits(section == item ? .isSelected : [])
                    }
                }
                .padding(.horizontal, WrappedSpace.gutter)
            }
            .padding(.top, 8)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch section {
                    case .colors: colorSection
                    case .type: typeSection
                    case .components: componentSection
                    case .controls: controlSection
                    case .marks: markSection
                    case .overlay: overlaySection
                    }
                }
                .padding(WrappedSpace.gutter)
                .padding(.bottom, 32)
            }
        }
        .background(WrappedColor.ink.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Tokens")
            ForEach(WrappedColor.all, id: \.name) { token in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(token.color)
                        .frame(width: 44, height: 28)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    Text(token.name)
                        .wrappedType(.body)
                        .foregroundStyle(.white)
                }
                .accessibilityElement(children: .combine)
            }
            RoundedRectangle(cornerRadius: 8)
                .fill(WrappedColor.storyRing)
                .frame(height: 28)
                .accessibilityLabel("Story ring gradient")
        }
    }

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Type")
            ForEach(WrappedTextStyle.allCases) { style in
                VStack(alignment: .leading, spacing: 4) {
                    Text(style.rawValue)
                        .wrappedType(.caption)
                        .foregroundStyle(WrappedColor.muted)
                    Text(style.spec)
                        .wrappedType(.caption)
                        .foregroundStyle(WrappedColor.pinkOnDark)
                    Text(sample(for: style))
                        .wrappedType(style)
                        .foregroundStyle(style == .igChrome ? .white : WrappedColor.paper)
                        .lineLimit(2)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var componentSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionTitle("Components")
            labeled("StoryProgressBars") { StoryProgressBars() }
            labeled("WrappedTopRow") { WrappedTopRow() }
            labeled("CardShell") {
                CardShell(background: WrappedColor.igPink) {
                    Text("Card")
                        .wrappedType(.title)
                        .foregroundStyle(WrappedColor.ink)
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            labeled("Eyebrow") { Eyebrow(text: "Your habits") }
            labeled("DisplayHeadline") {
                DisplayHeadline(text: "Plot twist.")
                    .padding(12)
                    .background(WrappedColor.paper)
            }
            labeled("BigNumber") {
                BigNumber(text: "1,214")
                    .padding(12)
                    .background(WrappedColor.paper)
            }
            labeled("PhotoTile") { PhotoTile(month: "AUG", flagged: true).frame(width: 96) }
            labeled("SwatchStrip") { SwatchStrip().padding(12).background(WrappedColor.paper) }
            labeled("CategoryBar") { CategoryBar().padding(12).background(WrappedColor.igOrange) }
            labeled("StickerChip") { StickerChip().frame(maxWidth: .infinity, alignment: .leading) }
            labeled("LikeBubble") { LikeBubble() }
            labeled("CommentBubble") { CommentBubble() }
            labeled("StoryThumb") { StoryThumb() }
            labeled("ReplyBubbles") { ReplyBubbles() }
            labeled("AvatarRing") { AvatarRing().padding(8).background(WrappedColor.paper) }
            labeled("ClockFace") { ClockFace() }
            labeled("MonthBars") { MonthBars() }
        }
    }

    private var controlSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionTitle("Controls")
            labeled("ClueRow") { ClueRow() }
            labeled("PersonalityMark") { PersonalityMark(archetype: .curator) }
            labeled("MatchBar") { MatchBar() }
            labeled("SharePill") { SharePill() }
            labeled("PrivatePill") { PrivatePill() }
            labeled("ProvenanceBadge") {
                HStack {
                    ForEach(WrappedProvenance.allCases) { item in
                        ProvenanceBadge(provenance: item)
                    }
                }
            }
            labeled("SegmentedToggle") {
                SegmentedToggle(options: ["Identity card", "Numbers card"], selection: $segment)
            }
            labeled("ToggleChip") {
                ToggleChip(title: "More of this", isOn: chipOn) { chipOn.toggle() }
            }
            labeled("HubTile") { HubTile().frame(width: 120) }
            labeled("HighlightTile") { HighlightTile() }
            labeled("ToolRow") { ToolRow().background(RoundedRectangle(cornerRadius: 12).fill(WrappedColor.surface)) }
            labeled("ShareActionButton") {
                HStack {
                    ShareActionButton()
                    ShareActionButton(title: "Send", systemImage: "paperplane", prominent: false)
                }
            }
        }
    }

    private var markSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Personality marks")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(PersonalityArchetype.allCases) { archetype in
                    VStack(alignment: .leading, spacing: 8) {
                        PersonalityMark(archetype: archetype, size: 72)
                        Text(archetype.title)
                            .font(ArchivoFont.font(size: 14, weight: 900, width: 62))
                            .foregroundStyle(archetype.foreground)
                            .textCase(.uppercase)
                    }
                    .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(archetype.field))
                }
            }
        }
    }

    private var overlaySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Reference overlay")
            Text("Reference image at 50% over the card.")
                .wrappedType(.caption)
                .foregroundStyle(WrappedColor.muted)
            RoundedRectangle(cornerRadius: 16)
                .fill(WrappedColor.igMagenta)
                .frame(height: 220)
                .referenceOverlay(image: Image(systemName: "circle.grid.cross.fill"), opacity: 0.5)
                .accessibilityLabel("Reference overlay at 50 percent")
            sectionTitle("Design canvas")
            DesignCanvas {
                WrappedColor.igPink
                    .overlay(alignment: .topLeading) {
                        Text("390 × 844")
                            .wrappedType(.title)
                            .foregroundStyle(WrappedColor.ink)
                            .padding(WrappedSpace.gutter)
                    }
            }
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .wrappedType(.title)
            .foregroundStyle(.white)
    }

    private func labeled<Content: View>(_ name: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .wrappedType(.caption)
                .foregroundStyle(WrappedColor.muted)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sample(for style: WrappedTextStyle) -> String {
        switch style {
        case .hero: "Aa"
        case .display: "Plot twist."
        case .bigNumber: "1,214"
        case .title: "Streetwear"
        case .body: "Built from your own posts."
        case .eyebrow: "Your habits"
        case .caption: "Measured · posted Jul 19"
        case .igChrome: "maya.lens"
        }
    }
}

#if DEBUG
#Preview {
    StyleguideView()
}
#endif
