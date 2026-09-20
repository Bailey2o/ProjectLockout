import SwiftUI

struct HealthCard: View {
    let health: ProtectionHealth

    var body: some View {
        LockoutCard {
            HStack {
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 10, height: 10)
                Text(health.overall.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LockoutTheme.text)
                Spacer()
            }

            healthRow(
                title: "Family Controls authorization",
                detail: health.authorization.lockoutTitle,
                ok: health.authorization == .approved
            )
            healthRow(
                title: "Application shields",
                requested: health.applicationsRequested,
                applied: health.applicationsShielded
            )
            healthRow(
                title: "Category shields",
                requested: health.categoriesRequested,
                applied: health.categoriesShielded
            )
            healthRow(
                title: "Web-domain shields",
                requested: health.webDomainsRequested,
                applied: health.webDomainsShielded
            )
            healthRow(
                title: "Store matches selection",
                detail: health.storeMatchesSelection ? "Yes" : "No",
                ok: health.storeMatchesSelection
            )
        }
    }

    private var indicatorColor: Color {
        switch health.overall {
        case .healthy: return LockoutTheme.healthy
        case .compromised: return LockoutTheme.compromised
        case .inactive: return LockoutTheme.muted
        }
    }

    private func healthRow(title: String, detail: String, ok: Bool) -> some View {
        row(title: title, detail: detail, color: ok ? LockoutTheme.healthy : LockoutTheme.warning)
    }

    @ViewBuilder
    private func healthRow(title: String, requested: Bool, applied: Bool) -> some View {
        if !requested {
            row(title: title, detail: "Not selected", color: LockoutTheme.muted)
        } else {
            row(
                title: title,
                detail: applied ? "Applied" : "Missing",
                color: applied ? LockoutTheme.healthy : LockoutTheme.compromised
            )
        }
    }

    private func row(title: String, detail: String, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(LockoutTheme.text)
            Spacer()
            Text(detail)
                .foregroundStyle(color)
                .fontWeight(.semibold)
        }
        .font(.system(size: 14))
        .padding(.top, 4)
    }
}
