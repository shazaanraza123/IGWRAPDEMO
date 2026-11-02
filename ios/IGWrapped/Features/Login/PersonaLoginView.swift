import Supabase
import SwiftUI

struct DemoPersona: Identifiable {
    let key: String
    let name: String
    let handle: String
    let detail: String
    var id: String { key }

    static let all = [
        DemoPersona(key: "maya", name: "Maya", handle: "maya.lens", detail: "Personal"),
        DemoPersona(key: "ghost", name: "ghost", handle: "ghost", detail: "Personal"),
        DemoPersona(key: "connector", name: "connector", handle: "connector", detail: "Personal"),
        DemoPersona(key: "emerging", name: "emerging", handle: "emerging", detail: "Creator"),
        DemoPersona(key: "established", name: "established", handle: "established", detail: "Creator"),
        DemoPersona(key: "teen", name: "Maya", handle: "maya.teen", detail: "Teen"),
    ]
}

private struct ClaimResult: Decodable {
    let tier: String
    let cards: Int
    let displayName: String
    let handle: String

    enum CodingKeys: String, CodingKey {
        case tier, cards, handle
        case displayName = "display_name"
    }
}

private struct ReadySession: Equatable {
    let name: String
    let handle: String
    let cards: Int
    let tier: String
}

private struct ProfileSnapshot: Decodable {
    let displayName: String
    let handle: String

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case handle
    }
}

private struct CardID: Decodable {
    let id: UUID
}

private struct ClaimBody: Encodable {
    let personaKey: String

    enum CodingKeys: String, CodingKey {
        case personaKey = "persona_key"
    }
}

@MainActor
@Observable
private final class LoginModel {
    var ready: ReadySession?
    var message: String?
    var isWorking = false
    var showsContext = false
    var isResolving = true

    func restore() async {
        defer { isResolving = false }
        if ProcessInfo.processInfo.arguments.contains("--reset-session") {
            await SessionStore.shared.signOut()
        }
        if !Backend.active {
            guard let key = LocalPersona.current,
                  let bundle = try? await BundledRunRepository().load(persona: key) else { return }
            let persona = DemoPersona.all.first { $0.key == key }
            ready = ReadySession(
                name: persona?.name ?? key,
                handle: persona?.handle ?? key,
                cards: bundle.cards.count,
                tier: bundle.run.tier
            )
            return
        }
        guard await SessionStore.shared.hasSession(), let client = SessionStore.shared.client else { return }
        do {
            let profiles: [ProfileSnapshot] = try await client.from("profiles").select("display_name,handle").execute().value
            guard let profile = profiles.first else { return }
            let cards: [CardID] = try await client.from("cards").select("id").execute().value
            guard !cards.isEmpty else { return }
            ready = ReadySession(name: profile.displayName, handle: profile.handle, cards: cards.count, tier: "")
        } catch {
            message = error.localizedDescription
        }
    }

    func claim(_ persona: DemoPersona) async {
        guard !isWorking else { return }
        if !Backend.active {
            isWorking = true
            message = nil
            defer { isWorking = false }
            do {
                let bundle = try await BundledRunRepository().load(persona: persona.key)
                LocalPersona.save(persona.key)
                ready = ReadySession(name: persona.name, handle: persona.handle, cards: bundle.cards.count, tier: bundle.run.tier)
            } catch {
                message = "No sample run for this account."
            }
            return
        }
        guard let client = SessionStore.shared.client else {
            message = "Sample login needs the local Supabase URL."
            return
        }
        isWorking = true
        message = nil
        defer { isWorking = false }
        do {
            if await SessionStore.shared.hasSession() == false {
                _ = try await client.auth.signInAnonymously()
            }
            let result: ClaimResult = try await client.functions.invoke(
                "claim-persona",
                options: FunctionInvokeOptions(body: ClaimBody(personaKey: persona.key))
            )
            LocalPersona.save(persona.key)
            ready = ReadySession(name: result.displayName, handle: result.handle, cards: result.cards, tier: result.tier)
        } catch {
            message = error.localizedDescription
        }
    }
}

