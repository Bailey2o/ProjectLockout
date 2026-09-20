import SwiftUI

struct CommitmentConfirmationView: View {
    @EnvironmentObject private var session: AppSession
    @State private var understoodLocal = false
    @State private var understoodReversible = false
    @State private var understoodApply = false

    private var canActivate: Bool {
        understoodLocal && understoodReversible && understoodApply && !session.isBusy
    }

    var body: some View {
        LockoutScreen(
            eyebrow: "Confirmation",
            title: "Apply a local development session",
            subtitle: "Phase 1 is honest on purpose: this is local and reversible. It is not a server-backed commitment and it is not permanent."
        ) {
            VStack(alignment: .leading, spacing: 16) {
                if let bannerError = session.bannerError {
                    LockoutErrorBanner(message: bannerError)
                }

                LockoutCard {
                    summaryRow("Apps", session.restriction.applicationTokens.count)
                    summaryRow("Categories", session.restriction.categoryTokens.count)
                    summaryRow("Web domains", session.restriction.webDomainTokens.count)
                    summaryRow("Authorization", session.authorizationStatus.lockoutTitle)
                }

                LockoutCard {
                    Toggle(isOn: $understoodLocal) {
                        Text("I understand this Phase 1 session is stored on this device only. There is no server-side lock yet.")
                            .font(.system(size: 15))
                            .foregroundStyle(LockoutTheme.text)
                    }
                    .tint(LockoutTheme.accent)

                    Toggle(isOn: $understoodReversible) {
                        Text("I understand I can reverse this from Lockout, by revoking Screen Time access in Settings, or by deleting the app.")
                            .font(.system(size: 15))
                            .foregroundStyle(LockoutTheme.text)
                    }
                    .tint(LockoutTheme.accent)

                    Toggle(isOn: $understoodApply) {
                        Text("I want iOS to shield the apps, categories, and websites I selected.")
                            .font(.system(size: 15))
                            .foregroundStyle(LockoutTheme.text)
                    }
                    .tint(LockoutTheme.accent)
                }
                .toggleStyle(.switch)

                Text("Later versions will add timed unlock and guardian approval. Those modes will not offer an instant in-app unlock. This build still does, because it is a development proof of concept.")
                    .font(.system(size: 13))
                    .foregroundStyle(LockoutTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    Task { await session.activateLocalSession() }
                } label: {
                    if session.isBusy {
                        ProgressView()
                            .tint(LockoutTheme.background)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Apply shields")
                    }
                }
                .buttonStyle(LockoutPrimaryButtonStyle(enabled: canActivate))
                .disabled(!canActivate)

                Button("Back") {
                    session.go(to: .selection)
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(LockoutTheme.muted)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func summaryRow(_ title: String, _ value: Int) -> some View {
        summaryRow(title, "\(value)")
    }

    private func summaryRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(LockoutTheme.muted)
            Spacer()
            Text(value)
                .foregroundStyle(LockoutTheme.text)
                .fontWeight(.semibold)
        }
        .font(.system(size: 15))
    }
}
