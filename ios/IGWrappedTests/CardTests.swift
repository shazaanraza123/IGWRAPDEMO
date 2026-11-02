import Foundation
import Testing
@testable import IGWrapped

private final class RunBundleProbe: NSObject {}

@Test func mayaCardCopyMatchesTheSchema() throws {
    let url = try #require(Bundle(for: RunBundleProbe.self).url(forResource: "maya", withExtension: "json"))
    let bundle = try JSONDecoder().decode(RunBundle.self, from: Data(contentsOf: url))
    #expect(bundle.metric("posts") == 38)
    #expect(bundle.metric("stories") == 412)
    #expect(bundle.metric("reels_sent") == 1_206)
    #expect(bundle.metric("saves") == 1_214)
    #expect(bundle.metric("days_active") == 301)
    #expect(bundle.metric("liked_posts") == 1_840)
    #expect(bundle.metric("friends_stories_watched_pct") == 96)
    #expect(bundle.card(number: 1)?.headline == "2026 LOOKED\nGOOD ON\nYOU.")
    #expect(bundle.card(number: 2)?.headline == "YOU HAD QUITE\nA YEAR.")
    #expect(bundle.card(number: 3)?.headline == "YOUR FEED\nHAD A COLOR.")
    #expect(bundle.card(number: 1)?.support == "Built from your own posts and Stories, Jan 1 to Nov 15.")
    #expect(bundle.card(number: 2)?.support == "August was your busiest month: 9 posts, 61 Stories.")
    #expect(bundle.card(number: 2)?.payload.copy?.playLabel == "PLAY YOUR\nYEAR · 0:15")
    #expect(bundle.card(number: 3)?.payload.copy?.footnote == "% = main color in each of 1,840 liked posts")
    let months = bundle.card(number: 2)?.payload.months ?? []
    #expect(months.map(\.photo) == (1...11).map { String(format: "m-%02d", $0) })
    #expect(MontageGate.ready(months) == false)
    #expect(bundle.card(number: 2)?.payload.topMonth == 8)
    #expect(bundle.card(number: 2)?.payload.montageSeconds == 15)
    #expect(months.count == 11)
}

@Test func infoSheetUsesEachCardsMetrics() throws {
    let url = try #require(Bundle(for: RunBundleProbe.self).url(forResource: "maya", withExtension: "json"))
    let bundle = try JSONDecoder().decode(RunBundle.self, from: Data(contentsOf: url))
    #expect(bundle.card(number: 1)?.metricKeys.isEmpty == true)
    let reels = "Top 5 categories by share of your Reels watch time. Other categories: 8%."
    let methods = bundle.metrics(for: bundle.card(number: 5) ?? .placeholder(type: "reelsRabbitHole", number: 5)).map(\.method)
    #expect(methods.contains(reels))
    #expect(bundle.metrics(for: bundle.card(number: 2)!).contains { $0.windowLabel == "Jan 1 to Nov 15, 2026" })
    #expect(bundle.metrics(for: bundle.card(number: 4)!).allSatisfy { $0.provenance == "inferred" })
    for number in 2 ... 13 {
        let card = try #require(bundle.card(number: number))
        #expect(!bundle.metrics(for: card).isEmpty)
    }
}

@Test func hidingACardLeavesTheSequenceAndSurvives() {
    let name = "hidden-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    defaults.set("maya", forKey: LocalPersona.storageKey)
    HiddenCards.hide(9, defaults: defaults)
    var model = StoryPlayerModel()
    model.omitted = HiddenCards.load(defaults: defaults)
    #expect(model.sequence == [1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13])
    #expect(model.sequence.count == 12)
    HiddenCards.clear(defaults: defaults)
    model.omitted = HiddenCards.load(defaults: defaults)
    #expect(model.sequence.count == 13)
}

@Test @MainActor func looksWrongWritesALocalRow() async {
    let file = FileManager.default.temporaryDirectory.appendingPathComponent("feedback-\(UUID().uuidString).json")
    let wrote = await FeedbackStore().reportLooksWrong(card: "P09", reason: LooksWrongReason.numberOff.rawValue, file: file)
    #expect(wrote)
    let rows = FeedbackStore.localRows(file: file)
    #expect(rows.contains { $0.kind == FeedbackKind.looksWrong && $0.reason == "number_off" && $0.target == "P09" })
}

@Test func cardChromeFollowsTheHtml() {
    #expect(CardChrome.forCard(1).mark == .ink)
    #expect(CardChrome.forCard(2).mark == .gradient)
    #expect(CardChrome.forCard(3).mark == .gradient)
    #expect(CardChrome.forCard(4).mark == .white)
}

@Test func teenRunSkipsTheCircleAndTheNightCard() {
    var model = StoryPlayerModel()
    model.omitted = [8, 9]
    #expect(model.sequence == [1, 2, 3, 4, 5, 6, 7, 10, 11, 12, 13])
    model.card = 7
    #expect(model.goForward() == .moved)
    #expect(model.card == 10)
    model.card = 7
    #expect(model.jumpChapter(forward: true) == .moved)
    #expect(model.card == 10)
}

@Test @MainActor func offlineSessionDoesNotOpenAClient() {
    #expect(Backend.active == false)
    #expect(SessionStore.shared.client == nil)
}

@Test @MainActor func feedbackSelectionPersistsLocally() {
    let name = "feedback-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    let store = FeedbackStore(defaults: defaults)
    store.remember(target: "Streetwear drops", kind: FeedbackKind.moreOfThis)
    let restored = FeedbackStore(defaults: defaults)
    #expect(restored.selection(for: "Streetwear drops") == FeedbackKind.moreOfThis)
    #expect(restored.selection(for: "Film cameras") == nil)
}

@Test func personAvatarUsesTheHandleUntilAHeadshotExists() {
    #expect(PersonAvatar.initial("dee.films") == "D")
    #expect(PersonAvatar.initial("@maya.lens") == "M")
    #expect(PersonAvatar.photoName(for: "jules.mp") == "friend-jules")
    #expect(PersonAvatar.photoName(for: "maya.lens") == "maya-profile")
    for handle in ["dee.films", "jules.mp", "nico_k", "sam.wav", "tori.eats", "maya.lens"] {
        #expect(!PersonAvatar.photoName(for: handle).hasPrefix("tile"))
        let swatch = PersonSwatch.forHandle(handle)
        #expect(swatch == PersonSwatch.forHandle(handle))
        #expect(swatch.usesInk == (swatch == .green || swatch == .yellow))
    }
    #expect(PersonSwatch.forHandle("dee.films") != PersonSwatch.forHandle("jules.mp"))
}
