import SwiftUI

enum WrappedProvenance: String, CaseIterable, Identifiable {
    case measured
    case estimated
    case inferred

    var id: String { rawValue }

    var title: String {
        switch self {
        case .measured: "Measured"
        case .estimated: "Estimated"
        case .inferred: "Inferred"
        }
    }
}

struct StoryProgressBars: View {
    var count: Int = 13
    var current: Int = 0
    var progress: CGFloat = 0.45
    var foreground: Color = .white
    var trackOpacity: Double = 0.3

    var body: some View {
        HStack(spacing: WrappedSpace.progressGap) {
            ForEach(0 ..< count, id: \.self) { index in
                GeometryReader { proxy in
                    Capsule()
                        .fill(foreground.opacity(trackOpacity))
                    Capsule()
                        .fill(foreground)
                        .frame(width: fillWidth(index: index, total: proxy.size.width))
                }
                .frame(height: WrappedSpace.progressThickness)
            }
        }
        .frame(height: WrappedSpace.progressThickness)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("player-progress")
    }

    private func fillWidth(index: Int, total: CGFloat) -> CGFloat {
        if index < current { return total }
        if index > current { return 0 }
        return total * min(max(progress, 0), 1)
    }
}

struct WrappedTopRow: View {
    var showsInfo: Bool = true
    var isMuted: Bool = false
    var foreground: Color = .white
    var mark: WrappedMark = .gradient
    var innerBorder: Color = WrappedColor.ink
    var outerFill: Color = WrappedColor.ink
    var onInfo: () -> Void = {}
    var onMute: () -> Void = {}
    var onClose: () -> Void = {}

    var body: some View {
        HStack(spacing: CardSpace.chipGap) {
            markView
                .frame(width: WrappedSpace.wrappedMark, height: WrappedSpace.wrappedMark)
                .accessibilityHidden(true)
            Text("Wrapped")
                .font(ArchivoFont.font(size: CardSpace.markWord, weight: CardSpace.strong, width: CardSpace.regular))
                .foregroundStyle(foreground)
            Spacer()
            if showsInfo {
                topButton("Info", systemImage: "info.circle", identifier: "player-info", action: onInfo)
            }
            topButton(
                isMuted ? "Unmute" : "Mute",
                systemImage: isMuted ? "speaker.slash" : "speaker.wave.2",
                identifier: "player-mute",
                action: onMute
            )
            topButton("Close", systemImage: "xmark", identifier: "player-close", action: onClose)
        }
    }

    @ViewBuilder
    private var markView: some View {
        switch mark {
        case .gradient:
            ZStack {
                Circle().stroke(WrappedColor.storyRing, lineWidth: CardSpace.ringWidth)
                Circle().stroke(innerBorder, lineWidth: CardSpace.ringWidth).padding(CardSpace.ringWidth)
                Text("26")
                    .font(ArchivoFont.font(size: CardSpace.markDigits, weight: CardSpace.heavy, width: CardSpace.regular))
                    .foregroundStyle(WrappedColor.igWhite)
            }
        case .ink:
            ZStack {
                Circle().fill(outerFill)
                Circle().strokeBorder(innerBorder, lineWidth: CardSpace.ringWidth)
                Text("26")
                    .font(ArchivoFont.font(size: CardSpace.markDigits, weight: CardSpace.heavy, width: CardSpace.regular))
                    .foregroundStyle(WrappedColor.igWhite)
            }
        case .white:
            ZStack {
                Circle().fill(WrappedColor.igWhite)
                Circle().fill(WrappedColor.ink).padding(CardSpace.ringWidth)
                Circle().stroke(innerBorder, lineWidth: CardSpace.ringWidth).padding(CardSpace.ringWidth)
                Text("26")
                    .font(ArchivoFont.font(size: CardSpace.markDigits, weight: CardSpace.heavy, width: CardSpace.regular))
                    .foregroundStyle(WrappedColor.igWhite)
            }
        }
    }

