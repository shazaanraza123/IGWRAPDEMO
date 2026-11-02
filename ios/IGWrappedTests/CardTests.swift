import Foundation
import Testing
@testable import IGWrapped

@Test func mayaCardCopyMatchesTheSchema() {
    #expect(MayaOpening.headline == "2026 looked good on you.")
    #expect(MayaOpening.support == "Built from your own posts and Stories, Jan 1 to Nov 15.")
    #expect(MayaYear.support == "August was your busiest month: 9 posts, 61 Stories.")
    #expect(MayaYear.playLabel == "PLAY YOUR YEAR · 0:15")
    #expect(MayaYear.topMonth == 8)
    #expect(MayaYear.montageSeconds == 15)
    #expect(MayaYear.months.count == 11)
    #expect(MayaFeed.footnote == "% = main color in each of 1,840 liked posts")
    #expect(MayaFeed.swatches.map(\.percent) == ["31%", "24%", "19%", "15%", "11%"])
    #expect(MayaAlgorithm.undercut == "63 watched. No judgment.")
    #expect(MayaAlgorithm.topics.map(\.name) == ["Streetwear drops", "Film cameras", "Ceramic frogs"])
    #expect(MayaAlgorithm.topics[2].undercut)
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
