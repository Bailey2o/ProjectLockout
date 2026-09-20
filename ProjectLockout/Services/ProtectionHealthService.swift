import FamilyControls
import Foundation

@MainActor
final class ProtectionHealthService {
    func evaluate(
        authorization: AuthorizationStatus,
        commitment: LocalCommitment?,
        selection: FamilyActivitySelection,
        snapshot: ShieldSnapshot
    ) -> ProtectionHealth {
        let active = commitment?.status == .active
        let matches = snapshot.matches(selection)
        let requested = RestrictionSelection(selection)
        let health = ProtectionHealth(
            authorization: authorization,
            commitmentActive: active,
            applicationsRequested: !requested.applicationTokens.isEmpty,
            categoriesRequested: !requested.categoryTokens.isEmpty,
            webDomainsRequested: !requested.webDomainTokens.isEmpty,
            applicationsShielded: snapshot.applicationsApplied,
            categoriesShielded: snapshot.categoriesApplied,
            webDomainsShielded: snapshot.webDomainsApplied,
            storeMatchesSelection: matches,
            evaluatedAt: Date()
        )
        LockoutLog.health.info(
            "Health overall=\(String(describing: health.overall), privacy: .public) auth=\(authorization.lockoutTitle, privacy: .public) active=\(active) matches=\(matches) apps=\(snapshot.applicationTokens.count) cats=\(snapshot.categoryTokens.count) web=\(snapshot.webDomainTokens.count)"
        )
        return health
    }
}
