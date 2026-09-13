import Flutter
import Foundation

/// iOS implementation of the dev.zuraffa/agent_platform channel
/// (spec 115): Application Support home + Keychain secure store.
public class ZuraffaAgentPlugin: NSObject, FlutterPlugin {
  private static let channelName = "dev.zuraffa/agent_platform"
  private static let service = "dev.zuraffa.zuraffa_agent"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: ZuraffaAgentPlugin.channelName, binaryMessenger: registrar.messenger())
    let instance = ZuraffaAgentPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getAgentHome": agentHome(result)
    case "secureRead": secureRead(call, result: result)
    case "secureWrite": secureWrite(call, result: result)
    case "secureDelete": secureDelete(call, result: result)
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func agentHome(_ result: @escaping FlutterResult) {
    guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
      result(FlutterError(code: "unavailable", message: "no application support directory", details: nil))
      return
    }
    let home = base.appendingPathComponent("zuraffa_agent", isDirectory: true)
    do {
      try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
    } catch {
      result(FlutterError(code: "unavailable", message: "home creation failed: \(error)", details: nil))
      return
    }
    result(home.path)
  }

  private func secureWrite(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let key = key(of: call), let value = call.arguments?["value"] as? String else {
      result(FlutterError(code: "badArgs", message: "missing key or value", details: nil))
      return
    }
    let data = value.data(using: .utf8)!
    let query: [String: Any] = baseQuery(key: key)
    SecItemDelete(query as CFDictionary)
    var attributes = query
    attributes[kSecValueData as String] = data
    attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
    let status = SecItemAdd(attributes as CFDictionary, nil)
    if status == errSecSuccess { result(nil) } else { result(flutterError(status)) }
  }

  private func secureRead(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let key = key(of: call) else {
      result(FlutterError(code: "badArgs", message: "missing key", details: nil))
      return
    }
    var query = baseQuery(key: key)
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecSuccess, let data = item as? Data,
       let value = String(data: data, encoding: .utf8) {
      result(value)
    } else if status == errSecItemNotFound {
      result(nil)
    } else {
      result(flutterError(status))
    }
  }

  private func secureDelete(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let key = key(of: call) else {
      result(FlutterError(code: "badArgs", message: "missing key", details: nil))
      return
    }
    let status = SecItemDelete(baseQuery(key: key) as CFDictionary)
    if status == errSecSuccess || status == errSecItemNotFound { result(nil) } else { result(flutterError(status)) }
  }

  private func key(of call: FlutterMethodCall) -> String? {
    let args = call.arguments as? [String: Any]
    let key = args?["key"] as? String
    guard let key, !key.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
    return key
  }

  private func flutterError(_ status: OSStatus) -> FlutterError {
    FlutterError(code: "secureStoreFailure", message: "keychain status \(status)", details: nil)
  }

  private func baseQuery(key: String) -> [String: Any] {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: ZuraffaAgentPlugin.service,
      kSecAttrAccount as String: key,
    ]
    // Data-protection keychain (iOS); harmless on macOS 10.15+.
    query[kSecUseDataProtectionKeychain as String] = true
    return query
  }
}