struct PersonaLoginView: View {
    var onClaimed: () -> Void = {}
    @State private var model = LoginModel()

    var body: some View {
        ZStack {
            WrappedColor.ink.ignoresSafeArea()
            if model.isResolving {
                Color.clear
            } else if let ready = model.ready {
                readyView(ready)
            } else {
                picker
            }
        }
        .task { await model.restore() }
        .sheet(isPresented: Binding(
            get: { model.showsContext },
            set: { model.showsContext = $0 }
        )) {
            contextSheet
        }
    }

    private var picker: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WrappedSpace.gutter) {
                Text("Choose a sample account")
                    .wrappedType(.title)
                    .foregroundStyle(WrappedColor.paper)
                ForEach(DemoPersona.all) { persona in
                    Button {
                        Task {
                            await model.claim(persona)
                            if model.ready != nil {
                                onClaimed()
                            }
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: WrappedSpace.gridGap) {
                            Text(persona.name)
                                .wrappedType(.body)
                                .foregroundStyle(WrappedColor.paper)
                            Text("\(persona.handle) · \(persona.detail)")
                                .wrappedType(.caption)
                                .foregroundStyle(WrappedColor.muted)
                        }
                        .frame(maxWidth: .infinity, minHeight: WrappedSpace.minHit, alignment: .leading)
                        .padding(.horizontal, WrappedSpace.gutter)
                        .background(WrappedColor.surfaceRaised)
                    }
                    .buttonStyle(.plain)
                    .disabled(model.isWorking)
                    .accessibilityIdentifier("persona-\(persona.key)")
                }
                Button("What is this?") { model.showsContext = true }
                    .wrappedType(.body)
                    .foregroundStyle(WrappedColor.pinkOnDark)
                    .frame(minHeight: WrappedSpace.minHit)
                if model.isWorking {
                    Text("Signing in")
                        .wrappedType(.caption)
                        .foregroundStyle(WrappedColor.muted)
                }
                if let message = model.message {
                    Text(message)
                        .wrappedType(.caption)
                        .foregroundStyle(WrappedColor.likeRed)
                }
                Text("Concept prototype. Not affiliated with Instagram. Sample data.")
                    .wrappedType(.caption)
                    .foregroundStyle(WrappedColor.muted)
            }
            .padding(WrappedSpace.gutter)
        }
    }

    private func readyView(_ ready: ReadySession) -> some View {
        VStack(alignment: .leading, spacing: WrappedSpace.gutter) {
            Text("Wrapped is ready")
                .wrappedType(.title)
                .foregroundStyle(WrappedColor.paper)
                .accessibilityIdentifier("wrapped-ready")
            Text("\(ready.name) · \(ready.handle)")
                .wrappedType(.body)
                .foregroundStyle(WrappedColor.paper)
            Text("\(ready.cards) cards")
                .wrappedType(.caption)
                .foregroundStyle(WrappedColor.muted)
            Text("Concept prototype. Not affiliated with Instagram. Sample data.")
                .wrappedType(.caption)
                .foregroundStyle(WrappedColor.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(WrappedSpace.gutter)
    }

    private var contextSheet: some View {
        ZStack {
            WrappedColor.sheet.ignoresSafeArea()
            VStack(alignment: .leading, spacing: WrappedSpace.gutter) {
                Text("What is this?")
                    .wrappedType(.title)
                    .foregroundStyle(WrappedColor.paper)
                Text("Each card is a sample account. Signing in creates an anonymous session and builds that account's Wrapped from sample data.")
                    .wrappedType(.body)
                    .foregroundStyle(WrappedColor.paper)
                Text("Concept prototype. Not affiliated with Instagram. Sample data.")
                    .wrappedType(.caption)
                    .foregroundStyle(WrappedColor.muted)
            }
            .padding(WrappedSpace.gutter)
        }
        .presentationDetents([.medium])
    }
}
