import Foundation
import Security

/// Generic Keychain wrapper. Tokens and local commitment records are stored here
/// rather than in UserDefaults so they are not included in unencrypted backups of app defaults.
final class KeychainService {
    private let service: String

    init(service: String = LockoutIdentity.keychainService) {
        self.service = service
    }

    func setData(_ data: Data, account: String) throws {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let deleteStatus = SecItemDelete(base as CFDictionary)
        if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
            LockoutLog.persistence.error("Keychain delete-before-save failed account=\(account, privacy: .public) status=\(deleteStatus)")
            throw LockoutError.persistenceFailed("Could not replace the existing Keychain item (\(deleteStatus)).")
        }

        var add = base
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(add as CFDictionary, nil)
        guard status == errSecSuccess else {
            LockoutLog.persistence.error("Keychain save failed account=\(account, privacy: .public) status=\(status)")
            throw LockoutError.persistenceFailed("Could not save data to the Keychain (\(status)).")
        }
        LockoutLog.persistence.info("Saved Keychain item account=\(account, privacy: .public) bytes=\(data.count)")
    }

    func data(for account: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = item as? Data else {
            LockoutLog.persistence.error("Keychain read failed account=\(account, privacy: .public) status=\(status)")
            throw LockoutError.persistenceFailed("Could not read Keychain item (\(status)).")
        }
        return data
    }

    func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            LockoutLog.persistence.info("Deleted Keychain item account=\(account, privacy: .public) status=\(status)")
            return
        }
        LockoutLog.persistence.error("Keychain delete failed account=\(account, privacy: .public) status=\(status)")
        throw LockoutError.persistenceFailed("Could not delete Keychain item (\(status)).")
    }
}