    private func topButton(
        _ label: String,
        systemImage: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: CardSpace.chromeIcon, weight: .semibold))
                .foregroundStyle(foreground)
                .frame(width: WrappedSpace.minHit, height: WrappedSpace.minHit)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityIdentifier(identifier)
    }
}

struct CardShell<Content: View>: View {
    var background: Color
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .top) {
            background.ignoresSafeArea()
            content()
                .padding(.horizontal, WrappedSpace.gutter)
                .padding(.top, WrappedSpace.contentTop)
        }
    }
}

struct Eyebrow: View {
    var text: String

    var body: some View {
        Text(text)
            .wrappedType(.eyebrow)
            .foregroundStyle(WrappedColor.pinkOnDark)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// One tight line box per explicit break in the card copy.
/// SwiftUI will not compress a paragraph below a line height of 1, so each line is its own text.
struct DisplayHeadline: View {
    var lines: [String]
    var size: CGFloat
    var lineHeight: CGFloat
    var weight: CGFloat
    var width: CGFloat
    var tracking: CGFloat
    var color: Color
    var alignment: HorizontalAlignment

    init(
        copy: String,
        size: CGFloat,
        lineHeight: CGFloat,
        weight: CGFloat = CardSpace.heavy,
        width: CGFloat = CardSpace.condensed,
        tracking: CGFloat = 0,
        color: Color,
        alignment: HorizontalAlignment = .leading
    ) {
        lines = copy.components(separatedBy: "\n")
        self.size = size
        self.lineHeight = lineHeight
        self.weight = weight
        self.width = width
        self.tracking = tracking
        self.color = color
        self.alignment = alignment
    }

    var body: some View {
        VStack(alignment: alignment, spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(ArchivoFont.font(size: size, weight: weight, width: width))
                    .tracking(tracking)
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .fixedSize()
                    .frame(height: size * lineHeight, alignment: .bottom)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(lines.joined(separator: " "))
    }
}

struct BigNumber: View {
    var text: String

    var body: some View {
        Text(text)
            .wrappedType(.bigNumber)
            .foregroundStyle(WrappedColor.ink)
    }
}

struct PhotoTile: View {
    var month: String
    var flagged: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [WrappedColor.surfaceRaised, WrappedColor.igViolet.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            Text(month)
                .font(ArchivoFont.font(size: 11, weight: 800, width: 100))
                .foregroundStyle(WrappedColor.ink)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.white))
                .padding(6)
        }
        .overlay {
            if flagged {
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(WrappedColor.igPink, lineWidth: 3)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel(flagged ? "\(month), top month" : month)
    }
}

struct SwatchStrip: View {
    var swatches: [(hex: String, percent: String)] = [
        ("#1F2A44", "31%"),
        ("#C8A27C", "24%"),
        ("#8B3A3A", "19%"),
        ("#E9E1D3", "15%"),
        ("#4E6B4A", "11%")
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(swatches, id: \.hex) { swatch in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color(swatch.hex))
                        .frame(height: 28)
                    Text(swatch.percent)
                        .wrappedType(.caption)
                        .foregroundStyle(WrappedColor.ink)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(swatch.percent), \(swatch.hex)")
            }
        }
    }

    private func color(_ hex: String) -> Color {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let value = UInt32(cleaned, radix: 16) ?? 0
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        return Color(.sRGB, red: red, green: green, blue: blue)
    }
}

struct CategoryBar: View {
    var name: String = "Streetwear"
    var fraction: CGFloat = 0.31

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name).wrappedType(.title).foregroundStyle(WrappedColor.ink)
                Spacer()
                Text("\(Int((fraction * 100).rounded()))%")
                    .wrappedType(.title)
                    .foregroundStyle(WrappedColor.ink)
            }
            GeometryReader { proxy in
                Capsule().fill(WrappedColor.igYellow.opacity(0.45))
                Capsule()
                    .fill(WrappedColor.ink)
                    .frame(width: proxy.size.width * fraction)
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
    }
}

