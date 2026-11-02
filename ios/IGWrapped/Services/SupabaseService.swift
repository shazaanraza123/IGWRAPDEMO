import Foundation
import Supabase

enum AppConfig {
    static var supabaseURL: URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String, !raw.isEmpty else {
            return nil
        }
        return URL(string: raw)
    }

    static var supabaseAnonKey: String? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String, !key.isEmpty else {
            return nil
        }
        return key
    }
}

@MainActor
final class SessionStore {
    static let shared = SessionStore()

    let client: SupabaseClient?

    private init() {
        guard Backend.active, let url = AppConfig.supabaseURL, let key = AppConfig.supabaseAnonKey else {
            client = nil
            print("igwrapped offline: no network client")
            return
        }
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key,
            options: SupabaseClientOptions(auth: .init(emitLocalSessionAsInitialSession: true))
        )
    }

    func hasSession() async -> Bool {
        if Backend.active {
            guard let client else { return false }
            return (try? await client.auth.session) != nil
        }
        return LocalPersona.current != nil
    }

    func signOut() async {
        LocalPersona.clear()
        HiddenCards.clear()
        try? await client?.auth.signOut()
    }
}
