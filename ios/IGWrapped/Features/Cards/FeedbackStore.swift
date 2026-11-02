import Foundation
import Supabase

/// Local selection plus an owner row in `card_feedback` when a session exists.
@MainActor
@Observable
final class FeedbackStore {
    static let shared = FeedbackStore()

    private let defaults: UserDefaults
    private let storageKey = "igwrapped.card-feedback"
    private(set) var selections: [String: String] = [:]
    private(set) var didWrite = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([String: String].self, from: data) {
            selections = saved
        }
    }

    func selection(for target: String) -> String? {
        selections[target]
    }

    func remember(target: String, kind: String) {
        selections[target] = kind
        guard let data = try? JSONEncoder().encode(selections) else { return }
        defaults.set(data, forKey: storageKey)
    }

    func choose(target: String, kind: String) async -> Bool {
        remember(target: target, kind: kind)
        let wrote = await write(target: target, kind: kind, reason: nil)
        if wrote {
            didWrite = true
        }
        return wrote
    }

    func reportLooksWrong(card: String, reason: String, file: URL? = nil) async -> Bool {
        await write(target: card, kind: FeedbackKind.looksWrong, reason: reason, file: file)
    }

    func loadRemote() async {
        guard Backend.active, let client = SessionStore.shared.client else { return }
        do {
            let rows: [FeedbackRead] = try await client
                .from("card_feedback")
                .select("kind,target,created_at")
                .execute()
                .value
            let ordered = rows.sorted { $0.createdAt < $1.createdAt }
            for row in ordered {
                guard let target = row.target else { continue }
                selections[target] = row.kind
            }
            if let data = try? JSONEncoder().encode(selections) {
                defaults.set(data, forKey: storageKey)
            }
        } catch {
            return
        }
    }

    private func write(target: String, kind: String, reason: String?, file: URL? = nil) async -> Bool {
        guard Backend.active, let client = SessionStore.shared.client else {
            return appendLocal(target: target, kind: kind, reason: reason, file: file)
        }
        do {
            let session = try await client.auth.session
            let cards: [CardRef] = try await client
                .from("cards")
                .select("id")
                .eq("type", value: "yourAlgorithm")
                .limit(1)
                .execute()
                .value
            guard let card = cards.first else { return false }
            let row = FeedbackInsert(cardId: card.id, userId: session.user.id, kind: kind, target: target, reason: reason)
            try await client.from("card_feedback").insert(row).execute()
            return true
        } catch {
            return false
        }
    }
}

enum FeedbackKind {
    static let moreOfThis = "more_of_this"
    static let notMe = "not_me"
    static let guilty = "guilty"
    static let looksWrong = "looks_wrong"
}

struct LocalFeedback: Codable, Equatable {
    var target: String
    var kind: String
    var reason: String?
    var createdAt: String
}

enum LooksWrongReason: String, CaseIterable, Identifiable {
    case numberOff = "number_off"
    case notMe = "not_me"
    case dontRemember = "dont_remember"
    case other = "other"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .numberOff: "The number seems off"
        case .notMe: "That's not me"
        case .dontRemember: "I don't remember this"
        case .other: "Something else"
        }
    }
}

extension FeedbackStore {
    static var localFile: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("IGWrapped", isDirectory: true)
            .appendingPathComponent("card-feedback.json")
    }

    static func localRows(file: URL) -> [LocalFeedback] {
        guard let data = try? Data(contentsOf: file) else { return [] }
        return (try? JSONDecoder().decode([LocalFeedback].self, from: data)) ?? []
    }

    fileprivate func appendLocal(target: String, kind: String, reason: String?, file: URL?) -> Bool {
        guard let file = file ?? Self.localFile else { return false }
        do {
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            var rows = Self.localRows(file: file)
            let stamp = ISO8601DateFormatter().string(from: Date())
            rows.append(LocalFeedback(target: target, kind: kind, reason: reason, createdAt: stamp))
            try JSONEncoder().encode(rows).write(to: file, options: .atomic)
            return true
        } catch {
            return false
        }
    }
}

private struct CardRef: Decodable {
    let id: UUID
}

private struct FeedbackRead: Decodable {
    let kind: String
    let target: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case kind
        case target
        case createdAt = "created_at"
    }
}

private struct FeedbackInsert: Encodable {
    let cardId: UUID
    let userId: UUID
    let kind: String
    let target: String
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case cardId = "card_id"
        case userId = "user_id"
        case kind
        case target
        case reason
    }
}
