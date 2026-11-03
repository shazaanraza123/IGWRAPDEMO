import SwiftUI

enum WrappedRoute: Equatable {
    case login
    case building
    case beforeWeStart
    case edition
    case player
    case hub
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

    static func load() async -> (WrappedRunFacts, RunBundle)? {
        let persona = LocalPersona.current ?? "maya"
        let repository: any RunRepository = (Backend.active && AppConfig.supabaseURL != nil)
            ? SupabaseRunRepository()
            : BundledRunRepository()
        guard let bundle = try? await repository.load(persona: persona) else {
            return nil
        }
        var facts = WrappedRunFacts()
        facts.tier = bundle.run.tier
        facts.isTeen = persona == "teen"
        facts.accountType = (persona == "emerging" || persona == "established") ? "creator" : "personal"
        if Backend.active, let client = SessionStore.shared.client, await SessionStore.shared.hasSession() {
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
        }
        return (facts, bundle)
    }
}

struct WrappedEntryFlow: View {
    var onExit: () -> Void

    @State private var route: WrappedRoute = .building
    @State private var openedAt = Date()
    @State private var openSeconds = ""
    @State private var facts = WrappedRunFacts()
    @State private var bundle: RunBundle?
    @State private var failed = false
    @State private var ringFilled = false
    @State private var showsHow = false
    @State private var toast: String?
    @State private var hubCard: Int?
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
                StoryPlayer(onHub: { route = .hub }, bundle: bundle, startCard: hubCard)
                Color.clear
                    .frame(width: 1, height: 1)
                    .accessibilityIdentifier("entry-open-seconds")
                    .accessibilityLabel(openSeconds)
            case .hub:
                if let bundle {
                    WrappedHub(bundle: bundle, onBack: onExit, onOpen: { card in
                        hubCard = card
                        route = .player
                    })
                }
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
            Text(bundle?.card(number: 1)?.support ?? "")
                .wrappedType(.body)
                .foregroundStyle(WrappedColor.paper)
            entryButton("Start", identifier: "start-wrapped") {
                WrappedIntro.markSeen()
                route = WrappedEntryPlan.afterStart(
                    isProfessional: WrappedEntryPlan.isProfessional(facts.accountType)
                )
            }
            entryButton("Choose what's included", identifier: "choose-included") {
                showUnavailable(.privacy)
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
                showUnavailable(.creator)
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
                Text(bundle?.card(number: 1)?.payload.windowLabel ?? "")
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
        let loadedFacts = await loaded
        guard !Task.isCancelled else { return }
        guard let loadedFacts else {
            failed = true
            return
        }
        self.facts = loadedFacts.0
        self.bundle = loadedFacts.1
        let next = WrappedEntryPlan.afterBuilding(introSeen: WrappedIntro.hasSeen())
        if next == .player {
            openSeconds = String(format: "%.2f", Date().timeIntervalSince(openedAt))
        }
        route = next
    }

    private func showUnavailable(_ feature: Feature) {
        guard let message = Feature.toast(for: feature) else { return }
        toast = message
        Task {
            try? await Task.sleep(for: .seconds(2))
            toast = nil
        }
    }
}
