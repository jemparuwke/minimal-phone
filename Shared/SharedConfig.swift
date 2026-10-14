import Foundation

/// Values shared by the app and the widget extension.
enum SharedConfig {
    /// App Group identifier. Injected from build settings (`BUNDLE_ID_PREFIX`) through the
    /// `MinimalAppGroup` key in each target's Info.plist, so it never has to be edited in code.
    static let appGroup: String = Bundle.main.object(forInfoDictionaryKey: "MinimalAppGroup") as? String ?? ""

    /// True when the App Group entitlement really works (the widget can see the app's data).
    static let isAppGroupAvailable: Bool =
        !appGroup.isEmpty && FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) != nil

    /// Custom URL scheme handled by the app (`minimalphone://open/<id>`, `minimalphone://search`).
    static let urlScheme = "minimalphone"

    /// Storage visible to both the app and the widget. Falls back to the app's own defaults
    /// when the App Group is not provisioned (the widget then explains what is wrong).
    static let defaults: UserDefaults = {
        if isAppGroupAvailable, let shared = UserDefaults(suiteName: appGroup) {
            return shared
        }
        return .standard
    }()

    static let launcherDataKey = "launcher.data.v1"

    static let favoritesWidgetKind = "pl.minimal.favorites"
    static let searchWidgetKind = "pl.minimal.search"

    static func openURL(for id: UUID) -> URL {
        URL(string: "\(urlScheme)://open/\(id.uuidString)")!
    }

    static let searchURL = URL(string: "\(urlScheme)://search")!
    static let homeURL = URL(string: "\(urlScheme)://home")!
    static let shieldURL = URL(string: "\(urlScheme)://shield")!
}
