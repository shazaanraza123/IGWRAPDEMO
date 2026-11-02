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
    /// Instagram shell, measured from `design/reference/instagram/01-home.png`.
    static let igBackground = Color(hex: 0x000000)
    static let igWhite = Color(hex: 0xFFFFFF)
    static let igTabBar = Color(hex: 0x161D25)
    static let igTabChip = Color(hex: 0x464A53)
    static let igIcon = Color(hex: 0xB9BCC1)
    static let igRingSeen = Color(hex: 0x464D53)

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
        ("ghostInk", ghostInk),
        ("igBackground", igBackground),
        ("igWhite", igWhite),
        ("igTabBar", igTabBar),
        ("igTabChip", igTabChip),
        ("igIcon", igIcon),
        ("igRingSeen", igRingSeen)
    ]
}

/// Chrome positions from `01-home.png`, mapped onto the 390×844 frame.
enum IGSpace {
    static let topBarHeight: CGFloat = 108
    static let iconCenterY: CGFloat = 80
    static let iconHit: CGFloat = 44
    static let chromeIcon: CGFloat = 24
    static let plusCenterX: CGFloat = 37
    static let heartCenterX: CGFloat = 351
    static let wordmarkWidth: CGFloat = 132
    static let wordmarkHeight: CGFloat = 28
    static let unreadDot: CGFloat = 8
    static let storyDiameter: CGFloat = 74
    static let storyGap: CGFloat = 19
    static let storyLeading: CGFloat = 7
    static let storyTopGap: CGFloat = 8
    static let storyLabelGap: CGFloat = 8
    static let ringStroke: CGFloat = 2.5
    static let storyBadge: CGFloat = 22
    static let bannerInset: CGFloat = 12
    static let bannerRadius: CGFloat = 18
    static let bannerGap: CGFloat = 12
    static let postAvatar: CGFloat = 32
    static let postInset: CGFloat = 12
    static let postTopGap: CGFloat = 10
    static let postAspect: CGFloat = 4.0 / 5.0
    static let tabBarWidth: CGFloat = 338
    static let tabBarHeight: CGFloat = 56
    static let tabBarLeading: CGFloat = 25
    static let tabBarBottom: CGFloat = 32
    static let tabChipWidth: CGFloat = 56
    static let tabChipHeight: CGFloat = 36
    static let tabChipRadius: CGFloat = 12
    static let tabCount: CGFloat = 5
    static let profileDot: CGFloat = 26
    static let tabClearance: CGFloat = 96
    /// Story viewer chrome from `05-story-viewer.png` (472×1024, scaled onto 390×844).
    /// Open and close durations from `video-story-open-close.mp4`: the card is full by ~0.30s after the tap, and the swipe release is gone within ~0.18s.
    static let viewerProgressTop: CGFloat = 66
    static let viewerProgressHeight: CGFloat = 2
    static let viewerProgressInset: CGFloat = 8
    static let viewerHeaderGap: CGFloat = 4
    static let viewerReplyBottom: CGFloat = 42
    static let viewerReplyIcon: CGFloat = 36
    static let viewerReplyStroke: CGFloat = 1
    static let viewerCardRadius: CGFloat = 20
    static let viewerDragMinimum: CGFloat = 12
    static let viewerDismissTravel: CGFloat = 120
    static let viewerDismissVelocity: CGFloat = 900
    static let viewerDismissScale: CGFloat = 0.86
    static let viewerOpen: Double = 0.30
    static let viewerDismiss: Double = 0.18
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

/// Motion from UIUX §6 and APPFLOW §2. The cube reuses the card-enter spring. Reduce Motion is the 150 ms crossfade.
enum WrappedMotion {
    static let cardEnterResponse: Double = 0.45
    static let cardEnterDamping: Double = 0.85
    static let reduceMotion: Double = 0.15
    static let chapterCrossfade: Double = 0.8
    static let defaultCardDuration: TimeInterval = 6
    static let longCardDuration: TimeInterval = 9
    static let longCardNumbers: Set<Int> = [2, 10, 12]
    static let cubePerspective: CGFloat = 0.6
    static let clockTick: TimeInterval = 1.0 / 30.0
}

private extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}
