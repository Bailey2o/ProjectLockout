import Foundation

struct LocalCommitment: Codable, Equatable {
    var id: UUID
    var status: LocalCommitmentStatus
    var createdAt: Date
    var activatedAt: Date?
    var endedAt: Date?
    var selectionSummary: SelectionSummary
    var phaseIdentifier: String
    var honestyNote: String

    static func draft(selectionSummary: SelectionSummary) -> LocalCommitment {
        LocalCommitment(
            id: UUID(),
            status: .draft,
            createdAt: Date(),
            activatedAt: nil,
            endedAt: nil,
            selectionSummary: selectionSummary,
            phaseIdentifier: LockoutIdentity.phaseIdentifier,
            honestyNote: LocalCommitment.phase1HonestyNote
        )
    }

    static let phase1HonestyNote = "Phase 1 is a local, reversible development session. It is not server-backed and is not commitment-locked."
}

enum LocalCommitmentStatus: String, Codable, Equatable {
    case draft
    case confirmationPending
    case activating
    case active
    case activationFailed
    case ended
}

struct SelectionSummary: Codable, Equatable {
    var applicationCount: Int
    var categoryCount: Int
    var webDomainCount: Int

    var totalCount: Int {
        applicationCount + categoryCount + webDomainCount
    }

    var isEmpty: Bool {
        totalCount == 0
    }
}
