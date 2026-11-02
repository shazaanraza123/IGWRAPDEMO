import SwiftUI

enum PersonalityArchetype: String, CaseIterable, Identifiable {
    case curator
    case ghost
    case reelDealer
    case mainCharacter
    case closeFriend
    case trendspotter
    case socialButterfly
    case archivist

    var id: String { rawValue }

    var title: String {
        switch self {
        case .curator: "The Curator"
        case .ghost: "The Ghost"
        case .reelDealer: "The Reel Dealer"
        case .mainCharacter: "The Main Character"
        case .closeFriend: "The Close Friend"
        case .trendspotter: "The Trendspotter"
        case .socialButterfly: "The Social Butterfly"
        case .archivist: "The Archivist"
        }
    }

    var blurb: String {
        switch self {
        case .curator: "Saves a lot, posts a little"
        case .ghost: "Sees every Story, rarely likes or posts"
        case .reelDealer: "Top Reel sender to friends"
        case .mainCharacter: "Posts often, and it lands"
        case .closeFriend: "Lives in Close Friends and DMs"
        case .trendspotter: "Catches audio and topics early"
        case .socialButterfly: "Spreads love across many accounts"
        case .archivist: "Stories nearly daily, grid barely touched"
        }
    }

    var field: Color {
        switch self {
        case .curator: WrappedColor.igMagenta
        case .ghost: WrappedColor.ghostInk
        case .reelDealer: WrappedColor.igOrange
        case .mainCharacter: WrappedColor.igYellow
        case .closeFriend: WrappedColor.closeGreen
        case .trendspotter: WrappedColor.igViolet
        case .socialButterfly: WrappedColor.igPink
        case .archivist: WrappedColor.paper
        }
    }

    var foreground: Color {
        switch self {
        case .curator, .ghost, .trendspotter: .white
        default: WrappedColor.ink
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .curator: "Curator mark: three stacked bookmarks"
        case .ghost: "Ghost mark: an empty dashed story ring with two eyes"
        case .reelDealer: "Reel Dealer mark: three Reels fanned like playing cards"
        case .mainCharacter: "Main Character mark: a sparkle inside a bold ring"
        case .closeFriend: "Close Friend mark: a star inside a filled circle"
        case .trendspotter: "Trendspotter mark: a rising audio waveform inside a ring"
        case .socialButterfly: "Social Butterfly mark: five overlapping story rings"
        case .archivist: "Archivist mark: a calendar grid of daily story rings"
        }
    }
}

struct PersonalityMark: View {
    var archetype: PersonalityArchetype
    var size: CGFloat = 88

    var body: some View {
        Canvas { context, canvasSize in
            let scale = min(canvasSize.width, canvasSize.height) / 140
            var transform = CGAffineTransform.identity
            transform = transform.scaledBy(x: scale, y: scale)
            context.concatenate(transform)
            draw(archetype, in: &context)
        }
        .frame(width: size, height: size)
        .accessibilityLabel(archetype.accessibilityLabel)
    }

    private func draw(_ archetype: PersonalityArchetype, in context: inout GraphicsContext) {
        switch archetype {
        case .curator:
            bookmark(context: &context, origin: CGPoint(x: 22, y: 18), color: WrappedColor.igYellow)
            bookmark(context: &context, origin: CGPoint(x: 48, y: 30), color: WrappedColor.igOrange)
            bookmark(context: &context, origin: CGPoint(x: 74, y: 42), color: .white)
        case .ghost:
            strokeCircle(in: &context, radius: 56, width: 8, color: .white, dash: [14, 10])
            fillEllipse(in: &context, center: CGPoint(x: 56, y: 66), radius: CGSize(width: 7, height: 11), color: .white)
            fillEllipse(in: &context, center: CGPoint(x: 84, y: 66), radius: CGSize(width: 7, height: 11), color: .white)
        case .reelDealer:
            reelCard(in: &context, degrees: -22, color: WrappedColor.ink, play: false)
            reelCard(in: &context, degrees: 0, color: WrappedColor.igPink, play: false)
            reelCard(in: &context, degrees: 22, color: .white, play: true)
        case .mainCharacter:
            strokeCircle(in: &context, radius: 56, width: 10, color: WrappedColor.ink, dash: [])
            context.fill(sparkle(), with: .color(WrappedColor.ink))
        case .closeFriend:
            context.fill(Path(ellipseIn: CGRect(x: 12, y: 12, width: 116, height: 116)), with: .color(WrappedColor.ink))
            context.fill(star(), with: .color(WrappedColor.closeGreen))
        case .trendspotter:
            strokeCircle(in: &context, radius: 56, width: 8, color: .white, dash: [])
            let bars: [(CGFloat, CGFloat, CGFloat, Color)] = [
                (36, 80, 12, .white),
                (48, 72, 20, .white),
                (60, 64, 28, .white),
                (72, 54, 38, .white),
                (84, 44, 48, WrappedColor.igYellow),
                (96, 34, 58, WrappedColor.igYellow)
            ]
            for bar in bars {
                let rect = CGRect(x: bar.0, y: bar.1, width: 8, height: bar.2)
                context.fill(Path(roundedRect: rect, cornerRadius: 4), with: .color(bar.3))
            }
        case .socialButterfly:
            let rings: [(CGFloat, CGFloat, CGFloat)] = [(44, 46, 22), (96, 46, 22), (44, 96, 18), (96, 96, 18)]
            for ring in rings {
                let rect = CGRect(x: ring.0 - ring.2, y: ring.1 - ring.2, width: ring.2 * 2, height: ring.2 * 2)
                context.stroke(Path(ellipseIn: rect), with: .color(WrappedColor.ink), lineWidth: 7)
            }
            context.fill(Path(ellipseIn: CGRect(x: 50, y: 50, width: 40, height: 40)), with: .color(WrappedColor.ink))
        case .archivist:
            let empty: Set<Int> = [5, 13, 22]
            for index in 0 ..< 28 {
                let x = 16 + CGFloat(index % 7) * 18
                let y = 34 + CGFloat(index / 7) * 22
                let rect = CGRect(x: x - 7, y: y - 7, width: 14, height: 14)
                let circle = Path(ellipseIn: rect)
                if empty.contains(index) {
                    context.stroke(circle, with: .color(WrappedColor.ink), lineWidth: 2.5)
                } else {
                    context.fill(circle, with: .color(WrappedColor.ink))
                    context.stroke(circle, with: .color(WrappedColor.ink), lineWidth: 2.5)
                }
            }
        }
    }

