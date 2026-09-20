import Foundation

/// Boundary for later server-backed commitments (Phase 2).
/// Phase 1 stores a local record only. The server must become authoritative before
/// any product copy claims that unlock is delayed or guardian-gated.
@MainActor
protocol CommitmentServicing: AnyObject {
    func load() throws -> LocalCommitment?
    func save(_ commitment: LocalCommitment) throws
    func clear() throws
}

/// Local Keychain record used by Phase 1. Replace this type in Phase 2 with a
/// network client that never lets the device mark a strict commitment ended.
final class LocalCommitmentService: CommitmentServicing {
    static let account = "local-commitment"

    private let keychain: KeychainService
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(keychain: KeychainService) {
        self.keychain = keychain
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
    }

    func load() throws -> LocalCommitment? {
        guard let data = try keychain.data(for: Self.account) else {
            return nil
        }
        do {
            let commitment = try decoder.decode(LocalCommitment.self, from: data)
            LockoutLog.commitment.info(
                "Loaded local commitment id=\(commitment.id.uuidString, privacy: .public) status=\(commitment.status.rawValue, privacy: .public)"
            )
            return commitment
        } catch {
            LockoutLog.commitment.error("Failed to decode local commitment: \(error.localizedDescription, privacy: .public)")
            throw LockoutError.persistenceFailed("Could not decode the local commitment record.")
        }
    }

    func save(_ commitment: LocalCommitment) throws {
        let data: Data
        do {
            data = try encoder.encode(commitment)
        } catch {
            LockoutLog.commitment.error("Failed to encode local commitment: \(error.localizedDescription, privacy: .public)")
            throw LockoutError.persistenceFailed("Could not encode the local commitment record.")
        }
        try keychain.setData(data, account: Self.account)
        LockoutLog.commitment.info(
            "Saved local commitment id=\(commitment.id.uuidString, privacy: .public) status=\(commitment.status.rawValue, privacy: .public)"
        )
    }

    func clear() throws {
        try keychain.delete(account: Self.account)
        LockoutLog.commitment.info("Cleared local commitment record")
    }
}
