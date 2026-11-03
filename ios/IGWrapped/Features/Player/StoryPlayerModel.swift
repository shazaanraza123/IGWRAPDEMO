import Foundation

/// Actions the prototype has not built. Pitch mode and the demo toast both read this list.
enum Feature: Equatable, CaseIterable {
    case share
    case hub
    case create
    case activity
    case storyReply
    case privacy
    case creator
    case remix
    case together
    case quiz
    case pastYears

    static func isBuilt(_ feature: Feature) -> Bool {
        switch feature {
        case .share, .hub:
            true
        case .create, .activity, .storyReply, .privacy, .creator, .remix, .together, .quiz, .pastYears:
            false
        }
    }

    static let unavailable = "Not part of this demo"

    /// Nil when the action is built, and nil in pitch mode so the control stays quiet.
    static func toast(for feature: Feature, pitch: Bool = Pitch.active) -> String? {
        guard !isBuilt(feature) else { return nil }
        return pitch ? nil : unavailable
    }
}

enum Pitch {
    static var active: Bool {
        ProcessInfo.processInfo.arguments.contains("--pitch")
    }
}

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

    static func save(_ progress: PlayerProgress, defaults: UserDefaults = .standard, pitch: Bool = Pitch.active) {
        guard !pitch else { return }
        guard let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: key)
    }

    static func load(defaults: UserDefaults = .standard, pitch: Bool = Pitch.active) -> PlayerProgress? {
        guard !pitch else { return nil }
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PlayerProgress.self, from: data)
    }
}

struct StoryPlayerModel {
    static let cardCount = 13
    static let backZone: CGFloat = 1.0 / 3.0

    static let toastLifetime: TimeInterval = 2

    var card = 1
    var elapsed: TimeInterval = 0
    var toast: String?
    private var toastGeneration = 0
    var isHolding = false
    var infoOpen = false
    var shareOpen = false
    var autoplay = true
    var coverOpen = false
    /// Cards a teen run does not include. Empty for the full deck.
    var omitted: Set<Int> = []
    /// Catalog numbers this deck plays, in order. Defaults to 1...13.
    var included: [Int] = Array(1 ... cardCount)

    var sequence: [Int] {
        included.filter { !omitted.contains($0) }
    }

    var sequenceIndex: Int {
        sequence.firstIndex(of: card) ?? 0
    }

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

    mutating func showToast(_ message: String) -> Int {
        toastGeneration += 1
        toast = message
        return toastGeneration
    }

    mutating func clearToast() {
        toast = nil
    }

    /// Drops the toast only if this is still the one `showToast` returned.
    mutating func expireToast(generation: Int) {
        guard toastGeneration == generation else { return }
        toast = nil
    }

    mutating func tap(xFraction: CGFloat) -> PlayerAdvance {
        if xFraction < Self.backZone {
            return goBack()
        }
        return goForward()
    }

    mutating func goBack() -> PlayerAdvance {
        clearToast()
        guard let index = sequence.firstIndex(of: card), index > 0 else {
            elapsed = 0
            return .same
        }
        card = sequence[index - 1]
        elapsed = 0
        return .moved
    }

    mutating func goForward() -> PlayerAdvance {
        clearToast()
        guard let index = sequence.firstIndex(of: card) else { return .finished }
        if index + 1 >= sequence.count {
            return .finished
        }
        card = sequence[index + 1]
        elapsed = 0
        return .moved
    }

    /// Lands on the first included card of the neighboring chapter, skipping an empty one.
    mutating func jumpChapter(forward: Bool) -> PlayerAdvance {
        clearToast()
        var cursor = chapter
        while true {
            guard let target = forward ? cursor.next : cursor.previous else { return .same }
            if let next = sequence.first(where: { target.cards.contains($0) }) {
                card = next
                elapsed = 0
                return .moved
            }
            cursor = target
        }
    }

    /// The teaser waits for Reveal. Reveal itself turns autoplay off.
    mutating func reveal() -> PlayerAdvance {
        autoplay = false
        return goForward()
    }

    mutating func tick(delta: TimeInterval) -> PlayerAdvance {
        guard autoplay, !isHolding, !infoOpen, !shareOpen, !coverOpen, delta > 0 else { return .same }
        guard card != 11 else { return .same }
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
