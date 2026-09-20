import SwiftUI

@main
struct ProjectLockoutApp: App {
    @StateObject private var session = AppSession()

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