struct StickerChip: View {
    var eyebrow: String = "Your palette"
    var title: String = "Midnight Camel"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(eyebrow)
                .font(ArchivoFont.font(size: 10, weight: 800, width: 70))
                .foregroundStyle(WrappedColor.igYellow)
                .textCase(.uppercase)
            Text(title)
                .font(ArchivoFont.font(size: 16, weight: 900, width: 62))
                .foregroundStyle(.white)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 6).fill(WrappedColor.ink))
        .rotationEffect(.degrees(-6))
        .accessibilityElement(children: .combine)
    }
}

struct LikeBubble: View {
    var count: String = "2,184"

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "heart.fill")
            Text(count).wrappedType(.title)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 14).fill(WrappedColor.likeRed))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) likes")
    }
}

struct CommentBubble: View {
    var text: String = "418 comments. Unhinged ones."

    var body: some View {
        Text(text)
            .wrappedType(.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(WrappedColor.ink))
    }
}

struct StoryThumb: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(LinearGradient(colors: [WrappedColor.igViolet, WrappedColor.nightNavy], startPoint: .top, endPoint: .bottom))
            .frame(width: 72, height: 120)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(WrappedColor.storyRing, lineWidth: 3)
                    .padding(-4)
            }
            .accessibilityLabel("Story thumbnail")
    }
}

struct ReplyBubbles: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            capsule(width: 72, color: WrappedColor.ink)
            capsule(width: 48, color: .white)
            capsule(width: 64, color: WrappedColor.ink)
        }
        .accessibilityLabel("Replies, contents hidden")
    }

    private func capsule(width: CGFloat, color: Color) -> some View {
        Capsule().fill(color).frame(width: width, height: 14)
    }
}

struct AvatarRing: View {
    var label: String = "dee.films"

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(WrappedColor.igViolet)
                .frame(width: 56, height: 56)
                .overlay(Circle().stroke(WrappedColor.storyRing, lineWidth: 3))
            Text(label)
                .wrappedType(.caption)
                .foregroundStyle(WrappedColor.ink)
                .lineLimit(1)
        }
        .frame(minWidth: WrappedSpace.minHit, minHeight: WrappedSpace.minHit)
        .accessibilityElement(children: .combine)
    }
}

struct ClockFace: View {
    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.25), lineWidth: 10)
            Circle().trim(from: 0.08, to: 0.72)
                .stroke(WrappedColor.igYellow, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle().fill(WrappedColor.nightNavy).padding(16)
            Circle().fill(WrappedColor.igYellow).frame(width: 8, height: 8)
            Capsule().fill(.white).frame(width: 28, height: 3).offset(x: -8).rotationEffect(.degrees(-20))
            Capsule().fill(WrappedColor.igYellow).frame(width: 18, height: 3).offset(x: 6).rotationEffect(.degrees(70))
        }
        .frame(width: 120, height: 120)
        .accessibilityLabel("3:42 AM")
    }
}

struct MonthBars: View {
    var values: [CGFloat] = [3, 2, 4, 3, 5, 22, 41, 58, 64, 71, 80]

    var body: some View {
        let peak = values.max() ?? 1
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                RoundedRectangle(cornerRadius: 2)
                    .fill(value > 10 ? WrappedColor.ink : WrappedColor.igYellow)
                    .frame(height: max(4, 64 * value / peak))
            }
        }
        .frame(height: 64, alignment: .bottom)
        .accessibilityLabel("Monthly bars")
    }
}

struct ClueRow: View {
    var index: String = "01"
    var text: String = "You saved 1,214 posts"

