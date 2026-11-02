import SwiftUI

enum WrappedRoute: Equatable {
    case login
    case building
    case beforeWeStart
    case edition
    case player
}

enum WrappedEntryPlan {
    static func afterOpen(hasSession: Bool) -> WrappedRoute {
        hasSession ? .building : .login
    }

    static func afterBuilding(introSeen: Bool) -> WrappedRoute {
        introSeen ? .player : .beforeWeStart
    }

    static func afterStart(isProfessional: Bool) -> WrappedRoute {
        isProfessional ? .edition : .player
    }

    static func isProfessional(_ accountType: String) -> Bool {
        accountType == "creator" || accountType == "business"
    }
}

enum WrappedIntro {
    private static let key = "igwrapped.intro-seen"

    static func hasSeen(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: key)
    }

    static func markSeen(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: key)
    }

    static func clear(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}

struct WrappedRunFacts: Equatable {
    var accountType = "personal"
    var tier = "full"
    var isTeen = false

    var omittedCards: Set<Int> { isTeen ? [8, 9] : [] }
}

@MainActor
enum WrappedRunLookup {
    private struct ProfileRow: Decodable {
        var accountType: String
        var isTeen: Bool

        enum CodingKeys: String, CodingKey {
            case accountType = "account_type"
            case isTeen = "is_teen"
        }
    }

    private struct RunRow: Decodable {
        var tier: String
    }

    static func load() async -> WrappedRunFacts? {
        guard let client = SessionStore.shared.client, await SessionStore.shared.hasSession() else {
            return nil
        }
        var facts = WrappedRunFacts()
        if let profiles: [ProfileRow] = try? await client.from("profiles")
            .select("account_type,is_teen")
            .execute()
            .value,
           let profile = profiles.first {
            facts.accountType = profile.accountType
            facts.isTeen = profile.isTeen
        }
        if let runs: [RunRow] = try? await client.from("wrapped_runs")
            .select("tier")
            .execute()
            .value,
           let run = runs.first {
            facts.tier = run.tier
        }
        return facts
    }
}

struct WrappedEntryFlow: View {
    var onExit: () -> Void

