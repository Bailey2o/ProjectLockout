import FamilyControls
import SwiftUI

struct SelectionView: View {
    @EnvironmentObject private var session: AppSession
    @State private var isPickerPresented = false
    @State private var localError: String?

    var body: some View {
        LockoutScreen(
            eyebrow: "Selection",
            title: "What should be harder to open?",
            subtitle: "Use Apple’s Family Activity picker to choose apps, categories, and web domains. Lockout stores opaque tokens — not names, URLs, or history."
        ) {
            VStack(alignment: .leading, spacing: 16) {
                if let message = session.bannerError ?? localError {
                    LockoutErrorBanner(message: message)
                }

                HStack(spacing: 10) {
                    countChip(title: "Apps", count: session.restriction.applicationTokens.count)
                    countChip(title: "Categories", count: session.restriction.categoryTokens.count)
                    countChip(title: "Websites", count: session.restriction.webDomainTokens.count)
                }

                Button("Choose apps & websites") {
                    isPickerPresented = true
                }
                .buttonStyle(LockoutPrimaryButtonStyle())
                .familyActivityPicker(
                    headerText: "Choose apps, categories, and websites",
                    footerText: "Lockout receives opaque tokens only. It does not receive browsing history.",
                    isPresented: $isPickerPresented,
                    selection: $session.selection
                )
                .onChange(of: session.selection) { _ in
                    localError = nil
                    session.persistDraftSelection()
                }

                if session.restriction.isEmpty {
                    LockoutCard {
                        Text("Nothing is selected yet. You can pick specific apps, App Store categories, and web domains.")
                            .font(.system(size: 14))
                            .foregroundStyle(LockoutTheme.muted)
                    }
                } else {
                    SelectionTokenList(selection: session.selection)
                }

                if session.restriction.applicationTokens.count > ManagedSettingsLimits.applications
                    || session.restriction.categoryTokens.count > ManagedSettingsLimits.categories
                    || session.restriction.webDomainTokens.count > ManagedSettingsLimits.webDomains {
                    LockoutErrorBanner(
                        message: "Apple limits shields to \(ManagedSettingsLimits.applications) apps, \(ManagedSettingsLimits.categories) categories, and \(ManagedSettingsLimits.webDomains) web domains at a time. Reduce the selection before activating."
                    )
                }

                Button("Continue") {
                    do {
                        try session.prepareConfirmation()
                    } catch {
                        localError = error.localizedDescription
                    }
                }
                .buttonStyle(LockoutPrimaryButtonStyle(enabled: !session.restriction.isEmpty))
                .disabled(session.restriction.isEmpty)

                Button("Back") {
                    session.go(to: .permission)
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(LockoutTheme.muted)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func countChip(title: String, count: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(LockoutTheme.text)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(LockoutTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(LockoutTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(LockoutTheme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
