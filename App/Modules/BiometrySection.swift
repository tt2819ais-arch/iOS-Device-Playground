import SwiftUI
import LocalAuthentication
import CryptoKit
import Security

@MainActor
final class BiometryModel: ObservableObject {
    @Published var faceOn = false
    @Published var keychainOn = false
    @Published var cryptoOn = false

    @Published var authStatus: String = "—"
    @Published var keychainValue: String = ""
    @Published var savedValue: String = ""
    @Published var plain: String = "Привет / Hello"
    @Published var encrypted: String = ""
    @Published var decrypted: String = ""

    private let keychainAccount = "DevicePlayground.sample"
    private let keychainService = "com.tt2819ais.deviceplayground"
    private let symKey = SymmetricKey(size: .bits256)

    func authenticate() {
        let ctx = LAContext()
        var err: NSError?
        let policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
        guard ctx.canEvaluatePolicy(policy, error: &err) else {
            authStatus = err?.localizedDescription ?? "unavailable"
            return
        }
        ctx.evaluatePolicy(policy, localizedReason: "Authenticate to test biometry") { ok, error in
            DispatchQueue.main.async {
                self.authStatus = ok ? "OK" : (error?.localizedDescription ?? "failed")
            }
        }
    }

    func saveSecret() {
        guard let data = keychainValue.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount,
            kSecAttrService as String: keychainService
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        SecItemAdd(add as CFDictionary, nil)
    }
    func loadSecret() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount,
            kSecAttrService as String: keychainService,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data, let s = String(data: data, encoding: .utf8) {
            savedValue = s
        } else {
            savedValue = "—"
        }
    }
    func deleteSecret() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount,
            kSecAttrService as String: keychainService
        ]
        SecItemDelete(query as CFDictionary)
        savedValue = ""
    }

    func encrypt() {
        guard let data = plain.data(using: .utf8) else { return }
        if let sealed = try? AES.GCM.seal(data, using: symKey),
           let combined = sealed.combined {
            encrypted = combined.base64EncodedString()
        }
    }
    func decrypt() {
        guard let data = Data(base64Encoded: encrypted) else { return }
        if let box = try? AES.GCM.SealedBox(combined: data),
           let opened = try? AES.GCM.open(box, using: symKey),
           let s = String(data: opened, encoding: .utf8) {
            decrypted = s
        }
    }
}

struct BiometrySection: View {
    @StateObject private var m = BiometryModel()

    var body: some View {
        VStack(spacing: 16) {
            FeatureCard(titleKey: "bio_faceid", symbol: "faceid", tint: .mint, isOn: $m.faceOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("bio_faceid_desc").font(.callout).foregroundStyle(.secondary)
                    ActionButton(titleKey: "bio_authenticate", systemImage: "faceid", tint: .mint) {
                        m.authenticate()
                    }
                    Text(m.authStatus).font(.caption.monospaced()).foregroundStyle(.secondary)
                }
            }
            FeatureCard(titleKey: "bio_keychain", symbol: "key.fill", tint: .mint, isOn: $m.keychainOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("bio_keychain_desc").font(.callout).foregroundStyle(.secondary)
                    TextField("secret", text: $m.keychainValue).textFieldStyle(.roundedBorder)
                    HStack {
                        ActionButton(titleKey: "bio_save", systemImage: "tray.and.arrow.down.fill", tint: .mint) { m.saveSecret() }
                        ActionButton(titleKey: "bio_load", systemImage: "tray.and.arrow.up.fill", tint: .mint) { m.loadSecret() }
                        ActionButton(titleKey: "bio_delete", systemImage: "trash.fill", tint: .red) { m.deleteSecret() }
                    }
                    if !m.savedValue.isEmpty { Text(m.savedValue).font(.caption.monospaced()).textSelection(.enabled) }
                }
            }
            FeatureCard(titleKey: "bio_crypto", symbol: "lock.shield.fill", tint: .mint, isOn: $m.cryptoOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("bio_crypto_desc").font(.callout).foregroundStyle(.secondary)
                    TextField("plain", text: $m.plain).textFieldStyle(.roundedBorder)
                    HStack {
                        ActionButton(titleKey: "bio_encrypt", systemImage: "lock.fill", tint: .mint) { m.encrypt() }
                        ActionButton(titleKey: "bio_decrypt", systemImage: "lock.open.fill", tint: .mint) { m.decrypt() }
                    }
                    if !m.encrypted.isEmpty {
                        Text(m.encrypted).font(.caption.monospaced()).lineLimit(3).textSelection(.enabled)
                    }
                    if !m.decrypted.isEmpty {
                        Text(m.decrypted).font(.callout).foregroundStyle(.green)
                    }
                }
            }
        }
    }
}
