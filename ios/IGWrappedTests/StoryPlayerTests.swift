import AVFoundation
import Foundation
import Testing
@testable import IGWrapped

@Test func chaptersMatchTheDecisions() {
    #expect(Chapter.memories.cards == 1 ... 2)
    #expect(Chapter.interests.cards == 3 ... 5)
    #expect(Chapter.moments.cards == 6 ... 7)
    #expect(Chapter.people.cards == 8 ... 9)
    #expect(Chapter.identity.cards == 10 ... 13)
    #expect(Chapter.containing(9) == .people)
    #expect(Chapter.containing(10) == .identity)
}

@Test func tapZonesMoveOneCardAndRestartTheFirst() {
    var model = StoryPlayerModel()
    #expect(model.tap(xFraction: 0.8) == .moved)
    #expect(model.card == 2)
    model.elapsed = 3
    #expect(model.tap(xFraction: 0.1) == .moved)
    #expect(model.card == 1)
    #expect(model.elapsed == 0)
    model.elapsed = 4
    #expect(model.tap(xFraction: 0) == .same)
    #expect(model.card == 1)
    #expect(model.elapsed == 0)
}

@Test func rightEdgeOfTheLastCardFinishes() {
    var model = StoryPlayerModel()
    model.card = 13
    #expect(model.tap(xFraction: 0.9) == .finished)
    #expect(model.card == 13)
}

@Test func chapterSwipeLandsOnTheNeighborChapter() {
    var model = StoryPlayerModel()
    model.card = 2
    #expect(model.jumpChapter(forward: true) == .moved)
    #expect(model.card == 3)
    model.card = 4
    #expect(model.jumpChapter(forward: false) == .moved)
    #expect(model.card == 1)
    model.card = 1
    #expect(model.jumpChapter(forward: false) == .same)
    model.card = 12
    #expect(model.jumpChapter(forward: true) == .same)
    #expect(model.card == 12)
}

@Test func durationsFollowTheAppFlow() {
    var model = StoryPlayerModel()
    #expect(model.duration == 6)
    for card in [2, 10, 12] {
        model.card = card
        #expect(model.duration == 9)
    }
    model.card = 11
    #expect(model.duration == 6)
    #expect(model.showsInfoButton == false)
    #expect(model.tick(delta: 8) == .same)
    #expect(model.card == 11)
    #expect(model.reveal() == .moved)
    #expect(model.card == 12)
    #expect(model.autoplay == false)
    #expect(model.tick(delta: 20) == .same)
    #expect(model.card == 12)
    model.card = 3
    #expect(model.showsInfoButton)
}

@Test func toastClearsWhenTheCardAdvances() {
    var model = StoryPlayerModel()
    model.card = 4
    let generation = model.showToast("Got it. We'll tune Explore.")
    #expect(model.toast == "Got it. We'll tune Explore.")
    #expect(model.goForward() == .moved)
    #expect(model.card == 5)
    #expect(model.toast == nil)
    model.expireToast(generation: generation)
    #expect(model.toast == nil)

    model.showToast("Got it. We'll tune Explore.")
    #expect(model.goBack() == .moved)
    #expect(model.card == 4)
    #expect(model.toast == nil)

    model.showToast("Got it. We'll tune Explore.")
    #expect(model.jumpChapter(forward: true) == .moved)
    #expect(model.card == 6)
    #expect(model.toast == nil)
}

@Test func holdAndInfoPauseTheClock() {
    var model = StoryPlayerModel()
    model.isHolding = true
    #expect(model.tick(delta: 8) == .same)
    #expect(model.card == 1)
    #expect(model.elapsed == 0)
    model.isHolding = false
    model.infoOpen = true
    #expect(model.tick(delta: 8) == .same)
    model.infoOpen = false
    model.autoplay = false
    #expect(model.tick(delta: 8) == .same)
    model.autoplay = true
    model.coverOpen = true
    #expect(model.tick(delta: 8) == .same)
    model.coverOpen = false
    #expect(model.tick(delta: 6) == .moved)
    #expect(model.card == 2)
    #expect(model.elapsed == 0)
}

