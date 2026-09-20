import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Customizes the system shield that iOS presents over shielded apps and sites.
///
/// Shields still appear if this extension is missing — the system then uses its default
/// appearance. This target exists so Phase 1 shows Lockout-branded copy instead of a
/// generic Screen Time shield. It is not required for `ManagedSettingsStore` enforcement.
///
/// Device Activity Monitor is intentionally omitted: Phase 1 applies shields immediately
/// from the app. A monitor extension is only needed for schedule-based DeviceActivity events.
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        lockoutConfiguration(subtitle: "You chose to keep this app unavailable.")
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        lockoutConfiguration(subtitle: "You chose to keep this category unavailable.")
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        lockoutConfiguration(subtitle: "You chose to keep this site unavailable.")
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        lockoutConfiguration(subtitle: "You chose to keep this category of sites unavailable.")
    }

    private func lockoutConfiguration(subtitle: String) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor(red: 0.055, green: 0.067, blue: 0.086, alpha: 1),
            icon: UIImage(systemName: "lock.square"),
            title: ShieldConfiguration.Label(text: "Lockout", color: UIColor(red: 0.957, green: 0.945, blue: 0.918, alpha: 1)),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: UIColor(red: 0.604, green: 0.639, blue: 0.698, alpha: 1)),
            primaryButtonLabel: ShieldConfiguration.Label(text: "OK", color: UIColor(red: 0.055, green: 0.067, blue: 0.086, alpha: 1)),
            primaryButtonBackgroundColor: UIColor(red: 0.788, green: 0.635, blue: 0.153, alpha: 1),
            secondaryButtonLabel: nil
        )
    }
}
