import FamilyControls
import Foundation
import ManagedSettings

struct ShieldSnapshot: Equatable {
    var applicationTokens: Set<ApplicationToken>
    var categoryTokens: Set<ActivityCategoryToken>
    var webDomainCategoryTokens: Set<ActivityCategoryToken>
    var webDomainTokens: Set<WebDomainToken>

    var applicationsApplied: Bool { !applicationTokens.isEmpty }
    var categoriesApplied: Bool { !categoryTokens.isEmpty || !webDomainCategoryTokens.isEmpty }
    var webDomainsApplied: Bool { !webDomainTokens.isEmpty }
    var anyShieldApplied: Bool {
        applicationsApplied || categoriesApplied || webDomainsApplied
    }

    func matches(_ selection: FamilyActivitySelection) -> Bool {
        applicationTokens == selection.applicationTokens
            && categoryTokens == selection.categoryTokens
            && webDomainCategoryTokens == selection.categoryTokens
            && webDomainTokens == selection.webDomainTokens
    }
}
