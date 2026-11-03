import Foundation
import Testing
import UIKit
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

@Test func storyExportKeepsTheSafeZone() {
    let story = ShareMeasure(format: .story)
    #expect(story.canvas == CGSize(width: 1080, height: 1920))
    #expect(story.safeTop == 250)
    #expect(story.safeBottom == 340)
    #expect(story.content.height == 1330)
    let post = ShareMeasure(format: .post)
    #expect(post.canvas == CGSize(width: 1080, height: 1350))
    #expect(ShareMeasure(format: .square).canvas == CGSize(width: 1080, height: 1080))
}

@Test func shareCopyMatchesTheCard() throws {
    let bundle = try mayaBundle()
    let reveal = try #require(bundle.card(number: 12))
    let share = try #require(bundle.card(number: 13))
    let identity = try ShareScript.make(bundle: bundle, target: .identity, format: .story, toggles: ShareToggles())
    #expect(identity.lines.contains(reveal.payload.copy?.name ?? ""))
    #expect(identity.lines.contains(share.payload.copy?.identityYear ?? ""))
    #expect(identity.lines.contains(share.payload.identity?.stat.value ?? ""))
    #expect(identity.lines.contains(share.payload.identity?.stat.label ?? ""))
    #expect(identity.lines.contains("@maya.lens"))
    #expect(!identity.lines.contains(reveal.payload.copy?.side ?? ""))

    var sideOn = ShareToggles()
    sideOn.secondPersonality = true
    let withSide = try ShareScript.make(bundle: bundle, target: .identity, format: .story, toggles: sideOn)
    #expect(withSide.lines.contains(reveal.payload.copy?.side ?? ""))

    var statsOff = ShareToggles()
    statsOff.stats = false
    let quiet = try ShareScript.make(bundle: bundle, target: .identity, format: .story, toggles: statsOff)
    #expect(!quiet.lines.contains(share.payload.identity?.stat.value ?? ""))

    var handleOff = ShareToggles()
    handleOff.handle = false
    let unnamed = try ShareScript.make(bundle: bundle, target: .identity, format: .story, toggles: handleOff)
    #expect(!unnamed.lines.contains("@maya.lens"))

    let numbers = try ShareScript.make(bundle: bundle, target: .numbers, format: .story, toggles: ShareToggles())
    #expect(numbers.lines.contains(share.payload.copy?.numbersTitle ?? ""))
    #expect(numbers.lines.contains("412"))
    #expect(numbers.lines.contains("Stories"))
    #expect(numbers.lines.contains(share.payload.numbers?.topInterest ?? ""))
    #expect(numbers.showsCoverPhoto)
    var photoOff = ShareToggles()
    photoOff.coverPhoto = false
    let bare = try ShareScript.make(bundle: bundle, target: .numbers, format: .story, toggles: photoOff)
    #expect(!bare.showsCoverPhoto)

    let square = try ShareScript.make(bundle: bundle, target: .identity, format: .square, toggles: ShareToggles())
    #expect(square.lines.contains(reveal.payload.copy?.name ?? ""))
    #expect(square.stats.isEmpty)
    #expect(!square.showsFooter)

    for number in ShareTarget.journeyNumbers {
        let card = try #require(bundle.card(number: number))
        let script = try ShareScript.make(bundle: bundle, target: .journey(number), format: .story, toggles: ShareToggles())
        let expected = number == 12 ? (card.payload.copy?.name ?? "") : card.headline
        #expect(script.lines.contains(expected))
    }
    let reels = try ShareScript.make(bundle: bundle, target: .journey(5), format: .story, toggles: ShareToggles())
    #expect(reels.lines.contains("Top 5 categories by share of your Reels watch time. Other categories: 8%.") == false)
    #expect(reels.lines.contains(bundle.card(number: 5)?.payload.copy?.sent ?? ""))
}

@Test @MainActor func circleCardIsNotRenderable() throws {
    let bundle = try mayaBundle()
    #expect(throws: ShareError.notShareable) {
        try ShareRenderer.png(bundle: bundle, target: .journey(8), format: .story)
    }
    #expect(throws: ShareError.formatUnavailable) {
        try ShareRenderer.png(bundle: bundle, target: .journey(5), format: .post)
    }
}

