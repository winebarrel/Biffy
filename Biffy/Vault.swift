import Foundation
import Valet

enum Vault {
    static let shared = Valet.valet(with: Identifier(nonEmpty: Bundle.main.bundleIdentifier)!, accessibility: .whenUnlocked)

    static var appPassword: String {
        get {
            do {
                return try shared.string(forKey: "appPassword")
            } catch KeychainError.itemNotFound {
                // Nothing to do
            } catch {
                Logger.shared.error("failed to get appPassword from Valet: \(error)")
            }

            return ""
        }

        set(token) {
            do {
                if token.isEmpty {
                    try shared.removeObject(forKey: "appPassword")
                } else {
                    try shared.setString(token, forKey: "appPassword")
                }
            } catch {
                Logger.shared.error("failed to set appPassword to Valet: \(error)")
            }
        }
    }
}
