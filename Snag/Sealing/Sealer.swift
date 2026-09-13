// The seal: SHA-256 over the canonical bytes, signed with a P-256 key that
// never leaves the phone. In the Secure Enclave when the hardware has one;
// a software key kept in the Keychain when it does not — the simulator, and
// nothing else this app supports. The bundle carries the public key, so a
// verifier needs neither the phone nor the app.
//
// No biometric on the key: the landlord signs on the tenant's phone, and a
// key that demanded the tenant's face at that moment is exactly wrong.
import CryptoKit
import Foundation
import SnagDomain

enum SealError: Error { case noKey, keychain(OSStatus) }

struct Seal: Sendable, Equatable {
    let digest: [UInt8]      // SHA-256 of the canonical bytes
    let signature: [UInt8]   // P-256 ECDSA, DER
    let publicKey: [UInt8]   // X9.63
    /// The report id: the hex of the digest of its first canonical encoding.
    var id: String { digest.map { String(format: "%02x", $0) }.joined() }
}

@MainActor
final class Sealer {
    private enum Key {
        case enclave(SecureEnclave.P256.Signing.PrivateKey)
        case software(P256.Signing.PrivateKey)
    }
    private let key: Key
    static let keychainAccount = "ng.snag.sealing-key"

    init() throws {
        key = try Self.loadOrMake()
    }

    var usesSecureEnclave: Bool { if case .enclave = key { true } else { false } }

    var publicKey: [UInt8] {
        switch key {
        case .enclave(let k): Array(k.publicKey.x963Representation)
        case .software(let k): Array(k.publicKey.x963Representation)
        }
    }

    func seal(_ canonical: [UInt8]) throws -> Seal {
        let digest = SHA256.hash(data: Data(canonical))
        let sig: Data
        switch key {
        case .enclave(let k): sig = try k.signature(for: digest).derRepresentation
        case .software(let k): sig = try k.signature(for: digest).derRepresentation
        }
        return Seal(digest: Array(digest), signature: Array(sig), publicKey: publicKey)
    }

    // MARK: key storage

    private static func loadOrMake() throws -> Key {
        if let stored = try load() {
            if SecureEnclave.isAvailable, let k = try? SecureEnclave.P256.Signing.PrivateKey(dataRepresentation: stored) { return .enclave(k) }
            if let k = try? P256.Signing.PrivateKey(rawRepresentation: stored) { return .software(k) }
        }
        if SecureEnclave.isAvailable {
            let k = try SecureEnclave.P256.Signing.PrivateKey(accessControl: SecAccessControlCreateWithFlags(
                nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, [.privateKeyUsage], nil)!)
            try store(k.dataRepresentation)
            return .enclave(k)
        }
        let k = P256.Signing.PrivateKey()
        try store(k.rawRepresentation)
        return .software(k)
    }

    private static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "ng.snag", kSecAttrAccount as String: keychainAccount]
    }

    private static func load() throws -> Data? {
        var q = query; q[kSecReturnData as String] = true; q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &out)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw SealError.keychain(status) }
        return out as? Data
    }

    private static func store(_ data: Data) throws {
        var q = query
        q[kSecValueData as String] = data
        q[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let status = SecItemAdd(q as CFDictionary, nil)
        guard status == errSecSuccess || status == errSecDuplicateItem else { throw SealError.keychain(status) }
    }

    /// For tests: forget the key so the next Sealer makes a fresh one.
    static func reset() { SecItemDelete(query as CFDictionary) }
}
