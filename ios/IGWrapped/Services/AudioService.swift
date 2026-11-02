import AVFoundation

/// One player per chapter. An 800 ms crossfade, and an ambient session so the silent switch mutes playback.
@MainActor
final class AudioService {
    static let shared = AudioService()

    private(set) var chapter: Chapter?
    private(set) var isMuted = false
    private(set) var isDucked = false
    private(set) var sessionCategory: AVAudioSession.Category = .ambient

    private var players: [Chapter: AVAudioPlayer] = [:]
    private var crossfadeTask: Task<Void, Never>?
    private let directory: URL?

    init(directory: URL? = nil) {
        self.directory = directory
        activateSession()
    }

    var respectsSilentSwitch: Bool {
        sessionCategory == .ambient || sessionCategory == .soloAmbient
    }

    func play(_ chapter: Chapter) {
        guard self.chapter != chapter else { return }
        let outgoing = self.chapter.flatMap { players[$0] }
        self.chapter = chapter
        guard let incoming = prepare(chapter) else {
            outgoing?.stop()
            return
        }
        incoming.currentTime = 0
        incoming.volume = 0
        incoming.play()
        crossfade(from: outgoing, to: incoming)
    }

    func pause() {
        guard let chapter, let player = players[chapter] else { return }
        player.pause()
    }

    func resume() {
        guard !isMuted, let chapter, let player = players[chapter] else { return }
        if !player.isPlaying {
            player.play()
        }
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
        guard let chapter, let player = players[chapter] else { return }
        player.volume = muted ? 0 : audibleVolume
        if muted {
            player.pause()
        } else if !player.isPlaying {
            player.play()
        }
    }

    func setDucked(_ ducked: Bool) {
        isDucked = ducked
        guard !isMuted, let chapter, let player = players[chapter] else { return }
        player.volume = audibleVolume
    }

    func stop() {
        crossfadeTask?.cancel()
        players.values.forEach { $0.stop() }
        chapter = nil
    }

    func volume(for chapter: Chapter) -> Float {
        players[chapter]?.volume ?? 0
    }

    func isPlaying(_ chapter: Chapter) -> Bool {
        players[chapter]?.isPlaying ?? false
    }

    private var audibleVolume: Float {
        isDucked ? WrappedMotion.duckedVolume : 1
    }

    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        sessionCategory = session.category
    }

    private func prepare(_ chapter: Chapter) -> AVAudioPlayer? {
        if let existing = players[chapter] {
            return existing
        }
        guard let url = trackURL(chapter) else { return nil }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.numberOfLoops = -1
        player.prepareToPlay()
        players[chapter] = player
        return player
    }

    private func trackURL(_ chapter: Chapter) -> URL? {
        let extensions = ["m4a", "mp3", "wav", "caf"]
        if let directory {
            for ext in extensions {
                let url = directory.appendingPathComponent("\(chapter.rawValue).\(ext)")
                if FileManager.default.fileExists(atPath: url.path) {
                    return url
                }
            }
            return nil
        }
        for ext in extensions {
            if let url = Bundle.main.url(forResource: chapter.rawValue, withExtension: ext) {
                return url
            }
        }
        return nil
    }

    private func crossfade(from outgoing: AVAudioPlayer?, to incoming: AVAudioPlayer) {
        crossfadeTask?.cancel()
        let steps = 16
        let step = WrappedMotion.chapterCrossfade / Double(steps)
        crossfadeTask = Task { @MainActor in
            for index in 1 ... steps {
                try? await Task.sleep(for: .seconds(step))
                if Task.isCancelled { return }
                let amount = Float(index) / Float(steps)
                incoming.volume = isMuted ? 0 : amount * audibleVolume
                outgoing?.volume = isMuted ? 0 : (1 - amount) * audibleVolume
            }
            outgoing?.stop()
            if !isMuted {
                incoming.volume = audibleVolume
            }
        }
    }
}
