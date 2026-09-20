import FamilyControls
import SwiftUI

struct SelectionTokenList: View {
    let selection: FamilyActivitySelection

    var body: some View {
        LockoutCard {
            if selection.applicationTokens.isEmpty
                && selection.categoryTokens.isEmpty
                && selection.webDomainTokens.isEmpty {
                Text("No opaque tokens are stored right now.")
                    .font(.system(size: 14))
                    .foregroundStyle(LockoutTheme.muted)
            } else {
                if !selection.applicationTokens.isEmpty {
                    section(title: "Applications") {
                        ForEach(Array(selection.applicationTokens), id: \.self) { token in
                            Label(token)
                                .foregroundStyle(LockoutTheme.text)
                        }
                    }
                }
                if !selection.categoryTokens.isEmpty {
                    section(title: "Categories") {
                        ForEach(Array(selection.categoryTokens), id: \.self) { token in
                            Label(token)
                                .foregroundStyle(LockoutTheme.text)
                        }
                    }
                }
                if !selection.webDomainTokens.isEmpty {
                    section(title: "Web domains") {
                        ForEach(Array(selection.webDomainTokens), id: \.self) { token in
                            Label(token)
                                .foregroundStyle(LockoutTheme.text)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(LockoutTheme.muted)
            content()
        }
        .padding(.bottom, 4)
    }
}