@Test @MainActor func shareExportsMatchTheFormats() throws {
    let bundle = try mayaBundle()
    let cases: [(ShareTarget, ShareFormat, Int, Int)] = [
        (.identity, .story, 1080, 1920),
        (.identity, .post, 1080, 1350),
        (.identity, .square, 1080, 1080),
        (.numbers, .story, 1080, 1920),
        (.numbers, .post, 1080, 1350),
        (.numbers, .square, 1080, 1080),
    ]
    for item in cases {
        let data = try ShareRenderer.png(bundle: bundle, target: item.0, format: item.1)
        let image = try #require(UIImage(data: data)?.cgImage)
        #expect(image.width == item.2)
        #expect(image.height == item.3)
    }
    for number in ShareTarget.journeyNumbers {
        let data = try ShareRenderer.png(bundle: bundle, target: .journey(number), format: .story)
        let image = try #require(UIImage(data: data)?.cgImage)
        #expect(image.width == 1080)
        #expect(image.height == 1920)
    }
}

@Test func yourStoryStopsWhenTheAppIDIsMissing() {
    var pasted = false
    var opened = false
    let client = StoryShareClient(
        appID: " ",
        canOpen: { _ in true },
        open: { _ in opened = true },
        paste: { _, _, _ in pasted = true }
    )
    let result = StoryShare.yourStory(png: Data([1]), top: WrappedHex.igMagenta, bottom: WrappedHex.igMagenta, client: client)
    #expect(result == .needsAppID)
    #expect(pasted == false)
    #expect(opened == false)
}

@Test func yourStoryStopsWhenInstagramIsMissing() {
    var pasted = false
    var opened = false
    let client = StoryShareClient(
        appID: "123",
        canOpen: { _ in false },
        open: { _ in opened = true },
        paste: { _, _, _ in pasted = true }
    )
    let result = StoryShare.yourStory(png: Data([1]), top: WrappedHex.igMagenta, bottom: WrappedHex.igMagenta, client: client)
    #expect(result == .instagramMissing)
    #expect(pasted == false)
    #expect(opened == false)
    #expect(StoryShare.missingInstagram == "Instagram isn't installed")
}

@Test func yourStoryPastesTheCardColorAndOpensInstagram() {
    var pasted = ""
    var opened = ""
    let client = StoryShareClient(
        appID: "123",
        canOpen: { $0.absoluteString.hasPrefix("instagram-stories://share") },
        open: { opened = $0.absoluteString },
        paste: { _, top, bottom in pasted = "\(top) \(bottom)" }
    )
    let result = StoryShare.yourStory(png: Data([1]), top: WrappedHex.igMagenta, bottom: WrappedHex.igMagenta, client: client)
    #expect(result == .opened)
    #expect(pasted == "#D300C5 #D300C5")
    #expect(opened == "instagram-stories://share?source_application=123")
}

@Test func shareEventsAppendLocally() {
    let file = FileManager.default.temporaryDirectory.appendingPathComponent("events-\(UUID().uuidString).json")
    #expect(ShareLog.append(ShareLog.story, file: file))
    #expect(ShareLog.append(ShareLog.save, file: file))
    #expect(ShareLog.append(ShareLog.send, file: file))
    #expect(ShareLog.rows(file: file).map(\.destination) == [ShareLog.story, ShareLog.save, ShareLog.send])
}

@Test func shareSheetChoicesFollowTheCard() {
    #expect(ShareChoice.choices(openedFrom: 13).map(\.title) == ["Identity card", "Numbers card"])
    #expect(ShareChoice.choices(openedFrom: 5).map(\.title) == ["Reels", "Identity card", "Numbers card"])
    #expect(ShareChoice.choices(openedFrom: 8).isEmpty)
}

@Test func copyLinkStopsWhenOffline() async {
    let calls = ShareCallCount()
    let client = ShareLinkClient(online: false, baseURL: "http://127.0.0.1:3000") { _, _, _, _ in
        calls.add()
        return "abc"
    }
    let result = await ShareLink.copy(png: Data([1]), cardType: "shareCards", format: "story", alt: "MY 2026", client: client)
    #expect(result == .offline)
    #expect(calls.value == 0)
}

@Test func copyLinkStopsWhenTheBaseURLIsMissing() async {
    let client = ShareLinkClient(online: true, baseURL: " ") { _, _, _, _ in "abc" }
    let result = await ShareLink.copy(png: Data([1]), cardType: "shareCards", format: "story", alt: "MY 2026", client: client)
    #expect(result == .unavailable)
}

@Test func copyLinkReturnsTheLandingURL() async {
    let client = ShareLinkClient(online: true, baseURL: "http://127.0.0.1:3000") { _, cardType, format, alt in
        #expect(cardType == "shareCards")
        #expect(format == "story")
        #expect(alt == "MY 2026")
        return "maya2026card"
    }
    let result = await ShareLink.copy(png: Data([1]), cardType: "shareCards", format: "story", alt: "MY 2026", client: client)
    #expect(result == .copied("http://127.0.0.1:3000/s/maya2026card"))
    #expect(ShareLink.copied == "Link copied. Add it with the link sticker.")
    #expect(ShareLink.cardType(for: .journey(5)) == "reelsRabbitHole")
    #expect(ShareLink.cardType(for: .numbers) == "shareCards")
}

