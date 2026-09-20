import FamilyControls
import Foundation
import ManagedSettings

struct RestrictionSelection: Equatable {
    var familyActivitySelection: FamilyActivitySelection

    init(_ familyActivitySelection: FamilyActivitySelection = FamilyActivitySelection()) {
        self.familyActivitySelection = familyActivitySelection
    }

    var applicationTokens: Set<ApplicationToken> {
        familyActivitySelection.applicationTokens
    }

    var categoryTokens: Set<ActivityCategoryToken> {
        familyActivitySelection.categoryTokens
    }

    var webDomainTokens: Set<WebDomainToken> {
        familyActivitySelection.webDomainTokens
    }

    var summary: SelectionSummary {
        SelectionSummary(
            applicationCount: applicationTokens.count,
            categoryCount: categoryTokens.count,
            webDomainCount: webDomainTokens.count
        )
    }

    var isEmpty: Bool {
        summary.isEmpty
    }
}

enum ManagedSettingsLimits {
    static let applications = 50
    static let categories = 50
    static let webDomains = 50
}
