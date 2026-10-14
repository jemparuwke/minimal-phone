import SwiftUI
import UIKit

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
    private var pendingURL: URL?
    private var pendingItem: LaunchItem?

    init(store: LauncherStore, stats: UsageStats) {
        self.store = store
        self.stats = stats
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
        guard let url = item.url else {
            failedItem = item
            return
        }
        if UserDefaults.standard.object(forKey: Pref.haptics) as? Bool ?? true {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        stats.recordOpen(item)
        guard isActive else {
            pendingURL = url
            pendingItem = item
            return
        }
        openExternal(url, for: item)
    }

    func resist() {
        stats.recordResisted()
        pausing = nil
    }

    /// Opens a URL that is not a launcher item (web search, Settings…).
    func openURL(_ url: URL) {
        Task { _ = await UIApplication.shared.open(url) }
    }

    private func openExternal(_ url: URL, for item: LaunchItem) {
        Task {
            let opened = await UIApplication.shared.open(url)
            if opened {
                isSearching = false
            } else {
                failedItem = item
            }
        }
    }

    // MARK: - Deep links (widget)

    /// Deep links (widgets, Shortcuts, Action Button):
    /// `minimal://open/<uuid or catalog id>`, `minimal://search`, `minimal://shield`,
    /// `minimal://settings`, `minimal://home`.
    func handle(_ url: URL) {
        guard url.scheme?.lowercased() == SharedConfig.urlScheme else { return }
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
            if let url = pendingURL, let item = pendingItem {
                pendingURL = nil
                pendingItem = nil
                openExternal(url, for: item)
            }
        case .background:
            isActive = false
            // Coming back should always land on a calm home screen.
            isSearching = false
            pausing = nil
        default:
            isActive = false
        }
    }
}