    var body: some View {
        HStack(spacing: 10) {
            Text(index)
                .wrappedType(.caption)
                .foregroundStyle(WrappedColor.igPink)
            Text(text)
                .wrappedType(.body)
                .foregroundStyle(.white)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: WrappedSpace.minHit)
        .background(RoundedRectangle(cornerRadius: 14).fill(WrappedColor.surfaceRaised))
        .accessibilityElement(children: .combine)
    }
}

struct MatchBar: View {
    var primary: CGFloat = 0.7

    var body: some View {
        GeometryReader { proxy in
            Capsule().fill(Color.white.opacity(0.35))
            Capsule()
                .fill(WrappedColor.ink)
                .frame(width: proxy.size.width * primary)
        }
        .frame(height: 8)
        .accessibilityLabel("70 percent Curator match, 30 percent Ghost match")
    }
}

struct SharePill: View {
    var title: String = "Share"
    var inverted: Bool = false
    var expands: Bool = false
    var identifier: String = "card-share"
    var action: () -> Void = {}

    private var ink: Color { inverted ? WrappedColor.ink : WrappedColor.igWhite }
    private var fill: Color { inverted ? WrappedColor.igWhite : WrappedColor.ink }

    var body: some View {
        Button(action: action) {
            HStack(spacing: CardSpace.chipGap) {
                Image(systemName: "paperplane.fill")
                Text(title)
                    .font(ArchivoFont.font(size: CardSpace.shareSize, weight: CardSpace.strong, width: CardSpace.regular))
            }
            .foregroundStyle(ink)
            .padding(.leading, CardSpace.chipTextPad + CardSpace.chipPadV)
            .padding(.trailing, WrappedSpace.gutter)
            .frame(maxWidth: expands ? .infinity : nil)
            .frame(height: WrappedSpace.pillHeight)
            .background(Capsule().fill(fill))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityIdentifier(identifier)
    }
}

struct PrivatePill: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
            Text("Private card · only you see this")
                .wrappedType(.caption)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .frame(minHeight: WrappedSpace.minHit)
        .background(Capsule().fill(WrappedColor.ink))
        .accessibilityElement(children: .combine)
    }
}

struct ProvenanceBadge: View {
    var provenance: WrappedProvenance = .measured

    var body: some View {
        Text(provenance.title)
            .wrappedType(.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .overlay {
                Capsule().stroke(Color.white, style: stroke)
            }
            .accessibilityLabel(provenance.title)
    }

    private var stroke: StrokeStyle {
        switch provenance {
        case .measured:
            StrokeStyle(lineWidth: 1)
        case .estimated:
            StrokeStyle(lineWidth: 1, dash: [2, 2])
        case .inferred:
            StrokeStyle(lineWidth: 1, dash: [6, 3])
        }
    }
}

struct SegmentedToggle: View {
    var options: [String]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button {
                    selection = index
                } label: {
                    Text(option)
                        .wrappedType(.caption)
                        .foregroundStyle(selection == index ? WrappedColor.ink : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: WrappedSpace.compactControl)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selection == index ? Color.white : Color.clear)
                        )
                        .contentShape(Rectangle())
                        .frame(minHeight: WrappedSpace.minHit)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option)
                .accessibilityAddTraits(selection == index ? .isSelected : [])
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 14).fill(WrappedColor.surface))
    }
}

struct ToggleChip: View {
    var title: String
    var isOn: Bool
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                }
                Text(title).wrappedType(.caption)
            }
            .foregroundStyle(isOn ? WrappedColor.ink : .white)
            .padding(.horizontal, 12)
            .frame(height: WrappedSpace.compactControl)
            .background(Capsule().fill(isOn ? Color.white : Color.clear))
            .overlay(Capsule().stroke(Color.white.opacity(isOn ? 0 : 0.7), lineWidth: 1))
            .contentShape(Capsule())
            .padding(.vertical, (WrappedSpace.minHit - WrappedSpace.compactControl) / 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

struct HubTile: View {
    var index: String = "01"
    var title: String = "Opening"
    var color: Color = WrappedColor.igPink

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(index).wrappedType(.caption).foregroundStyle(color == WrappedColor.igYellow ? WrappedColor.ink : .white)
            Text(title)
                .font(ArchivoFont.font(size: 13, weight: 900, width: 62))
                .foregroundStyle(color == WrappedColor.igYellow ? WrappedColor.ink : .white)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .bottomLeading)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(color))
        .accessibilityElement(children: .combine)
    }
}

