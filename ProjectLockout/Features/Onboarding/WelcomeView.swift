import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "lock.square")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(LockoutTheme.accent)
                    .accessibilityHidden(true)

                Text(LockoutIdentity.displayName.uppercased())
                    .font(LockoutTheme.wordmarkFont)
                    .tracking(4)
                    .foregroundStyle(LockoutTheme.text)

                Text(LockoutIdentity.tagline)
                    .font(.system(size: 22, weight: .medium, design: .serif))
                    .foregroundStyle(LockoutTheme.accent)

                Text("Decide while you are calm. Lockout uses Apple’s Screen Time APIs to shield the apps, categories, and websites you choose.")
                    .font(LockoutTheme.bodyFont)
                    .foregroundStyle(LockoutTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                LockoutCard {
                    Text("Phase 1 is a local proof of concept. Shields are applied by iOS, but this session is reversible for development. Later versions will add server-backed Commitment and Guardian modes. This build does not claim to be impossible to bypass.")
                        .font(.system(size: 14))
                        .foregroundStyle(LockoutTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button("Continue") {
                session.go(to: .permission)
            }
            .buttonStyle(LockoutPrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
            .accessibilityHint("Continues to Screen Time authorization")
        }
        .background(LockoutTheme.background.ignoresSafeArea())
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppSession.make())
}
