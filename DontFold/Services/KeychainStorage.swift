import Foundation
import Security

/// Tiny Keychain wrapper for storing small string values that should survive
/// app delete + reinstall (e.g. the canonical user ID, the purchase log).
/// Uses generic-password class, keyed by a service-scoped account string.
enum KeychainStorage {
    private static let service = "com.dontfold.app"

    static func set(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        // Delete any existing item first — SecItemUpdate is fussier than just replacing.
        SecItemDelete(query(forKey: key) as CFDictionary)
        var attributes = query(forKey: key)
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func get(forKey key: String) -> String? {
        var q = query(forKey: key)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(forKey key: String) {
        SecItemDelete(query(forKey: key) as CFDictionary)
    }

    private static func query(forKey key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }
}
