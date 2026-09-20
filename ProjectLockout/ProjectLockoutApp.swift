import SwiftUI

@main
struct ProjectLockoutApp: App {
    @StateObject private var session: AppSession

    init() {
        // Create the session before wrapping it so `@StateObject`'s autoclosure
        // does not evaluate a main-actor initializer in a nonisolated context.
        let session = AppSession.make()
        _session = StateObject(wrappedValue: session)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .onAppear {
                    session.start()
                }
        }
    }
}
