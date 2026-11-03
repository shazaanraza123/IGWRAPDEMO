import Foundation

struct RunBundle: Codable, Equatable {
    var run: RunRecord
    var metrics: [RunMetric]
    var archetypes: [ArchetypeScore]
    var cards: [RunCard]

    func card(_ type: String) -> RunCard? {
        cards.first { $0.type == type }
    }

    func metric(_ key: String) -> Int? {
        guard let value = metrics.first(where: { $0.key == key })?.valueNum else { return nil }
        return Int(value)
    }

    static var empty: RunBundle {
        RunBundle(
            run: RunRecord(
                year: 2026,
                edition: "personal",
                periodStart: "",
                periodEnd: "",
                tier: "full",
                status: "ready",
                engineVersion: "1",
                copy: RunCopy(window: "", summary: "")
            ),
            metrics: [],
            archetypes: [],
            cards: []
        )
    }

    /// The demo deck for this launch. Teen uses the teen bundle.
    static func launched() -> RunBundle {
        let name = ProcessInfo.processInfo.arguments.contains("--teen") ? "maya-teen" : "maya"
        return (try? load(named: name)) ?? .empty
    }

    static func load(named name: String) throws -> RunBundle {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw RunLoadError.missing(name)
        }
        return try JSONDecoder().decode(RunBundle.self, from: Data(contentsOf: url))
    }
}

enum RunLoadError: Error {
    case missing(String)
}

struct RunRecord: Codable, Equatable {
    var year: Int
    var edition: String
    var periodStart: String
    var periodEnd: String
    var tier: String
    var status: String
    var engineVersion: String
    var copy: RunCopy

    enum CodingKeys: String, CodingKey {
        case year, edition, tier, status, copy
        case periodStart = "period_start"
        case periodEnd = "period_end"
        case engineVersion = "engine_version"
    }
}

struct RunCopy: Codable, Equatable {
    var window: String
    var summary: String
}

struct RunMetric: Codable, Equatable, Identifiable {
    var key: String
    var valueNum: Double?
    var valueText: String?
    var provenance: String
    var method: String
    var windowLabel: String

    var id: String { "\(key)|\(valueText ?? "")|\(valueNum.map { String($0) } ?? "")" }

    enum CodingKeys: String, CodingKey {
        case key, provenance, method
        case valueNum = "value_num"
        case valueText = "value_text"
        case windowLabel = "window_label"
    }
}

struct ArchetypeScore: Codable, Equatable {
    var archetype: String
    var score: Int
    var rank: Int
}

struct RunCard: Codable, Equatable, Identifiable {
    var code: String
    var type: String
    var chapter: String
    var sortOrder: Int
    var payload: CardPayload
    var metricKeys: [String]
    var shareable: Bool
    var teenSafe: Bool
    var hidden: Bool

    var id: String { code }

    enum CodingKeys: String, CodingKey {
        case code, type, chapter, payload, shareable, hidden
        case sortOrder = "sort_order"
        case metricKeys = "metric_keys"
        case teenSafe = "teen_safe"
    }
}

struct CardCopy: Codable, Equatable {
    var headline: String?
    var support: String?
    var playLabel: String?
    var hubHighlight: String?
    var hubDetail: String?
    var footnote: String?
    var undercut: String?
    var fastestRising: String?
    var sent: String?
    var comments: String?
    var average: String?
    var posted: String?
    var dateChip: String?
    var storyChip: String?
    var time: String?
    var note: String?
    var privacy: String?
    var clues: [String]?
    var name: String?
    var side: String?
    var primaryMatch: String?
    var secondaryMatch: String?
    var identityYear: String?
    var numbersTitle: String?
}

struct ShareIdentity: Codable, Equatable {
    var archetype: String
    var stat: TextPair
}

struct ShareNumbers: Codable, Equatable {
    var photo: String?
    var stats: [TextPair]
    var topInterest: String
}

struct CardPayload: Codable, Equatable {
    var photos: [String]? = nil
    var handle: String? = nil
    var windowLabel: String? = nil
    var months: [MonthSlot]? = nil
    var topMonth: Int? = nil
    var montageSeconds: Int? = nil
    var topMonthPosts: Int? = nil
    var topMonthStories: Int? = nil
    var paletteName: String? = nil
    var swatches: [ColorSwatch]? = nil
    var likedPosts: Int? = nil
    var topics: [TopicSlot]? = nil
    var categories: [NamedPercent]? = nil
    var fastestRising: RisingTopic? = nil
    var reelsSent: Int? = nil
    var postId: String? = nil
    var photo: String? = nil
    var likes: Int? = nil
    var comments: Int? = nil
    var vsAverage: Int? = nil
    var postedAt: String? = nil
    var storyId: String? = nil
    var replies: Int? = nil
    var windowHours: Int? = nil
    var handles: [String]? = nil
    var latestLocalTime: String? = nil
    var weekday: String? = nil
    var month: String? = nil
    var sentence: String? = nil
    var category: String? = nil
    var monthly: [Int]? = nil
    var turnMonth: Int? = nil
    var primary: String? = nil
    var secondary: String? = nil
    var primaryScore: Int? = nil
    var secondaryScore: Int? = nil
    var reasons: [TextPair]? = nil
    var identity: ShareIdentity? = nil
    var numbers: ShareNumbers? = nil
    var copy: CardCopy? = nil
}