struct HighlightTile: View {
    var eyebrow: String = "Your year in memories"
    var title: String = "11 months"
    var detail: String = "Play the 15-second recap"
    var color: Color = WrappedColor.igPink

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow).wrappedType(.eyebrow).foregroundStyle(WrappedColor.ink.opacity(0.7))
            Text(title).wrappedType(.title).foregroundStyle(WrappedColor.ink)
            Text(detail).wrappedType(.caption).foregroundStyle(WrappedColor.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(color))
        .accessibilityElement(children: .combine)
    }
}

struct ToolRow: View {
    var title: String = "Remix"
    var detail: String = "Restyle every card in 4 looks"
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle().fill(WrappedColor.igPink).frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).wrappedType(.body).foregroundStyle(.white)
                    Text(detail).wrappedType(.caption).foregroundStyle(WrappedColor.muted)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(minHeight: WrappedSpace.minHit)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title). \(detail)")
    }
}

struct ShareActionButton: View {
    var title: String = "Your story"
    var systemImage: String = "plus"
    var prominent: Bool = true
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    if prominent {
                        Circle().stroke(WrappedColor.storyRing, lineWidth: 3)
                    } else {
                        Circle().fill(WrappedColor.surfaceRaised)
                    }
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 52, height: 52)
                Text(title)
                    .wrappedType(.caption)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(minWidth: WrappedSpace.minHit, minHeight: WrappedSpace.minHit)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

enum PersonSwatch: Int, CaseIterable {
    case pink, orange, violet, green, yellow

    var fill: Color {
        switch self {
        case .pink: WrappedColor.igPink
        case .orange: WrappedColor.igOrange
        case .violet: WrappedColor.igViolet
        case .green: WrappedColor.closeGreen
        case .yellow: WrappedColor.igYellow
        }
    }

    var usesInk: Bool { self == .green || self == .yellow }

    static func forHandle(_ handle: String) -> PersonSwatch {
        let sum = PersonAvatar.bare(handle).unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let all = Self.allCases
        return all[sum % all.count]
    }
}

struct PersonAvatar: View {
    var handle: String
    var photo: String?

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            face(side: side)
                .frame(width: side, height: side)
                .clipShape(Circle())
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func face(side: CGFloat) -> some View {
        if let photo, let image = BundlePhoto.image(named: photo) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            let swatch = PersonSwatch.forHandle(handle)
            ZStack {
                Circle().fill(swatch.fill)
                Text(Self.initial(handle))
                    .font(.system(size: side * IGSpace.avatarInitialRatio, weight: .semibold))
                    .foregroundStyle(swatch.usesInk ? WrappedColor.ink : WrappedColor.igWhite)
            }
        }
    }

    static func bare(_ handle: String) -> String {
        handle.replacingOccurrences(of: "@", with: "")
    }

    static func initial(_ handle: String) -> String {
        let name = bare(handle)
        guard let first = name.first else { return "" }
        return String(first).uppercased()
    }

    /// Canonical headshot name. A missing file falls back to the initial.
    static func photoName(for handle: String) -> String {
        switch bare(handle) {
        case "maya.lens": "maya-profile"
        case "dee.films": "friend-dee"
        case "jules.mp": "friend-jules"
        case "nico_k": "friend-nico"
        case "sam.wav": "friend-sam"
        case "tori.eats": "friend-tori"
        default: "friend-\(bare(handle))"
        }
    }
}
