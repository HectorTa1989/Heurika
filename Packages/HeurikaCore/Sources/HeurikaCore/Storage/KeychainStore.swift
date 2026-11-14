import Foundation
import Security

/// Thin wrapper around the Security framework for storing provider API keys
/// and the Notion integration token. Uses the shared Keychain access group so
/// both the Heurika app and the HeurikaKeyboard extension read the same
/// values — this is what lets the extension use a key the person typed into
/// the app's Settings screen without any network round trip.
///
/// Deliberately NOT using App Group `UserDefaults` for secrets: UserDefaults
/// is unencrypted plist storage, fine for settings, wrong for API keys.
public final class KeychainStore: @unchecked Sendable {
    public static let shared = KeychainStore()
    private init() {}

    private enum Key {
        static func apiKey(_ provider: AIProviderType) -> String { "apikey.\(provider.rawValue)" }
        static let notionToken = "notion.integration_token"
    }

    // MARK: - Provider API keys

    public func apiKey(for provider: AIProviderType) -> String? {
        read(account: Key.apiKey(provider))
    }

    @discardableResult
    public func setAPIKey(_ value: String?, for provider: AIProviderType) -> Bool {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return delete(account: Key.apiKey(provider))
        }
        return write(value, account: Key.apiKey(provider))
    }

    // MARK: - Notion token

    public func notionToken() -> String? {
        read(account: Key.notionToken)
    }

    @discardableResult
    public func setNotionToken(_ value: String?) -> Bool {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return delete(account: Key.notionToken)
        }
        return write(value, account: Key.notionToken)
    }

    // MARK: - Core Security-framework calls

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.hectorta1989.heurika",
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: HeurikaConstants.keychainAccessGroup
        ]
    }

    private func read(account: String) -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    private func write(_ value: String, account: String) -> Bool {
        let data = Data(value.utf8)
        let existingQuery = baseQuery(account: account)

        var checkStatus: OSStatus = errSecSuccess
        var checkResult: AnyObject?
        checkStatus = SecItemCopyMatching(existingQuery as CFDictionary, &checkResult)

        if checkStatus == errSecSuccess {
            let attributesToUpdate: [String: Any] = [kSecValueData as String: data]
            let status = SecItemUpdate(existingQuery as CFDictionary, attributesToUpdate as CFDictionary)
            return status == errSecSuccess
        } else {
            var addQuery = baseQuery(account: account)
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let status = SecItemAdd(addQuery as CFDictionary, nil)
            return status == errSecSuccess
        }
    }

    @discardableResult
    private func delete(account: String) -> Bool {
        let query = baseQuery(account: account)
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
