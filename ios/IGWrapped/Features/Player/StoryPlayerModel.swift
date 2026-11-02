import Foundation

enum PlayerAdvance: Equatable {
    case same
    case moved
    case finished
}

enum PlayerDragEnd: Equatable {
    case tap
    case dismiss
    case info
    case nextChapter
    case previousChapter
    case cancel
}

enum ChapterTransition: Equatable {
    case cube
    case crossfade
}

struct PlayerProgress: Equatable, Codable {
    var card: Int
    var elapsed: TimeInterval
}

enum PlayerProgressStore {
    private static let key = "igwrapped.player-progress"

    static func save(_ progress: PlayerProgress, defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: key)
    }

    static func load(defaults: UserDefaults = .standard) -> PlayerProgress? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PlayerProgress.self, from: data)
    }
}

struct StoryPlayerModel {
    static let cardCount = 13
    static let backZone: CGFloat = 1.0 / 3.0

    var card = 1
    var elapsed: TimeInterval = 0
    var isHolding = false
    var infoOpen = false
    var autoplay = true

    var chapter: Chapter { Chapter.containing(card) }

    var duration: TimeInterval {
        WrappedMotion.longCardNumbers.contains(card)
            ? WrappedMotion.longCardDuration
            : WrappedMotion.defaultCardDuration
    }

    var fraction: CGFloat {
        guard duration > 0 else { return 0 }
        return CGFloat(min(max(elapsed / duration, 0), 1))
    }

    var showsInfoButton: Bool {
        card != 1 && card != 11
    }

    static func transition(reduceMotion: Bool) -> ChapterTransition {
        reduceMotion ? .crossfade : .cube
    }

    mutating func tap(xFraction: CGFloat) -> PlayerAdvance {
        if xFraction < Self.backZone {
            return goBack()
        }
        return goForward()
    }

    mutating func goBack() -> PlayerAdvance {
        if card == 1 {
            elapsed = 0
            return .same
        }
        card -= 1
        elapsed = 0
        return .moved
    }

    mutating func goForward() -> PlayerAdvance {
        if card == Self.cardCount {
            return .finished
        }
        card += 1
        elapsed = 0
        return .moved
    }

    /// Lands on the first card of the neighboring chapter.
    mutating func jumpChapter(forward: Bool) -> PlayerAdvance {
        let target = forward ? chapter.next : chapter.previous
        guard let target else { return .same }
        card = target.firstCard
        elapsed = 0
        return .moved
    }

    mutating func tick(delta: TimeInterval) -> PlayerAdvance {
        guard autoplay, !isHolding, !infoOpen, delta > 0 else { return .same }
        elapsed += delta
        guard elapsed >= duration else { return .same }
        return goForward()
    }

    func dragEnded(dx: CGFloat, dy: CGFloat, velocityX: CGFloat, velocityY: CGFloat) -> PlayerDragEnd {
        let travel = max(abs(dx), abs(dy))
        guard travel > IGSpace.viewerDragMinimum else { return .tap }
        if abs(dx) > abs(dy) {
            let flung = abs(velocityX) > IGSpace.viewerDismissVelocity
            guard abs(dx) > IGSpace.viewerDismissTravel || flung else { return .cancel }
            return dx < 0 ? .nextChapter : .previousChapter
        }
        if dy > 0 {
            let flung = velocityY > IGSpace.viewerDismissVelocity
            guard dy > IGSpace.viewerDismissTravel || flung else { return .cancel }
            return .dismiss
        }
        let flung = velocityY < -IGSpace.viewerDismissVelocity
        guard -dy > IGSpace.viewerDismissTravel || flung else { return .cancel }
        return .info
    }
}