enum CardCatalog {
    static let number: [String: Int] = [
        "opening": 1,
        "yearInMemories": 2,
        "feedColor": 3,
        "yourAlgorithm": 4,
        "reelsRabbitHole": 5,
        "mainCharacterPost": 6,
        "brokeTheGroupChat": 7,
        "yourCircle": 8,
        "threeAmClub": 9,
        "plotTwist": 10,
        "personalityTeaser": 11,
        "personalityReveal": 12,
        "shareCards": 13,
    ]
}

extension RunBundle {
    var deckNumbers: [Int] {
        cards.sorted { $0.sortOrder < $1.sortOrder }.compactMap { CardCatalog.number[$0.type] }
    }

    func card(number: Int) -> RunCard? {
        cards.first { CardCatalog.number[$0.type] == number }
    }

    func metrics(for card: RunCard) -> [RunMetric] {
        card.metricKeys.flatMap { key in metrics.filter { $0.key == key } }
    }
}

extension RunCard {
    static func placeholder(type: String, number: Int) -> RunCard {
        RunCard(
            code: type,
            type: type,
            chapter: "",
            sortOrder: number,
            payload: CardPayload(),
            metricKeys: [],
            shareable: false,
            teenSafe: true,
            hidden: false
        )
    }

    var headline: String { payload.copy?.headline ?? "" }
    var support: String { payload.copy?.support ?? "" }
}

enum MonthLabel {
    static let shorts = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV"]
    static let letters = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N"]

    static func chip(month: Int, top: Int?) -> String {
        guard month >= 1, month <= shorts.count else { return "" }
        let name = shorts[month - 1]
        return month == top ? "\(name) · TOP MONTH" : name
    }
}

enum MontageGate {
    static let unavailable = "Add month photos to play"

    static func ready(_ months: [MonthSlot]) -> Bool {
        !months.isEmpty && months.allSatisfy { BundlePhoto.image(named: $0.photo) != nil }
    }
}

enum CountText {
    static func string(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

struct MonthSlot: Codable, Equatable, Identifiable {
    var month: Int
    var photo: String
    var id: Int { month }
}

struct ColorSwatch: Codable, Equatable, Identifiable {
    var hex: String
    var pct: Int
    var id: String { hex }
}

struct TopicSlot: Codable, Equatable, Identifiable {
    var name: String
    var isUndercut: Bool?
    var watched: Int?
    var id: String { name }
}

struct RisingTopic: Codable, Equatable {
    var name: String
    var multiple: Int
    var since: String
}

struct NamedPercent: Codable, Equatable, Identifiable {
    var name: String
    var percent: Int
    var id: String { name }

    init(name: String, percent: Int) {
        self.name = name
        self.percent = percent
    }

    init(from decoder: Decoder) throws {
        var box = try decoder.unkeyedContainer()
        name = try box.decode(String.self)
        percent = try box.decode(Int.self)
    }

    func encode(to encoder: Encoder) throws {
        var box = encoder.unkeyedContainer()
        try box.encode(name)
        try box.encode(percent)
    }
}

struct TextPair: Codable, Equatable, Identifiable {
    var value: String
    var label: String
    var id: String { label }

    init(value: String, label: String) {
        self.value = value
        self.label = label
    }

    init(from decoder: Decoder) throws {
        var box = try decoder.unkeyedContainer()
        value = try box.decode(String.self)
        label = try box.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var box = encoder.unkeyedContainer()
        try box.encode(value)
        try box.encode(label)
    }
}

enum LocalPersona {
    static let storageKey = "igwrapped.persona"

    static var current: String? {
        UserDefaults.standard.string(forKey: storageKey)
    }

    static func save(_ persona: String) {
        UserDefaults.standard.set(persona, forKey: storageKey)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    static func bundleName(for persona: String) -> String {
        persona == "teen" ? "maya-teen" : persona
    }
}

enum Backend {
    static var active: Bool {
        ProcessInfo.processInfo.arguments.contains("--backend")
    }
}

enum HiddenCards {
    private static let prefix = "igwrapped.hidden-cards"

    static func load(defaults: UserDefaults = .standard) -> Set<Int> {
        if ProcessInfo.processInfo.arguments.contains("--reset-session") {
            clear(defaults: defaults)
            return []
        }
        return stored(defaults: defaults)
    }

    static func hide(_ card: Int, defaults: UserDefaults = .standard) {
        var cards = stored(defaults: defaults)
        cards.insert(card)
        defaults.set(Array(cards).sorted(), forKey: storageKey(defaults: defaults))
    }

    static func clear(defaults: UserDefaults = .standard) {
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            defaults.removeObject(forKey: key)
        }
    }

    private static func stored(defaults: UserDefaults) -> Set<Int> {
        let values = defaults.array(forKey: storageKey(defaults: defaults)) as? [Int] ?? []
        return Set(values)
    }

    private static func storageKey(defaults: UserDefaults) -> String {
        let persona = defaults.string(forKey: LocalPersona.storageKey) ?? "maya"
        return "\(prefix).\(persona)"
    }
}

enum RunRepositoryError: Error {
    case missingBundle(String)
}

protocol RunRepository {
    func load(persona: String) async throws -> RunBundle
}

struct BundledRunRepository: RunRepository {
    func load(persona: String) async throws -> RunBundle {
        let name = LocalPersona.bundleName(for: persona)
        do {
            return try RunBundle.load(named: name)
        } catch {
            throw RunRepositoryError.missingBundle(name)
        }
    }
}

struct SupabaseRunRepository: RunRepository {
    func load(persona: String) async throws -> RunBundle {
        let client = await SessionStore.shared.client
        guard Backend.active, AppConfig.supabaseURL != nil, client != nil else {
            throw RunRepositoryError.missingBundle(persona)
        }
        return try await BundledRunRepository().load(persona: persona)
    }
}