    @State private var route: WrappedRoute = .building
    @State private var openedAt = Date()
    @State private var openSeconds = ""
    @State private var facts = WrappedRunFacts()
    @State private var failed = false
    @State private var ringFilled = false
    @State private var showsHow = false
    @State private var toast: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            WrappedColor.ink.ignoresSafeArea()
            switch route {
            case .building, .login:
                building
            case .beforeWeStart:
                beforeWeStart
            case .edition:
                edition
            case .player:
                StoryPlayer(onExit: onExit, omitted: facts.omittedCards)
                Color.clear
                    .frame(width: 1, height: 1)
                    .accessibilityIdentifier("entry-open-seconds")
                    .accessibilityLabel(openSeconds)
            }
            if let toast {
                Text(toast)
                    .wrappedType(.caption)
                    .foregroundStyle(WrappedColor.ink)
                    .padding(.horizontal, WrappedSpace.gutter)
                    .frame(minHeight: WrappedSpace.minHit)
                    .background(Capsule().fill(WrappedColor.igWhite))
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, WrappedSpace.gutter)
            }
        }
        .onAppear { openedAt = Date() }
        .task { await playBuilding() }
        .sheet(isPresented: $showsHow) {
            howItWorks
        }
    }

    private var building: some View {
        VStack(spacing: WrappedSpace.gutter) {
            ZStack {
                Circle()
                    .stroke(WrappedColor.igWhite.opacity(CardSpace.barDim), lineWidth: WrappedSpace.buildingStroke)
                Circle()
                    .trim(from: 0, to: ringFilled ? 1 : 0)
                    .stroke(WrappedColor.storyRing, style: StrokeStyle(lineWidth: WrappedSpace.buildingStroke, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: WrappedSpace.buildingRing, height: WrappedSpace.buildingRing)
            .accessibilityHidden(true)
            Text(failed ? "We couldn't build your Wrapped" : "Building your year")
                .wrappedType(.title)
                .foregroundStyle(WrappedColor.paper)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("building-year")
            if facts.tier == "lite", !failed {
                Text("A lighter recap this year")
                    .wrappedType(.body)
                    .foregroundStyle(WrappedColor.paper)
            }
            if failed {
                Button("Try again") {
                    failed = false
                    Task { await playBuilding() }
                }
                .buttonStyle(.plain)
                .wrappedType(.body)
                .foregroundStyle(WrappedColor.ink)
                .padding(.horizontal, WrappedSpace.gutter)
                .frame(minHeight: WrappedSpace.minHit)
                .background(Capsule().fill(WrappedColor.igWhite))
                .accessibilityIdentifier("building-retry")
            }
        }
        .padding(WrappedSpace.gutter)
    }

    private var beforeWeStart: some View {
        VStack(alignment: .leading, spacing: WrappedSpace.gutter) {
            Text("Before we start")
                .wrappedType(.title)
                .foregroundStyle(WrappedColor.paper)
                .accessibilityIdentifier("before-we-start")
            Text("Built from your own posts and Stories, Jan 1 to Nov 15.")
                .wrappedType(.body)
                .foregroundStyle(WrappedColor.paper)
            entryButton("Start", identifier: "start-wrapped") {
                WrappedIntro.markSeen()
                route = WrappedEntryPlan.afterStart(
                    isProfessional: WrappedEntryPlan.isProfessional(facts.accountType)
                )
            }
            entryButton("Choose what's included", identifier: "choose-included") {
                showToast()
            }
            entryButton("How Wrapped works", identifier: "how-wrapped-works") {
                showsHow = true
            }
            Spacer(minLength: 0)
            Text("Concept prototype. Not affiliated with Instagram. Sample data.")
                .wrappedType(.caption)
                .foregroundStyle(WrappedColor.muted)
        }
        .padding(WrappedSpace.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var edition: some View {
        VStack(alignment: .leading, spacing: WrappedSpace.gutter) {
            Text("Which Wrapped?")
                .wrappedType(.title)
                .foregroundStyle(WrappedColor.paper)
                .accessibilityIdentifier("edition-picker")
            entryButton("Personal", identifier: "edition-personal") {
                route = .player
            }
            entryButton("Creator", identifier: "edition-creator") {
                showToast()
            }
            entryButton("Watch both", identifier: "edition-both") {
                route = .player
            }
        }
        .padding(WrappedSpace.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var howItWorks: some View {
        ZStack {
            WrappedColor.sheet.ignoresSafeArea()
            VStack(alignment: .leading, spacing: WrappedSpace.gutter) {
                Text("How Wrapped works")
                    .wrappedType(.title)
                    .foregroundStyle(WrappedColor.paper)
                Text("Jan 1 to Nov 15.")
                    .wrappedType(.body)
                    .foregroundStyle(WrappedColor.paper)
                Text("No profile-visitor data. No DM contents.")
                    .wrappedType(.body)
                    .foregroundStyle(WrappedColor.paper)
            }
            .padding(WrappedSpace.gutter)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .presentationDetents([.medium])
    }

    private func entryButton(_ title: String, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .wrappedType(.body)
                .foregroundStyle(WrappedColor.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, WrappedSpace.gutter)
                .frame(minHeight: WrappedSpace.minHit)
                .background(RoundedRectangle(cornerRadius: CardSpace.stickerRadius).fill(WrappedColor.igWhite))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }

    private func playBuilding() async {
        ringFilled = reduceMotion
        if !reduceMotion {
            withAnimation(.linear(duration: WrappedMotion.buildingMinimum)) {
                ringFilled = true
            }
        }
        async let loaded = WrappedRunLookup.load()
        try? await Task.sleep(for: .seconds(WrappedMotion.buildingMinimum))
        let facts = await loaded
        guard !Task.isCancelled else { return }
        guard let facts else {
            failed = true
            return
        }
        self.facts = facts
        let next = WrappedEntryPlan.afterBuilding(introSeen: WrappedIntro.hasSeen())
        if next == .player {
            openSeconds = String(format: "%.2f", Date().timeIntervalSince(openedAt))
        }
        route = next
    }

    private func showToast() {
        toast = "Not part of this demo"
        Task {
            try? await Task.sleep(for: .seconds(2))
            toast = nil
        }
    }
}
