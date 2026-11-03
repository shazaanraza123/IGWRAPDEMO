import Network
import os
import Photos
import Supabase
import UIKit

enum StoryShareResult: Equatable {
    case needsAppID
    case instagramMissing
    case opened
    case saved
    case saveDenied
    case saveFailed
}

struct StoryShareClient {
    var appID: String
    var canOpen: (URL) -> Bool
    var open: (URL) -> Void
    var paste: (Data, String, String) -> Void
}

enum StoryShare {
    static let missingInstagram = "Instagram isn't installed"
    static let missingAppID = "Add a Facebook App ID in Config.xcconfig"
    static let photoDenied = "Photo access is off. Open Settings"
    static let saved = "Saved to Photos"

    static let imageKey = "com.instagram.sharedSticker.backgroundImage"
    static let topKey = "com.instagram.sharedSticker.backgroundTopColor"
    static let bottomKey = "com.instagram.sharedSticker.backgroundBottomColor"

    static func url(appID: String) -> URL? {
        let id = appID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return nil }
        return URL(string: "instagram-stories://share?source_application=\(id)")
    }

    static func colors(for target: ShareTarget) -> (top: String, bottom: String) {
        switch target {
        case .identity:
            return (WrappedHex.igMagenta, WrappedHex.igMagenta)
        case .numbers:
            return (WrappedHex.igPink, WrappedHex.paper)
        case .journey(let number):
            let hex = WrappedHex.field(number)
            return (hex, hex)
        }
    }

    /// Empty app id stops before the pasteboard. A missing Instagram app does not open the URL.
    static func yourStory(png: Data, top: String, bottom: String, client: StoryShareClient) -> StoryShareResult {
        guard let url = url(appID: client.appID) else { return .needsAppID }
        guard client.canOpen(url) else { return .instagramMissing }
        client.paste(png, top, bottom)
        client.open(url)
        return .opened
    }

    @MainActor
    static func liveClient() -> StoryShareClient {
        StoryShareClient(
            appID: (Bundle.main.object(forInfoDictionaryKey: "FACEBOOK_APP_ID") as? String) ?? "",
            canOpen: { UIApplication.shared.canOpenURL($0) },
            open: { UIApplication.shared.open($0) },
            paste: { image, top, bottom in
                let item: [String: Any] = [
                    imageKey: image,
                    topKey: top,
                    bottomKey: bottom
                ]
                UIPasteboard.general.setItems(
                    [item],
                    options: [.expirationDate: Date().addingTimeInterval(300)]
                )
            }
        )
    }

    @MainActor
    static func saveToPhotos(_ data: Data) async -> StoryShareResult {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized else { return .saveDenied }
        let wrote = await writePhoto(data)
        return wrote ? .saved : .saveFailed
    }

    /// The photo library runs this block on its own queue. It must not be main-actor isolated.
    nonisolated private static func writePhoto(_ data: Data) async -> Bool {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: data, options: nil)
            }, completionHandler: { success, _ in
                continuation.resume(returning: success)
            })
        }
    }

    @MainActor
    static func presentSend(_ data: Data) {
        guard let image = UIImage(data: data),
              let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController
        else { return }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        let controller = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        top.present(controller, animated: true)
    }

    @MainActor
    static func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

enum ShareLinkResult: Equatable {
    case copied(String)
    case offline
    case unavailable
}

struct ShareLinkClient: Sendable {
    var online: Bool
    var baseURL: String
    var publish: @Sendable (Data, String, String, String) async -> String?
}

enum ShareLink {
    static let copied = "Link copied. Add it with the link sticker."

    static func cardType(for target: ShareTarget) -> String {
        switch target {
        case .identity, .numbers:
            return "shareCards"
        case .journey(let number):
            switch number {
            case 3: return "feedColor"
            case 4: return "yourAlgorithm"
            case 5: return "reelsRabbitHole"
            case 6: return "mainCharacterPost"
            case 7: return "brokeTheGroupChat"
            case 9: return "threeAmClub"
            case 10: return "plotTwist"
            case 12: return "personalityReveal"
            default: return "shareCards"
            }
        }
    }

    static func url(base: String, slug: String) -> String? {
        let trimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !slug.isEmpty, let root = URL(string: trimmed) else { return nil }
        return root.appending(path: "s").appending(path: slug).absoluteString
    }

