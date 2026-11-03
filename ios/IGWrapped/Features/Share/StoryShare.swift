import Photos
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
    static let linksLater = "Links come with the web page"
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

enum ShareLog {
    struct Row: Codable, Equatable {
        var destination: String
        var createdAt: String
    }

    static let story = "story"
    static let save = "save"
    static let send = "send"

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
