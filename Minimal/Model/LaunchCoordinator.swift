import SwiftUI
import UIKit
import WidgetKit

/// Routes taps, widget links and the mindful pause, and owns which sheet is on screen.
@MainActor
final class LaunchCoordinator: ObservableObject {
    enum Sheet: Identifiable {
        case settings
        case shield
        case newItem(prefill: String)
        case editItem(LaunchItem)
        case favorites
        case catalog

        var id: String {
            switch self {
            case .settings: return "settings"
            case .shield: return "shield"
            case .newItem(let prefill): return "new-\(prefill)"
            case .editItem(let item): return "edit-\(item.id)"
            case .favorites: return "favorites"
            case .catalog: return "catalog"
            }
        }
    }

    @Published var sheet: Sheet?
    @Published var isSearching = false
    @Published var pausing: LaunchItem?
    @Published var failedItem: LaunchItem?

    private let store: LauncherStore
    private let stats: UsageStats
    private var isActive = false
    private var pendingItem: LaunchItem?
    /// iOS 26 can deliver one widget tap twice; ignore repeats within a second.
    private var lastDeepLink: (url: URL, at: Date)?

    /// The live coordinator, for App Intents running in the app's process.
    static weak var current: LaunchCoordinator?

    init(store: LauncherStore, stats: UsageStats) {
        self.store = store
        self.stats = stats
        Self.current = self
    }

    // MARK: - Launching

    /// Entry point for every tap on an item.
    func launch(_ item: LaunchItem) {
        if item.mindful {
            sheet = nil
            pausing = item
        } else {
            open(item)
        }
    }

    /// Opens the item right away (after the pause, or for items without one).
    func open(_ item: LaunchItem) {
        pausing = nil
        guard !candidateURLs(for: item).isEmpty else {
            failedItem = item
            return
        }
        Haptics.tap()
        stats.recordOpen(item)
        guard isActive else {
            pendingItem = item
            return
        }
        openExternal(item)
    }

    /// "Try it" from the editor: open without counting it as a real launch.
    /// Returns whether anything opened, so the editor can show its own error.
    func tryOpen(_ item: LaunchItem) async -> Bool {
        for url in candidateURLs(for: item) {
            let isWeb = ["http", "https"].contains(url.scheme?.lowercased() ?? "")
            let options: [UIApplication.OpenExternalURLOptionsKey: Any] =
                isWeb && item.catalogID != nil ? [.universalLinksOnly: true] : [:]
            if await UIApplication.shared.open(url, options: options) { return true }
        }
        return false
    }

    func resist() {
        Haptics.success()
        stats.recordResisted()
        pausing = nil
    }

    /// Opens a URL that is not a launcher item (web search, Settings…).
    func openURL(_ url: URL) {
        Task { _ = await UIApplication.shared.open(url) }
    }

    /// Catalog items use the catalog's current URL list (so fixes ship with app updates);
    /// anything the user typed is used as is.
    private func candidateURLs(for item: LaunchItem) -> [URL] {
        if let app = AppCatalog.app(id: item.catalogID) {
            return app.urls.compactMap(URL.init(string:))
        }
        return item.url.map { [$0] } ?? []
    }

    /// Tries each candidate in turn. Universal links of catalog apps are opened only in
    /// their app, never in the browser, so a missing app fails cleanly and we move on.
    private func openExternal(_ item: LaunchItem) {
        let candidates = candidateURLs(for: item)
        let isCatalogApp = item.catalogID != nil
        Task {
            for url in candidates {
                let isWeb = ["http", "https"].contains(url.scheme?.lowercased() ?? "")
                let options: [UIApplication.OpenExternalURLOptionsKey: Any] =
                    isWeb && isCatalogApp ? [.universalLinksOnly: true] : [:]
                if await UIApplication.shared.open(url, options: options) {
                    isSearching = false
                    return
                }
            }
            failedItem = item
        }
    }

    // MARK: - Deep links (widget)

    /// Deep links (widgets, Shortcuts, Action Button):
    /// `minimalphone://open/<uuid or catalog id>`, `minimalphone://search`, `minimalphone://shield`,
    /// `minimalphone://settings`, `minimalphone://home`.
    func handle(_ url: URL) {
        guard url.scheme?.lowercased() == SharedConfig.urlScheme else { return }
        // Nothing can be presented over the welcome screens; ignore links until setup is done.
        guard UserDefaults.standard.bool(forKey: Pref.onboarded) else { return }
        if let last = lastDeepLink, last.url == url, Date().timeIntervalSince(last.at) < 1 { return }
        lastDeepLink = (url, Date())
        switch url.host?.lowercased() {
        case "open":
            let key = url.lastPathComponent
            let item = UUID(uuidString: key).flatMap(store.item(id:)) ?? store.item(forCatalogID: key)
            guard let item else { return }
            sheet = nil
            launch(item)
        case "search":
            sheet = nil
            pausing = nil
            isSearching = true
        case "shield":
            pausing = nil
            sheet = .shield
        case "settings":
            pausing = nil
            sheet = .settings
        #if DEBUG
        case "debug-pause":
            // Used by CI to capture the pause screen.
            guard let item = store.favorites.first else { return }
            sheet = nil
            pausing = item
        #endif
        default:
            sheet = nil
            isSearching = false
        }
    }

    // MARK: - Scene

    func scenePhaseChanged(_ phase: ScenePhase) {
        switch phase {
        case .active:
            isActive = true
            // Cheap while in the foreground; keeps the widget in sync after installs and edits.
            WidgetCenter.shared.reloadTimelines(ofKind: SharedConfig.favoritesWidgetKind)
            if let item = pendingItem {
                pendingItem = nil
                // Opening another app while the scene is still settling can be dropped.
                Task {
                    try? await Task.sleep(for: .milliseconds(250))
                    openExternal(item)
                }
            }
        case .background:
            isActive = false
            // An app that was about to open should not pop up hours later.
            pendingItem = nil
            // Coming back should always land on a calm home screen.
            isSearching = false
            pausing = nil
        default:
            isActive = false
        }
    }
}
