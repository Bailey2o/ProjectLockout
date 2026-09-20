import FamilyControls
import Foundation

struct ProtectionHealth: Equatable {
    var authorization: AuthorizationStatus
    var commitmentActive: Bool
    var applicationsRequested: Bool
    var categoriesRequested: Bool
    var webDomainsRequested: Bool
    var applicationsShielded: Bool
    var categoriesShielded: Bool
    var webDomainsShielded: Bool
    var storeMatchesSelection: Bool
    var evaluatedAt: Date

    static let unknown = ProtectionHealth(
        authorization: .notDetermined,
        commitmentActive: false,
        applicationsRequested: false,
        categoriesRequested: false,
        webDomainsRequested: false,
        applicationsShielded: false,
        categoriesShielded: false,
        webDomainsShielded: false,
        storeMatchesSelection: false,
        evaluatedAt: Date.distantPast
    )

    var overall: Overall {
        guard commitmentActive else { return .inactive }
        if authorization != .approved || !storeMatchesSelection {
            return .compromised
        }
        return .healthy
    }

    enum Overall: Equatable {
        case inactive
        case healthy
        case compromised

        var title: String {
            switch self {
            case .inactive: return "Inactive"
            case .healthy: return "Shields applied"
            case .compromised: return "Protection interrupted"
            }
        }
    }
}

extension AuthorizationStatus {
    var lockoutTitle: String {
        switch self {
        case .notDetermined: return "Not determined"
        case .denied: return "Denied"
        case .approved: return "Approved"
        @unknown default: return "Unknown"
        }
    }
}
