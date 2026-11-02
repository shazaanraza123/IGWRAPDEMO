import SwiftUI

/// Music and cube groups. Eyebrow copy is not a chapter id.
enum Chapter: String, CaseIterable, Identifiable, Hashable {
    case memories
    case interests
    case moments
    case people
    case identity

    var id: String { rawValue }

    /// First and last card numbers, 1-based, from DECISIONS.
    var cards: ClosedRange<Int> {
        switch self {
        case .memories: 1 ... 2
        case .interests: 3 ... 5
        case .moments: 6 ... 7
        case .people: 8 ... 9
        case .identity: 10 ... 13
        }
    }

    var firstCard: Int { cards.lowerBound }

    var next: Chapter? {
        let chapters = Self.allCases
        guard let index = chapters.firstIndex(of: self), index + 1 < chapters.count else { return nil }
        return chapters[index + 1]
    }

    var previous: Chapter? {
        let chapters = Self.allCases
        guard let index = chapters.firstIndex(of: self), index > 0 else { return nil }
        return chapters[index - 1]
    }

    static func containing(_ card: Int) -> Chapter {
        allCases.first { $0.cards.contains(card) } ?? .memories
    }

    var field: Color {
        switch self {
        case .memories: WrappedColor.igPink
        case .interests: WrappedColor.igOrange
        case .moments: WrappedColor.igMagenta
        case .people: WrappedColor.nightNavy
        case .identity: WrappedColor.igViolet
        }
    }
}
