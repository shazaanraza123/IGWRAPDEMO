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
                PersonaLoginView()
            }
            #else
            PersonaLoginView()
            #endif
        }
    }
}
