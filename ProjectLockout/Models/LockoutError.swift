import Foundation

enum LockoutError: LocalizedError, Equatable {
    case authorizationNotApproved
    case authorizationFailed(String)
    case emptySelection
    case persistenceFailed(String)
    case shieldVerificationFailed
    case commitmentMissing
    case selectionLimitExceeded(kind: String, count: Int, limit: Int)

    var errorDescription: String? {
        switch self {
        case .authorizationNotApproved:
            return "Family Controls is not approved. Lockout cannot apply shields without Screen Time authorization."
        case .authorizationFailed(let message):
            return message
        case .emptySelection:
            return "Select at least one app, category, or website before continuing."
        case .persistenceFailed(let message):
            return message
        case .shieldVerificationFailed:
            return "iOS did not report the expected shields after activation. Nothing was marked active."
        case .commitmentMissing:
            return "No local Phase 1 session was found."
        case .selectionLimitExceeded(let kind, let count, let limit):
            return "Apple allows at most \(limit) shielded \(kind) at once. This selection has \(count)."
        }
    }
}
