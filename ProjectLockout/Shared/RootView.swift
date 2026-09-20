import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch session.route {
            case .welcome:
                WelcomeView()
            case .permission:
                PermissionView()
            case .selection:
                SelectionView()
            case .confirmation:
                CommitmentConfirmationView()
            case .dashboard:
                DashboardView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: session.route)
        .preferredColorScheme(.dark)
        .tint(LockoutTheme.accent)
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                session.refreshFromSystem()
            }
        }
    }
}