    private func bookmark(context: inout GraphicsContext, origin: CGPoint, color: Color) {
        var path = Path()
        path.move(to: origin)
        path.addLine(to: CGPoint(x: origin.x + 44, y: origin.y))
        path.addLine(to: CGPoint(x: origin.x + 44, y: origin.y + 80))
        path.addLine(to: CGPoint(x: origin.x + 22, y: origin.y + 64))
        path.addLine(to: CGPoint(x: origin.x, y: origin.y + 80))
        path.closeSubpath()
        context.fill(path, with: .color(color))
    }

    private func strokeCircle(
        in context: inout GraphicsContext,
        radius: CGFloat,
        width: CGFloat,
        color: Color,
        dash: [CGFloat]
    ) {
        let rect = CGRect(x: 70 - radius, y: 70 - radius, width: radius * 2, height: radius * 2)
        let style = StrokeStyle(lineWidth: width, lineCap: .butt, dash: dash)
        context.stroke(Path(ellipseIn: rect), with: .color(color), style: style)
    }

    private func fillEllipse(
        in context: inout GraphicsContext,
        center: CGPoint,
        radius: CGSize,
        color: Color
    ) {
        let rect = CGRect(
            x: center.x - radius.width,
            y: center.y - radius.height,
            width: radius.width * 2,
            height: radius.height * 2
        )
        context.fill(Path(ellipseIn: rect), with: .color(color))
    }

    private func reelCard(in context: inout GraphicsContext, degrees: CGFloat, color: Color, play: Bool) {
        let rect = CGRect(x: 45, y: 30, width: 50, height: 76)
        let pivot = CGPoint(x: 70, y: 120)
        let transform = CGAffineTransform(translationX: pivot.x, y: pivot.y)
            .rotated(by: degrees * .pi / 180)
            .translatedBy(x: -pivot.x, y: -pivot.y)
        context.fill(Path(roundedRect: rect, cornerRadius: 9).applying(transform), with: .color(color))
        if play {
            var triangle = Path()
            triangle.move(to: CGPoint(x: 78, y: 60))
            triangle.addLine(to: CGPoint(x: 78, y: 84))
            triangle.addLine(to: CGPoint(x: 98, y: 72))
            triangle.closeSubpath()
            context.fill(triangle.applying(transform), with: .color(WrappedColor.ink))
        }
    }

    private func sparkle() -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 70, y: 30))
        path.addCurve(
            to: CGPoint(x: 110, y: 70),
            control1: CGPoint(x: 72.5, y: 51),
            control2: CGPoint(x: 89, y: 67.5)
        )
        path.addCurve(
            to: CGPoint(x: 70, y: 110),
            control1: CGPoint(x: 89, y: 72.5),
            control2: CGPoint(x: 72.5, y: 89)
        )
        path.addCurve(
            to: CGPoint(x: 30, y: 70),
            control1: CGPoint(x: 67.5, y: 89),
            control2: CGPoint(x: 51, y: 72.5)
        )
        path.addCurve(
            to: CGPoint(x: 70, y: 30),
            control1: CGPoint(x: 51, y: 67.5),
            control2: CGPoint(x: 67.5, y: 51)
        )
        path.closeSubpath()
        return path
    }

    private func star() -> Path {
        let points = [
            CGPoint(x: 70, y: 34),
            CGPoint(x: 80.6, y: 55.5),
            CGPoint(x: 104.3, y: 58.9),
            CGPoint(x: 87.1, y: 75.7),
            CGPoint(x: 91.2, y: 99.3),
            CGPoint(x: 70, y: 88.1),
            CGPoint(x: 48.8, y: 99.3),
            CGPoint(x: 52.9, y: 75.7),
            CGPoint(x: 35.7, y: 58.9),
            CGPoint(x: 59.4, y: 55.5)
        ]
        var path = Path()
        path.move(to: points[0])
        points.dropFirst().forEach { path.addLine(to: $0) }
        path.closeSubpath()
        return path
    }
}
