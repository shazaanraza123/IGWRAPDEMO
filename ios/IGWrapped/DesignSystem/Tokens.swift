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
    /// Secondary line on the year card, from `P02-Memories.dc.html`.
    static let onInkSecondary = Color(hex: 0xD4D4D8)
    /// Feed-color eyebrow, from `P08-Palette.dc.html`.
    static let paletteEyebrow = Color(hex: 0x6B21A8)
    static let algorithmTileA = Color(hex: 0x8F5BFF)
    static let algorithmTileB = Color(hex: 0x5A1FD6)
    static let algorithmTileC = Color(hex: 0xA77CFF)
    static let paletteMidnight = Color(hex: 0x1F2A44)
    static let paletteCamel = Color(hex: 0xC8A27C)
    static let paletteWine = Color(hex: 0x8B3A3A)
    static let paletteCream = Color(hex: 0xE9E1D3)
    static let paletteOlive = Color(hex: 0x4E6B4A)
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
    /// Music level while a year montage is playing.
    static let duckedVolume: Float = 0.25
}

/// Positions from the card HTML. 1 CSS px = 1 pt.
enum CardSpace {
    static let chromeLeading: CGFloat = 12
    static let chromeTrailing: CGFloat = 10
    static let chromeGap: CGFloat = 10
    static let chromeIcon: CGFloat = 22
    static let heavy: CGFloat = 900
    static let strong: CGFloat = 800
    static let medium: CGFloat = 700
    static let support: CGFloat = 500
    static let condensed: CGFloat = 62
    static let semiCondensed: CGFloat = 72
    static let regular: CGFloat = 100
    static let titleWidth: CGFloat = 70
    static let markDigits: CGFloat = 11
    static let markWord: CGFloat = 14
    static let kicker: CGFloat = 10
    static let kickerTracking: CGFloat = 1
    static let openingGridTop: CGFloat = 132
    static let openingBadgeLeft: CGFloat = 133
    static let openingBadgeTop: CGFloat = 125
    static let openingBadge: CGFloat = 124
    static let openingBadgeBorder: CGFloat = 5
    static let openingBadgePad: CGFloat = 10
    static let openingYearSize: CGFloat = 64
    static let openingYearTracking: CGFloat = -2
    static let openingYearLine: CGFloat = 0.8
    static let openingCopyTop: CGFloat = 392
    static let openingCopyGap: CGFloat = 14
    static let openingHandleSize: CGFloat = 20
    static let openingHeadline: CGFloat = 72
    static let openingHeadlineTracking: CGFloat = -1.5
    static let openingHeadlineLine: CGFloat = 0.86
    static let openingSupport: CGFloat = 16
    static let openingSupportLine: CGFloat = 1.35
    static let openingSupportWidth: CGFloat = 270
    static let openingHintBottom: CGFloat = 40
    static let openingHint: CGFloat = 15
    static let hintIcon: CGFloat = 18
    static let hintPulse: CGFloat = 1.06
    static let openingOuterRadius: CGFloat = 146
    static let openingMidRadius: CGFloat = 106
    static let openingInnerRadius: CGFloat = 86
    static let openingOuterStroke: CGFloat = 30
    static let openingMidStroke: CGFloat = 3
    static let openingInnerStroke: CGFloat = 12
    static let openingDash: CGFloat = 34
    static let openingDashGap: CGFloat = 11
    static let openingRingCenterX: CGFloat = 345
    static let openingRingCenterY: CGFloat = 829
    static let yearCopyTop: CGFloat = 128
    static let yearCopyGap: CGFloat = 10
    static let yearHeadline: CGFloat = 60
    static let yearHeadlineTracking: CGFloat = -1.2
    static let yearGridTop: CGFloat = 280
    static let yearSupportTop: CGFloat = 756
    static let yearSupportSize: CGFloat = 15
    static let playLabel: CGFloat = 12
    static let playIcon: CGFloat = 18
    static let chipTracking: CGFloat = 0.6
    static let chipRadius: CGFloat = 4
    static let chipInset: CGFloat = 6
    static let chipPadH: CGFloat = 6
    static let chipPadV: CGFloat = 3
    static let topMonthRing: CGFloat = 3
    static let ringWidth: CGFloat = 2
    static let blockGap: CGFloat = 12
    static let feedHeadline: CGFloat = 66
    static let feedHeadlineTracking: CGFloat = -1.5
    static let feedGridTop: CGFloat = 286
    static let feedStickerTop: CGFloat = 590
    static let feedStickerTrailing: CGFloat = 14
    static let feedSwatchTop: CGFloat = 650
    static let stickerTilt: Double = -4
    static let stickerRadius: CGFloat = 12
    static let stickerPadV: CGFloat = 9
    static let stickerPadH: CGFloat = 14
    static let stickerName: CGFloat = 26
    static let swatchGap: CGFloat = 6
    static let swatchHeight: CGFloat = 30
    static let swatchRadius: CGFloat = 6
    static let swatchShare: CGFloat = 18
    static let hexSize: CGFloat = 10
    static let shareSize: CGFloat = 15
    static let algorithmHeadline: CGFloat = 50
    static let algorithmHeadlineLine: CGFloat = 0.88
    static let algorithmHeadlineTracking: CGFloat = -1
    static let algorithmTopicsTop: CGFloat = 344
    static let algorithmMosaicTop: CGFloat = 636
    static let algorithmMosaicHeight: CGFloat = 116
    static let mosaicRadius: CGFloat = 3
    static let topicIndex: CGFloat = 13
    static let topicName: CGFloat = 36
    static let topicGap: CGFloat = 22
    static let topicRowGap: CGFloat = 10
    static let topicButtonInset: CGFloat = 28
    static let chipHeight: CGFloat = 36
    static let chipGap: CGFloat = 8
    static let chipTextPad: CGFloat = 14
    static let quietStroke: CGFloat = 0.7
    static let dashedStroke: CGFloat = 1.5
    static let undercutSize: CGFloat = 14
    static let mosaicIcon: CGFloat = 30
    static let mosaicHeart: CGFloat = 18
    static let hairline: CGFloat = 1
    static let hairlineOpacity: Double = 0.12
    static let stickerShadow: Double = 0.3
    static let reelsHeadline: CGFloat = 62
    static let reelsName: CGFloat = 19
    static let reelsBar: CGFloat = 18
    static let postHeadline: CGFloat = 48
    static let postLikes: CGFloat = 30
    static let chatHeadline: CGFloat = 56
    static let chatReplies: CGFloat = 76
    static let chatCaption: CGFloat = 17
    static let nightTime: CGFloat = 78
    static let averageLine: CGFloat = 22
    static let storyChipSize: CGFloat = 9
    static let clockHour: Double = 111
    static let clockMinute: Double = 252
    static let barTrack: Double = 0.14
}

