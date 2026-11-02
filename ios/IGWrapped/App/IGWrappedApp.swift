import SwiftUI

@main
struct IGWrappedApp: App {
    init() {
        ArchivoFont.registerIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--styleguide") {
                StyleguideView()
            } else {
                InstagramShellView()
            }
            #else
            InstagramShellView()
            #endif
        }
    }
}
