import SwiftUI

/// Named colors and spacing. Feature views use these and never raw hex.
enum WrappedColor {
    static let ink = Color(hex: 0x0B0B0D)
    static let paper = Color(hex: 0xF7F3EC)
    static let igYellow = Color(hex: 0xFFD600)
    static let igOrange = Color(hex: 0xFF7A00)
    static let igPink = Color(hex: 0xFF0069)
    static let igMagenta = Color(hex: 0xD300C5)
    static let igViolet = Color(hex: 0x7638FA)
    static let closeGreen = Color(hex: 0x27C866)
    static let nightNavy = Color(hex: 0x141B4D)
    static let likeRed = Color(hex: 0xFF3040)
    static let pinkOnDark = Color(hex: 0xFF5C9A)
    static let surface = Color(hex: 0x17171B)
    static let surfaceRaised = Color(hex: 0x1E1E22)
    static let muted = Color(hex: 0xA1A1AA)
    static let sheet = Color(hex: 0x121214)
    /// Ghost mark field. Distinct from `ink`.
    static let ghostInk = Color(hex: 0x26262B)

    static let storyRing = AngularGradient(
        colors: [igYellow, igOrange, igPink, igMagenta, igViolet, igYellow],
        center: .center,
        startAngle: .degrees(200),
        endAngle: .degrees(560)
    )

    static let all: [(name: String, color: Color)] = [
        ("ink", ink),
        ("paper", paper),
        ("igYellow", igYellow),
        ("igOrange", igOrange),
        ("igPink", igPink),
        ("igMagenta", igMagenta),
        ("igViolet", igViolet),
        ("closeGreen", closeGreen),
        ("nightNavy", nightNavy),
        ("likeRed", likeRed),
        ("pinkOnDark", pinkOnDark),
        ("surface", surface),
        ("surfaceRaised", surfaceRaised),
        ("muted", muted),
        ("sheet", sheet),
        ("ghostInk", ghostInk)
    ]
}

enum WrappedSpace {
    static let frameWidth: CGFloat = 390
    static let frameHeight: CGFloat = 844
    static let gutter: CGFloat = 20
    static let gridGap: CGFloat = 4
    static let pillHeight: CGFloat = 50
    static let pillBottomInset: CGFloat = 26
    static let progressTop: CGFloat = 50
    static let topRowMinY: CGFloat = 60
    static let topRowMaxY: CGFloat = 104
    static let contentTop: CGFloat = 128
    static let minHit: CGFloat = 44
    static let compactControl: CGFloat = 36
    static let progressThickness: CGFloat = 3
    static let progressGap: CGFloat = 3
    static let wrappedMark: CGFloat = 30
}

private extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}