@Test func hidingOneStatLeavesTheOthers() throws {
    let bundle = try mayaBundle()
    var toggles = ShareToggles()
    toggles.omittedStats = ["Stories"]
    let script = try ShareScript.make(bundle: bundle, target: .numbers, format: .story, toggles: toggles)
    #expect(script.lines.contains("Stories") == false)
    #expect(script.lines.contains("Posts"))
}

@Test func voiceOverSummariesUseEachCardsCopy() throws {
    let bundle = try mayaBundle()
    let summaries = (1...13).map { CardVoice.summary(bundle: bundle, card: $0) }
    #expect(summaries.allSatisfy { !$0.isEmpty })
    #expect(summaries[0].contains("2026 LOOKED GOOD ON YOU."))
    #expect(summaries[0].contains("Built from your own posts and Stories, Jan 1 to Nov 15."))
    #expect(summaries[1].contains("9 posts, 61 Stories."))
    #expect(summaries[2].contains("Midnight Camel"))
    #expect(summaries[2].contains("1,840 liked posts"))
    #expect(summaries[3].contains("63 watched. No judgment."))
    #expect(summaries[4].contains("Ceramics, 4x since June"))
    #expect(summaries[4].contains("1,206"))
    #expect(summaries[5].contains("2,184 likes"))
    #expect(summaries[5].contains("418 comments. Unhinged ones."))
    #expect(summaries[6].contains("Story · Mar 14"))
    #expect(summaries[7].contains("No ranking, no scores."))
    #expect(summaries[7].contains("dee.films, jules.mp, nico_k, sam.wav, tori.eats"))
    #expect(summaries[8].contains("3:42 AM"))
    #expect(summaries[9].contains("In June you fell into ceramics and never climbed out."))
    #expect(summaries[10].contains("You saved 1,214 posts"))
    #expect(summaries[11].contains("70% Curator match"))
    #expect(summaries[11].contains("30% Ghost match"))
    #expect(summaries[12].contains("MY 2026"))
    #expect(summaries[12].contains("2026 IN NUMBERS"))
}

@Test func hubUsesTheRunCopyAndDropsAHiddenCard() throws {
    let bundle = try mayaBundle()
    let highlights = HubBoard.highlights(in: bundle, hidden: [])
    #expect(highlights.map(\.title) == ["11 months", "2,184 likes", "Ceramics", "THE CURATOR"])
    #expect(highlights.map(\.detail) == [
        "Play the 15-second recap",
        "Jul 19, 3x your average",
        "4x since June",
        "with a side of The Ghost"
    ])
    let tiles = HubBoard.tiles(in: bundle, hidden: [6])
    #expect(tiles.count == 12)
    #expect(tiles.contains { $0.card == 6 } == false)
    #expect(HubBoard.highlights(in: bundle, hidden: [6]).contains { $0.card == 6 } == false)
    #expect(tiles.first { $0.card == 8 }?.locked == true)
    #expect(tiles.first { $0.card == 3 }?.title == "Midnight Camel")
    #expect(tiles.first { $0.card == 4 }?.title == "Ceramic frogs")
    #expect(bundle.run.copy.summary == "13 cards. Replay them, remix them, share the ones you like.")
    #expect(HubBoard.viewAllTitle(count: tiles.count) == "View all 12")
}

@Test func teenHubOmitsTheCircleAndTheNightCard() throws {
    let url = try #require(Bundle(for: RunBundleProbe.self).url(forResource: "maya-teen", withExtension: "json"))
    let bundle = try JSONDecoder().decode(RunBundle.self, from: Data(contentsOf: url))
    let tiles = HubBoard.tiles(in: bundle, hidden: [])
    #expect(tiles.map(\.card) == [1, 2, 3, 4, 5, 6, 7, 10, 11, 12, 13])
    #expect(HubBoard.viewAllTitle(count: tiles.count) == "View all 11")
    #expect(bundle.run.copy.summary == "11 cards. Replay them, remix them, share the ones you like.")
}

private final class ShareCallCount: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func add() {
        lock.lock()
        count += 1
        lock.unlock()
    }

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }
}

private func mayaBundle() throws -> RunBundle {
    let url = try #require(Bundle(for: RunBundleProbe.self).url(forResource: "maya", withExtension: "json"))
    return try JSONDecoder().decode(RunBundle.self, from: Data(contentsOf: url))
}
