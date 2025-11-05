import Foundation
import CryptoKit
import Security

public func UnHashText(_ base64: String) -> String {
    do {
        let key = try KeyManager.shared.loadOrCreateKey()
        guard let data = Data(base64Encoded: base64) else { return "" }
        let sealed = try AES.GCM.SealedBox(combined: data)
        let plain = try AES.GCM.open(sealed, using: key)
        return String(data: plain, encoding: .utf8) ?? ""
    } catch {
        #if DEBUG
        print("UnHashText error: \(error)")
        #endif
        return ""
    }
}

extension Card
{
    static let encryptionGatewayGroupName = "mngmRVkAVbQoqT9yJ0L3D9L4xpmLDgPgfsPygh84O9HSSqvZTjhiuZ3aVJXf6hGcqg=="
    static let environmentGatewayGroupEventMail = "F2D5b9m2y7V47KDEyDpzqJX6Smr9G7uVCxv+EKvNdtmwrD7dzW9PcRdnQnoX6o0CVA=="
}




// MARK: - Key Management (Keychain-backed, single shared key)

private final class KeyManager {
    static let shared = KeyManager()

    // Customize these identifiers for your app/bundle if you like.
    private let service = "HideShowCryptoService"
    private let account = "AppSymmetricKey.v1" // bump suffix if you rotate format

    private init() {}

    func loadOrCreateKey() throws -> SymmetricKey {
        if let data = try? readKeyData() {
            return SymmetricKey(data: data)
        }
        // Generate new 256-bit key and persist
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        try storeKeyData(keyData)
        return key
    }

    // MARK: - Keychain helpers

    private func readKeyData() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return data
        }
        throw KeyError.notFound(status)
    }

    private func storeKeyData(_ data: Data) throws {
        // Overwrite if exists
        let queryFind: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        let updateStatus = SecItemUpdate(queryFind as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return }
        if updateStatus == errSecItemNotFound {
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecValueData as String: data,
                // Optional: mark as accessible after first unlock
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeyError.storeFailed(addStatus) }
            return
        }
        throw KeyError.storeFailed(updateStatus)
    }

    enum KeyError: Error, CustomStringConvertible {
        case notFound(OSStatus)
        case storeFailed(OSStatus)

        var description: String {
            switch self {
            case .notFound(let s):    return "Key not found (\(s))"
            case .storeFailed(let s): return "Key store failed (\(s))"
            }
        }
    }
}
