import SwiftUI

enum LockoutTheme {
    static let background = Color(red: 0.055, green: 0.067, blue: 0.086)
    static let surface = Color(red: 0.090, green: 0.106, blue: 0.133)
    static let surfaceElevated = Color(red: 0.118, green: 0.137, blue: 0.172)
    static let text = Color(red: 0.957, green: 0.945, blue: 0.918)
    static let muted = Color(red: 0.604, green: 0.639, blue: 0.698)
    static let accent = Color(red: 0.788, green: 0.635, blue: 0.153)
    static let accentSoft = Color(red: 0.788, green: 0.635, blue: 0.153).opacity(0.16)
    static let healthy = Color(red: 0.239, green: 0.604, blue: 0.416)
    static let warning = Color(red: 0.816, green: 0.541, blue: 0.180)
    static let compromised = Color(red: 0.769, green: 0.361, blue: 0.361)
    static let stroke = Color.white.opacity(0.08)

    static let wordmarkFont = Font.system(size: 34, weight: .semibold, design: .serif)
    static let titleFont = Font.system(size: 28, weight: .semibold, design: .default)
    static let bodyFont = Font.system(size: 16, weight: .regular, design: .default)
}

struct LockoutPrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(enabled ? LockoutTheme.background : LockoutTheme.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(enabled ? LockoutTheme.accent : LockoutTheme.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct LockoutSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(LockoutTheme.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(LockoutTheme.surfaceElevated)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(LockoutTheme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
