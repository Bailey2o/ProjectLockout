import SwiftUI

struct PermissionView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        LockoutScreen(
            eyebrow: "Permission",
            title: "Allow Screen Time access",
            subtitle: "Lockout requests individual Family Controls authorization so it can apply Managed Settings shields on this device."
        ) {
            VStack(alignment: .leading, spacing: 16) {
                if let bannerError = session.bannerError {
                    LockoutErrorBanner(message: bannerError)
                }

                LockoutCard {
                    statusRow(title: "Authorization", value: session.authorizationStatus.lockoutTitle)
                    Divider().overlay(LockoutTheme.stroke)
                    Text("Apple presents the system alert and Face ID, Touch ID, or passcode prompt. Lockout never sees your browsing history — only opaque tokens you select next.")
                        .font(.system(size: 14))
                        .foregroundStyle(LockoutTheme.muted)
                }

                LockoutCard {
                    labeledPoint(
                        title: "What this enables",
                        body: "Shielding selected apps, categories, and web domains through ManagedSettingsStore."
                    )
                    labeledPoint(
                        title: "What this does not do",
                        body: "It does not prevent deleting Lockout, changing Screen Time in Settings, or erasing the device."
                    )
                    labeledPoint(
                        title: "Simulator",
                        body: "Family Controls is limited in Simulator. A physical device and the Family Controls entitlement are required for a full demonstration."
                    )
                }

                Button {
                    Task { await session.requestAuthorization() }
                } label: {
                    if session.isBusy {
                        ProgressView()
                            .tint(LockoutTheme.background)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(session.authorizationStatus == .approved ? "Authorization approved" : "Allow Screen Time access")
                    }
                }
                .buttonStyle(LockoutPrimaryButtonStyle(enabled: !session.isBusy))
                .disabled(session.isBusy)

                Button("Continue") {
                    session.go(to: .selection)
                }
                .buttonStyle(LockoutSecondaryButtonStyle())
                .disabled(session.authorizationStatus != .approved)
                .opacity(session.authorizationStatus == .approved ? 1 : 0.45)

                Button("Back") {
                    session.go(to: .welcome)
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(LockoutTheme.muted)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func statusRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(LockoutTheme.text)
            Spacer()
            Text(value)
                .foregroundStyle(session.authorizationStatus == .approved ? LockoutTheme.healthy : LockoutTheme.warning)
                .fontWeight(.semibold)
        }
        .font(.system(size: 15))
    }

    private func labeledPoint(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(LockoutTheme.text)
            Text(body)
                .font(.system(size: 14))
                .foregroundStyle(LockoutTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
