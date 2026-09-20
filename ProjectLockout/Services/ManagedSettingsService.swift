import FamilyControls
import Foundation
import ManagedSettings

/// Applies and inspects Managed Settings shields. Views must not touch `ManagedSettingsStore`.
final class ManagedSettingsService {
    private let store: ManagedSettingsStore

    /// Construct `ManagedSettingsStore` in the initializer body, not a default
    /// argument, so store creation stays off of nonisolated default-arg evaluation.
    init() {
        self.store = ManagedSettingsStore()
    }

    init(store: ManagedSettingsStore) {
        self.store = store
    }

    func applyShields(for selection: FamilyActivitySelection) throws {
        let restriction = RestrictionSelection(selection)
        try Self.validateLimits(restriction)

        let applications = restriction.applicationTokens
        let categories = restriction.categoryTokens
        let webDomains = restriction.webDomainTokens

        store.shield.applications = applications.isEmpty ? nil : applications
        store.shield.applicationCategories = categories.isEmpty ? nil : .specific(categories)
        store.shield.webDomainCategories = categories.isEmpty ? nil : .specific(categories)
        store.shield.webDomains = webDomains.isEmpty ? nil : webDomains

        LockoutLog.settings.info(
            "Applied shields applications=\(applications.count) categories=\(categories.count) webDomains=\(webDomains.count)"
        )
    }

    func clearShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomainCategories = nil
        store.shield.webDomains = nil
        LockoutLog.settings.info("Cleared application, category, and web-domain shields on the default ManagedSettingsStore")
    }

    func snapshot() -> ShieldSnapshot {
        let applications = store.shield.applications ?? []
        let webDomains = store.shield.webDomains ?? []
        return ShieldSnapshot(
            applicationTokens: applications,
            categoryTokens: Self.specificCategories(store.shield.applicationCategories),
            webDomainCategoryTokens: Self.specificCategories(store.shield.webDomainCategories),
            webDomainTokens: webDomains
        )
    }

    private static func specificCategories<T>(
        _ policy: ShieldSettings.ActivityCategoryPolicy<T>?
    ) -> Set<ActivityCategoryToken> {
        if case let .specific(tokens, _) = policy {
            return tokens
        }
        return []
    }

    private static func validateLimits(_ restriction: RestrictionSelection) throws {
        if restriction.applicationTokens.count > ManagedSettingsLimits.applications {
            throw LockoutError.selectionLimitExceeded(
                kind: "applications",
                count: restriction.applicationTokens.count,
                limit: ManagedSettingsLimits.applications
            )
        }
        if restriction.categoryTokens.count > ManagedSettingsLimits.categories {
            throw LockoutError.selectionLimitExceeded(
                kind: "categories",
                count: restriction.categoryTokens.count,
                limit: ManagedSettingsLimits.categories
            )
        }
        if restriction.webDomainTokens.count > ManagedSettingsLimits.webDomains {
            throw LockoutError.selectionLimitExceeded(
                kind: "web domains",
                count: restriction.webDomainTokens.count,
                limit: ManagedSettingsLimits.webDomains
            )
        }
    }
}
