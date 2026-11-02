import CoreText
import SwiftUI
import UIKit

/// Archivo variable font. `wdth` 62 is the condensed display width. Shell type stays SF Pro.
enum ArchivoFont {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var baseDescriptor: UIFontDescriptor?
    nonisolated(unsafe) private static var didRegister = false

    static func registerIfNeeded() {
        lock.lock()
        defer { lock.unlock() }
        guard !didRegister else { return }
        didRegister = true
        guard let url = fontURL() else { return }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor]
        baseDescriptor = descriptors?.first.map { $0 as UIFontDescriptor }
    }

    static func uiFont(size: CGFloat, weight: CGFloat, width: CGFloat) -> UIFont {
        registerIfNeeded()
        guard let baseDescriptor else {
            return .systemFont(ofSize: size, weight: .bold)
        }
        let variations: [NSNumber: NSNumber] = [
            NSNumber(value: 0x7767_6874): NSNumber(value: Double(weight)),
            NSNumber(value: 0x7764_7468): NSNumber(value: Double(width))
        ]
        let attributes: [UIFontDescriptor.AttributeName: Any] = [
            UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): variations,
            .size: size
        ]
        let descriptor = baseDescriptor.addingAttributes(attributes)
        return UIFont(descriptor: descriptor, size: size)
    }

    static func font(size: CGFloat, weight: CGFloat, width: CGFloat) -> Font {
        Font(uiFont(size: size, weight: weight, width: width))
    }

    private static func fontURL() -> URL? {
        let bundle = Bundle.main
        let candidates = [
            bundle.url(forResource: "Archivo", withExtension: "ttf"),
            bundle.url(forResource: "Archivo", withExtension: "ttf", subdirectory: "Fonts"),
            bundle.url(forResource: "Archivo", withExtension: "ttf", subdirectory: "Resources/Fonts")
        ]
        return candidates.compactMap { $0 }.first
    }
}

enum WrappedTextStyle: String, CaseIterable, Identifiable {
    case hero
    case display
    case bigNumber
    case title
    case body
    case eyebrow
    case caption
    case igChrome
    case igStoryName
    case igUsername
    case igMeta
    case bannerTitle

    var id: String { rawValue }

    var spec: String {
        switch self {
        case .hero: "Archivo 96–116 / 0.82 · 900 · wdth 62"
        case .display: "Archivo 46–72 / 0.86 · 900 · wdth 62 · uppercase · tracking -1"
        case .bigNumber: "Archivo 54–88 / 0.85 · 900 · wdth 62"
        case .title: "Archivo 20–36 / 1.0 · 900 · wdth 71"
        case .body: "Archivo 15–17 / 1.3 · 600"
        case .eyebrow: "Archivo 12 / 1.0 · 800 · tracking 1.4 · uppercase"
        case .caption: "Archivo 13 / 1.2 · 600"
        case .igChrome: "SF Pro · shell"
        case .igStoryName: "SF Pro 11 semibold"
        case .igUsername: "SF Pro 14 semibold"
        case .igMeta: "SF Pro 12 regular"
        case .bannerTitle: "Archivo 44 / 0.88 · 900 · wdth 64 · uppercase · tracking -0.8"
        }
    }

    /// Canonical size inside the brief's range. Cards pick within the range later.
    var size: CGFloat {
        switch self {
        case .hero: 96
        case .display: 46
        case .bigNumber: 54
        case .title: 20
        case .body: 16
        case .eyebrow: 12
        case .caption: 13
        case .igChrome: 12
        case .igStoryName: 11
        case .igUsername: 14
        case .igMeta: 12
        case .bannerTitle: 44
        }
    }

    var lineHeight: CGFloat {
        switch self {
        case .hero: 0.82
        case .display: 0.86
        case .bigNumber: 0.85
        case .title: 1
        case .body: 1.3
        case .eyebrow: 1
        case .caption: 1.2
        case .igChrome, .igStoryName, .igUsername, .igMeta: 1.2
        case .bannerTitle: 0.88
        }
    }

    var weight: CGFloat {
        switch self {
        case .hero, .display, .bigNumber, .title: 900
        case .eyebrow: 800
        case .body, .caption: 600
        case .igChrome, .igStoryName, .igUsername: 600
        case .igMeta: 400
        case .bannerTitle: 900
        }
    }

    var width: CGFloat {
        switch self {
        case .hero, .display, .bigNumber: 62
        case .title: 71
        case .body, .eyebrow, .caption, .igChrome, .igStoryName, .igUsername, .igMeta: 100
        case .bannerTitle: 64
        }
    }

    var tracking: CGFloat {
        switch self {
        case .display: -1
        case .eyebrow: 1.4
        case .bannerTitle: -0.8
        default: 0
        }
    }

    var isUppercase: Bool {
        self == .display || self == .eyebrow || self == .bannerTitle
    }

    var uiFont: UIFont {
        switch self {
        case .igChrome, .igStoryName, .igUsername:
            return .systemFont(ofSize: size, weight: .semibold)
        case .igMeta:
            return .systemFont(ofSize: size, weight: .regular)
        default:
            break
        }
        return ArchivoFont.uiFont(size: size, weight: weight, width: width)
    }

    var font: Font { Font(uiFont) }

    func extraLineSpacing(for font: UIFont) -> CGFloat {
        (font.pointSize * lineHeight) - font.lineHeight
    }
}

struct WrappedTypeModifier: ViewModifier {
    var style: WrappedTextStyle

    func body(content: Content) -> some View {
        let font = style.uiFont
        content
            .font(style.font)
            .tracking(style.tracking)
            .lineSpacing(style.extraLineSpacing(for: font))
            .textCase(style.isUppercase ? .uppercase : nil)
    }
}

extension View {
    func wrappedType(_ style: WrappedTextStyle) -> some View {
        modifier(WrappedTypeModifier(style: style))
    }
}

enum IGFont {
    static var icon: Font { .system(size: IGSpace.chromeIcon, weight: .regular) }
    static var iconSelected: Font { .system(size: IGSpace.chromeIcon, weight: .semibold) }
    static var badge: Font { .system(size: IGSpace.storyBadge / 2, weight: .bold) }
}
