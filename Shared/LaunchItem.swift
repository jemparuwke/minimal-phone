import Foundation

/// One entry on the launcher: something with a name that opens when tapped.
struct LaunchItem: Codable, Identifiable, Hashable {
    enum Target: Codable, Hashable {
        /// Any URL: an app's URL scheme (`spotify://`), `tel:`, a website…
        case url(String)
        /// Name of a shortcut in the Shortcuts app. Reaches every app, including ones
        /// without a URL scheme (create a shortcut with the "Open App" action).
        case shortcut(String)
    }

    var id: UUID
    var name: String
    var target: Target
    /// Show a short breathing pause before opening.
    var mindful: Bool
    /// Identifier of the catalog preset this item came from, if any.
    var catalogID: String?

    init(id: UUID = UUID(), name: String, target: Target, mindful: Bool = false, catalogID: String? = nil) {
        self.id = id
        self.name = name
        self.target = target
        self.mindful = mindful
        self.catalogID = catalogID
    }

    var url: URL? {
        switch target {
        case .url(let string):
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return URL(string: Self.normalized(trimmed))
        case .shortcut(let name):
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty,
                  let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed)
            else { return nil }
            return URL(string: "shortcuts://run-shortcut?name=\(encoded)")
        }
    }

    /// "youtube.com" → "https://youtube.com", "spotify" → "spotify://"; anything with a
    /// scheme is left alone.
    static func normalized(_ address: String) -> String {
        if address.range(of: "^[A-Za-z][A-Za-z0-9+.-]*:", options: .regularExpression) != nil {
            return address
        }
        if address.contains(".") { return "https://" + address }
        return address + "://"
    }

    var isShortcut: Bool {
        if case .shortcut = target { return true }
        return false
    }

    // Tolerant decoding so stored data survives future fields being added.
    private enum CodingKeys: String, CodingKey { case id, name, target, mindful, catalogID }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        target = try container.decode(Target.self, forKey: .target)
        mindful = try container.decodeIfPresent(Bool.self, forKey: .mindful) ?? false
        catalogID = try container.decodeIfPresent(String.self, forKey: .catalogID)
    }
}

/// Everything the launcher persists. Shared with the widget through the App Group.
struct LauncherData: Codable, Equatable {
    var items: [LaunchItem]
    var favoriteIDs: [UUID]

    var favorites: [LaunchItem] {
        favoriteIDs.compactMap { id in items.first { $0.id == id } }
    }

    static func load(from defaults: UserDefaults = SharedConfig.defaults) -> LauncherData? {
        guard let data = defaults.data(forKey: SharedConfig.launcherDataKey) else { return nil }
        return try? JSONDecoder().decode(LauncherData.self, from: data)
    }

    func save(to defaults: UserDefaults = SharedConfig.defaults) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: SharedConfig.launcherDataKey)
    }
}

extension CharacterSet {
    /// Characters that may appear unescaped inside a single query value.
    static let urlQueryValueAllowed: CharacterSet = {
        var set = CharacterSet.urlQueryAllowed
        set.remove(charactersIn: "&=+?#/")
        return set
    }()
}