enum PaletteInk {
    static let colors: [Color] = [
        WrappedColor.paletteMidnight,
        WrappedColor.paletteCamel,
        WrappedColor.paletteWine,
        WrappedColor.paletteCream,
        WrappedColor.paletteOlive
    ]
}

enum WrappedMark: Equatable {
    case gradient
    case ink
    case white
}

struct CardChrome {
    var foreground: Color
    var trackOpacity: Double
    var mark: WrappedMark
    var innerBorder: Color
    var outerFill: Color = WrappedColor.ink

    static func forCard(_ card: Int) -> CardChrome {
        switch card {
        case 1:
            return CardChrome(
                foreground: WrappedColor.ink,
                trackOpacity: 0.25,
                mark: .ink,
                innerBorder: WrappedColor.igPink
            )
        case 3:
            return CardChrome(
                foreground: WrappedColor.ink,
                trackOpacity: 0.2,
                mark: .gradient,
                innerBorder: WrappedColor.paper
            )
        case 4:
            return CardChrome(
                foreground: WrappedColor.igWhite,
                trackOpacity: 0.3,
                mark: .white,
                innerBorder: WrappedColor.igViolet
            )
        case 5, 8:
            return CardChrome(
                foreground: WrappedColor.ink,
                trackOpacity: 0.25,
                mark: .ink,
                innerBorder: WrappedColor.igOrange
            )
        case 6:
            return CardChrome(
                foreground: WrappedColor.ink,
                trackOpacity: 0.22,
                mark: .ink,
                innerBorder: WrappedColor.igYellow
            )
        case 7:
            return CardChrome(
                foreground: WrappedColor.ink,
                trackOpacity: 0.25,
                mark: .ink,
                innerBorder: WrappedColor.closeGreen
            )
        case 9:
            return CardChrome(
                foreground: WrappedColor.igWhite,
                trackOpacity: 0.3,
                mark: .ink,
                innerBorder: WrappedColor.nightNavy,
                outerFill: WrappedColor.igYellow
            )
        default:
            return CardChrome(
                foreground: WrappedColor.igWhite,
                trackOpacity: 0.3,
                mark: .gradient,
                innerBorder: WrappedColor.ink
            )
        }
    }
}

enum MonthTone {
    /// Placeholder gradients from the year-card HTML, January through November.
    static let pairs: [(UInt32, UInt32)] = [
        (0x5B7FA6, 0x243447), (0xD8C3A5, 0x8A6F52), (0xC0617A, 0x3B1F3F),
        (0x6B8A6A, 0x2C3B2B), (0xB4835A, 0x5A3A24), (0x8F7AB8, 0x352A4F),
        (0xE0A96D, 0x7A4A22), (0xD97A8C, 0x5C2A38), (0x7FA3A0, 0x2C4644),
        (0xC9B38A, 0x6B5A3A), (0x9A6B5B, 0x3D2620)
    ]

    static func gradient(_ index: Int) -> LinearGradient {
        let pair = pairs[min(max(index, 0), pairs.count - 1)]
        return LinearGradient(
            colors: [Color(hex: pair.0), Color(hex: pair.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

enum FeedMosaic {
    static let fills: [(UInt32, UInt32)] = [
        (0x2B3A5E, 0x141C30), (0xD2B08C, 0x9C7A58), (0x2B3A5E, 0x141C30),
        (0x9E4545, 0x5E2424), (0xEFE7DA, 0xCFC3AF), (0xD2B08C, 0x9C7A58),
        (0x5E7D59, 0x33472F), (0x2B3A5E, 0x141C30), (0x9E4545, 0x5E2424)
    ]

    static func gradient(_ index: Int) -> LinearGradient {
        let pair = fills[index]
        return LinearGradient(
            colors: [Color(hex: pair.0), Color(hex: pair.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}