@Test func dragClassificationMatchesTheGestures() {
    var model = StoryPlayerModel()
    #expect(model.dragEnded(dx: 4, dy: 4, velocityX: 0, velocityY: 0) == .tap)
    #expect(model.dragEnded(dx: 0, dy: 160, velocityX: 0, velocityY: 0) == .dismiss)
    #expect(model.dragEnded(dx: 0, dy: -160, velocityX: 0, velocityY: 0) == .info)
    #expect(model.dragEnded(dx: -200, dy: 10, velocityX: 0, velocityY: 0) == .nextChapter)
    #expect(model.dragEnded(dx: 200, dy: 10, velocityX: 0, velocityY: 0) == .previousChapter)
    #expect(model.dragEnded(dx: 0, dy: 40, velocityX: 0, velocityY: 0) == .cancel)
    #expect(StoryPlayerModel.transition(reduceMotion: true) == .crossfade)
    #expect(StoryPlayerModel.transition(reduceMotion: false) == .cube)
}

@Test func progressIsSaved() {
    let defaults = UserDefaults(suiteName: "player-progress-test")!
    defaults.removePersistentDomain(forName: "player-progress-test")
    let progress = PlayerProgress(card: 4, elapsed: 1.5)
    PlayerProgressStore.save(progress, defaults: defaults, pitch: false)
    #expect(PlayerProgressStore.load(defaults: defaults, pitch: false) == progress)
}

@Test func pitchKeepsUnbuiltActionsQuietAndDoesNotResume() {
    #expect(Feature.isBuilt(.share))
    #expect(Feature.toast(for: .share, pitch: false) == nil)
    #expect(Feature.toast(for: .share, pitch: true) == nil)
    for feature in Feature.allCases where feature != .share {
        #expect(Feature.isBuilt(feature) == false)
        #expect(Feature.toast(for: feature, pitch: false) == Feature.unavailable)
        #expect(Feature.toast(for: feature, pitch: true) == nil)
    }
    let defaults = UserDefaults(suiteName: "player-progress-pitch")!
    defaults.removePersistentDomain(forName: "player-progress-pitch")
    PlayerProgressStore.save(PlayerProgress(card: 4, elapsed: 1.5), defaults: defaults, pitch: true)
    #expect(PlayerProgressStore.load(defaults: defaults, pitch: false) == nil)
    PlayerProgressStore.save(PlayerProgress(card: 4, elapsed: 1.5), defaults: defaults, pitch: false)
    #expect(PlayerProgressStore.load(defaults: defaults, pitch: true) == nil)
}

@Test @MainActor func musicFollowsChaptersAndRespectsTheSilentSwitch() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    for chapter in Chapter.allCases {
        try writeSilence(to: directory.appendingPathComponent("\(chapter.rawValue).wav"))
    }
    let service = AudioService(directory: directory)
    #expect(service.respectsSilentSwitch)
    #expect(service.sessionCategory != .playback)

    service.play(.memories)
    #expect(service.chapter == .memories)
    #expect(service.isPlaying(.memories))

    service.play(.interests)
    #expect(service.chapter == .interests)
    #expect(service.volume(for: .interests) == 0)
    try await Task.sleep(for: .seconds(1))
    #expect(service.volume(for: .interests) > 0.9)
    #expect(service.isPlaying(.memories) == false)

    service.setDucked(true)
    #expect(service.volume(for: .interests) < 0.5)
    service.setDucked(false)
    #expect(service.volume(for: .interests) > 0.9)
    service.setMuted(true)
    #expect(service.isPlaying(.interests) == false)
    service.stop()
    try? FileManager.default.removeItem(at: directory)
}

@Test @MainActor func missingTracksStillFollowTheChapter() {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let service = AudioService(directory: directory)
    service.play(.people)
    #expect(service.chapter == .people)
    #expect(service.isPlaying(.people) == false)
    service.play(.identity)
    #expect(service.chapter == .identity)
}

private func writeSilence(to url: URL) throws {
    let sampleRate: UInt32 = 8_000
    let frames: UInt32 = 800
    var data = Data()
    func append(_ string: String) {
        data.append(contentsOf: string.utf8)
    }
    func append32(_ value: UInt32) {
        var little = value.littleEndian
        withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }
    func append16(_ value: UInt16) {
        var little = value.littleEndian
        withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }
    let dataSize = frames * 2
    append("RIFF")
    append32(36 + dataSize)
    append("WAVE")
    append("fmt ")
    append32(16)
    append16(1)
    append16(1)
    append32(sampleRate)
    append32(sampleRate * 2)
    append16(2)
    append16(16)
    append("data")
    append32(dataSize)
    data.append(Data(count: Int(dataSize)))
    try data.write(to: url)
}
