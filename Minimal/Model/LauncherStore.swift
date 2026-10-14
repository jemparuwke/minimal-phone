import Foundation
import SwiftUI
import WidgetKit

/// The user's launcher: every item they can open, plus the ordered favorites on the home screen.
@MainActor
final class LauncherStore: ObservableObject {
    /// Home screen stays calm: at most this many favorites.
    static let maxFavorites = 8

    @Published private(set) var data: LauncherData

    private let defaults: UserDefaults

    init(defaults: UserDefaults = SharedConfig.defaults) {
        self.defaults = defaults
        if let stored = LauncherData.load(from: defaults) {
            data = stored
        } else {
            if let unreadable = defaults.data(forKey: SharedConfig.launcherDataKey) {
                // Never destroy a list we failed to read: keep a copy for a future version.
                defaults.set(unreadable, forKey: SharedConfig.launcherDataKey + ".backup")
            }
            data = AppCatalog.starterData()
            data.save(to: defaults)
            WidgetCenter.shared.reloadTimelines(ofKind: SharedConfig.favoritesWidgetKind)
        }
    }

    var items: [LaunchItem] { data.items }

    var favorites: [LaunchItem] { data.favorites }

    /// All items, alphabetically (Polish collation).
    var sortedItems: [LaunchItem] {
        data.items.sorted { $0.name.compare($1.name, locale: Formatters.polish) == .orderedAscending }
    }

    var canAddFavorite: Bool { data.favoriteIDs.count < Self.maxFavorites }

    func item(id: UUID) -> LaunchItem? {
        data.items.first { $0.id == id }
    }

    func isFavorite(_ item: LaunchItem) -> Bool {
        data.favoriteIDs.contains(item.id)
    }

    func item(forCatalogID catalogID: String) -> LaunchItem? {
        data.items.first { $0.catalogID == catalogID }
    }

    /// Items whose name matches the query, best matches (prefix) first.
    func search(_ query: String) -> [LaunchItem] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).searchFolded
        guard !needle.isEmpty else { return sortedItems }
        let matches = sortedItems.filter { $0.name.searchFolded.contains(needle) }
        let prefix = matches.filter { $0.name.searchFolded.hasPrefix(needle) }
        let rest = matches.filter { item in !prefix.contains(where: { $0.id == item.id }) }
        return prefix + rest
    }

    // MARK: - Mutations

    func add(_ item: LaunchItem, favorite: Bool = false) {
        mutate { data in
            data.items.append(item)
            if favorite, data.favoriteIDs.count < Self.maxFavorites {
                data.favoriteIDs.append(item.id)
            }
        }
    }

    func update(_ item: LaunchItem) {
        mutate { data in
            guard let index = data.items.firstIndex(where: { $0.id == item.id }) else { return }
            data.items[index] = item
        }
    }

    func remove(_ item: LaunchItem) {
        mutate { data in
            data.items.removeAll { $0.id == item.id }
            data.favoriteIDs.removeAll { $0 == item.id }
        }
    }

    func setFavorite(_ item: LaunchItem, _ isFavorite: Bool) {
        mutate { data in
            if isFavorite {
                guard !data.favoriteIDs.contains(item.id), data.favoriteIDs.count < Self.maxFavorites else { return }
                data.favoriteIDs.append(item.id)
            } else {
                data.favoriteIDs.removeAll { $0 == item.id }
            }
        }
    }

    func moveFavorites(from source: IndexSet, to destination: Int) {
        mutate { data in
            // Drop dangling IDs first so indices match what the editor shows.
            data.favoriteIDs = data.favorites.map(\.id)
            data.favoriteIDs.move(fromOffsets: source, toOffset: destination)
        }
    }

    func removeFavorites(at offsets: IndexSet) {
        mutate { data in
            data.favoriteIDs = data.favorites.map(\.id)
            data.favoriteIDs.remove(atOffsets: offsets)
        }
    }

    /// Adds or removes a catalog preset.
    func setCatalogApp(_ app: CatalogApp, included: Bool) {
        if included {
            guard item(forCatalogID: app.id) == nil else { return }
            add(app.makeItem())
        } else if let existing = item(forCatalogID: app.id) {
            remove(existing)
        }
    }

    func resetToStarter() {
        mutate { data in data = AppCatalog.starterData() }
    }

    private func mutate(_ change: (inout LauncherData) -> Void) {
        var copy = data
        change(&copy)
        guard copy != data else { return }
        data = copy
        copy.save(to: defaults)
        WidgetCenter.shared.reloadTimelines(ofKind: SharedConfig.favoritesWidgetKind)
    }
}
