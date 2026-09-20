import FamilyControls
import Foundation

/// Persists opaque Family Controls tokens. Apple voids tokens if authorization is revoked.
final class SelectionPersistenceService {
    static let account = "family-activity-selection"

    private let keychain: KeychainService
    private let encoder = PropertyListEncoder()
    private let decoder = PropertyListDecoder()

    init(keychain: KeychainService) {
        self.keychain = keychain
        encoder.outputFormat = .binary
    }

    func save(_ selection: FamilyActivitySelection) throws {
        let data: Data
        do {
            data = try encoder.encode(selection)
        } catch {
            LockoutLog.persistence.error("Failed to encode FamilyActivitySelection: \(error.localizedDescription, privacy: .public)")
            throw LockoutError.persistenceFailed("Could not encode the selected tokens.")
        }
        try keychain.setData(data, account: Self.account)
        let summary = RestrictionSelection(selection).summary
        LockoutLog.persistence.info(
            "Persisted selection apps=\(summary.applicationCount) categories=\(summary.categoryCount) web=\(summary.webDomainCount)"
        )
    }

    func load() throws -> FamilyActivitySelection? {
        guard let data = try keychain.data(for: Self.account) else {
            return nil
        }
        do {
            let selection = try decoder.decode(FamilyActivitySelection.self, from: data)
            let summary = RestrictionSelection(selection).summary
            LockoutLog.persistence.info(
                "Loaded selection apps=\(summary.applicationCount) categories=\(summary.categoryCount) web=\(summary.webDomainCount)"
            )
            return selection
        } catch {
            LockoutLog.persistence.error("Failed to decode FamilyActivitySelection: \(error.localizedDescription, privacy: .public)")
            throw LockoutError.persistenceFailed("Could not decode the stored tokens. They may have been voided after authorization changed.")
        }
    }

    func clear() throws {
        try keychain.delete(account: Self.account)
    }
}
