import SwiftUI

@main
struct IGWrappedApp: App {
    init() {
        ArchivoFont.registerIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            StyleguideView()
            #else
            WrappedColor.ink.ignoresSafeArea()
            #endif
        }
    }
}
