import SwiftUI

struct LockoutScreen<Content: View>: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(eyebrow.uppercased())
                        .font(.system(size: 12, weight: .semibold, design: .default))
                        .tracking(1.4)
                        .foregroundStyle(LockoutTheme.accent)
                    Text(title)
                        .font(LockoutTheme.titleFont)
                        .foregroundStyle(LockoutTheme.text)
                    Text(subtitle)
                        .font(LockoutTheme.bodyFont)
                        .foregroundStyle(LockoutTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                content
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(LockoutTheme.background.ignoresSafeArea())
    }
}

struct LockoutCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LockoutTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LockoutTheme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct LockoutErrorBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(LockoutTheme.text)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LockoutTheme.compromised.opacity(0.22))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(LockoutTheme.compromised.opacity(0.45), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
