import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var session: AppSession
    @State private var confirmEnd = false

    var body: some View {
        LockoutScreen(
            eyebrow: session.health.overall == .compromised ? "Interrupted" : "Active",
            title: dashboardTitle,
            subtitle: dashboardSubtitle
        ) {
            VStack(alignment: .leading, spacing: 16) {
                if let bannerError = session.bannerError {
                    LockoutErrorBanner(message: bannerError)
                }

                HealthCard(health: session.health)

                SelectionTokenList(selection: session.selection)

                if let commitment = session.commitment {
                    LockoutCard {
                        metaRow("Session", commitment.id.uuidString)
                        metaRow("Status", commitment.status.rawValue)
                        metaRow("Phase", commitment.phaseIdentifier)
                        if let activatedAt = commitment.activatedAt {
                            metaRow("Applied", Self.dateFormatter.string(from: activatedAt))
                        }
                        Text(commitment.honestyNote)
                            .font(.system(size: 13))
                            .foregroundStyle(LockoutTheme.muted)
                            .padding(.top, 4)
                    }
                }

                Button("End local session (development)") {
                    confirmEnd = true
                }
                .buttonStyle(LockoutSecondaryButtonStyle())

                Text("This control exists only in Phase 1 so developers can iterate. A later server-backed commitment will not offer instant removal from this screen.")
                    .font(.system(size: 13))
                    .foregroundStyle(LockoutTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .alert("End this local session?", isPresented: $confirmEnd) {
            Button("Cancel", role: .cancel) {}
            Button("Remove shields", role: .destructive) {
                Task { await session.endLocalDevelopmentSession() }
            }
        } message: {
            Text("This clears Managed Settings shields on this device and marks the Phase 1 record ended. It is a development control, not a product unlock flow.")
        }
    }

    private var dashboardTitle: String {
        switch session.health.overall {
        case .healthy:
            return "Shields are applied"
        case .compromised:
            return "Protection was interrupted"
        case .inactive:
            return "No active session"
        }
    }

    private var dashboardSubtitle: String {
        switch session.health.overall {
        case .healthy:
            return "iOS is shielding the tokens you selected. This Phase 1 session is local and reversible — not commitment-locked."
        case .compromised:
            return "Authorization or the Managed Settings store no longer matches the stored selection. Lockout will not claim you are protected."
        case .inactive:
            return "There is no active local session."
        }
    }

    private func metaRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LockoutTheme.muted)
            Text(value)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(LockoutTheme.text)
                .textSelection(.enabled)
        }
        .padding(.bottom, 6)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