    /// Uploads only when `online` is true. An empty base URL or a failed publish copies nothing.
    static func copy(
        png: Data,
        cardType: String,
        format: String,
        alt: String,
        client: ShareLinkClient
    ) async -> ShareLinkResult {
        guard client.online else { return .offline }
        guard url(base: client.baseURL, slug: "pending") != nil else { return .unavailable }
        guard let slug = await client.publish(png, cardType, format, alt), !slug.isEmpty else { return .unavailable }
        guard let link = url(base: client.baseURL, slug: slug) else { return .unavailable }
        return .copied(link)
    }

    @MainActor
    static func liveClient() async -> ShareLinkClient {
        let base = (Bundle.main.object(forInfoDictionaryKey: "SHARE_BASE_URL") as? String) ?? ""
        let online = await isOnline()
        return ShareLinkClient(online: online, baseURL: base) { png, cardType, format, alt in
            await publish(png: png, cardType: cardType, format: format, alt: alt)
        }
    }

    @MainActor
    private static func publish(png: Data, cardType: String, format: String, alt: String) async -> String? {
        guard Backend.active, let client = SessionStore.shared.client else { return nil }
        let allowed = ["story", "post", "square"]
        guard allowed.contains(format) else { return nil }
        let text = alt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        do {
            let session = try await client.auth.session
            let cards: [ShareCardRef] = try await client
                .from("cards")
                .select("id")
                .eq("type", value: cardType)
                .limit(1)
                .execute()
                .value
            guard let card = cards.first else { return nil }
            let slug = makeSlug()
            let path = "\(session.user.id.uuidString.lowercased())/\(slug).png"
            try await client.storage
                .from("shares")
                .upload(path, data: png, options: FileOptions(contentType: "image/png"))
            let row = SnapshotInsert(
                slug: slug,
                cardId: card.id,
                ownerId: session.user.id,
                format: format,
                style: "bold",
                imagePath: path,
                altText: text
            )
            try await client.from("share_snapshots").insert(row).execute()
            return slug
        } catch {
            return nil
        }
    }

    private static func makeSlug() -> String {
        let alphabet = Array("abcdefghijklmnopqrstuvwxyz0123456789")
        var generator = SystemRandomNumberGenerator()
        return String((0..<12).map { _ in alphabet.randomElement(using: &generator)! })
    }

    private static func isOnline() async -> Bool {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let resumed = OSAllocatedUnfairLock(initialState: false)
            monitor.pathUpdateHandler = { path in
                let first = resumed.withLock { value -> Bool in
                    if value { return false }
                    value = true
                    return true
                }
                guard first else { return }
                monitor.cancel()
                continuation.resume(returning: path.status == .satisfied)
            }
            monitor.start(queue: DispatchQueue(label: "igwrapped.reachability"))
        }
    }
}

private struct ShareCardRef: Decodable {
    let id: UUID
}

private struct SnapshotInsert: Encodable {
    let slug: String
    let cardId: UUID
    let ownerId: UUID
    let format: String
    let style: String
    let imagePath: String
    let altText: String

    enum CodingKeys: String, CodingKey {
        case slug
        case cardId = "card_id"
        case ownerId = "owner_id"
        case format
        case style
        case imagePath = "image_path"
        case altText = "alt_text"
    }
}

enum ShareLog {
    struct Row: Codable, Equatable {
        var destination: String
        var createdAt: String
    }

    static let story = "story"
    static let save = "save"
    static let send = "send"
    static let link = "link"

    static var localFile: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("IGWrapped", isDirectory: true)
            .appendingPathComponent("share-events.json")
    }

    static func rows(file: URL) -> [Row] {
        guard let data = try? Data(contentsOf: file) else { return [] }
        return (try? JSONDecoder().decode([Row].self, from: data)) ?? []
    }

    static func append(_ destination: String, file: URL? = nil) -> Bool {
        guard let file = file ?? localFile else { return false }
        do {
            try FileManager.default.createDirectory(
                at: file.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            var existing = rows(file: file)
            let stamp = ISO8601DateFormatter().string(from: Date())
            existing.append(Row(destination: destination, createdAt: stamp))
            try JSONEncoder().encode(existing).write(to: file, options: .atomic)
            return true
        } catch {
            return false
        }
    }
}
