import Foundation

/// A ready-made launcher entry for a well-known app.
struct CatalogApp: Identifiable, Hashable {
    enum Kind: String, CaseIterable, Identifiable {
        case apple, popular

        var id: String { rawValue }

        var title: String {
            switch self {
            case .apple: return "Apple"
            case .popular: return "Popularne"
            }
        }
    }

    let id: String
    let name: String
    let url: String
    let kind: Kind
    /// Feeds and other time sinks start with the mindful pause switched on.
    var mindful = false

    func makeItem() -> LaunchItem {
        LaunchItem(name: name, target: .url(url), mindful: mindful, catalogID: id)
    }
}

enum AppCatalog {
    static let all: [CatalogApp] = apple + popular

    static let apple: [CatalogApp] = [
        CatalogApp(id: "phone", name: "Telefon", url: "mobilephone://", kind: .apple),
        CatalogApp(id: "messages", name: "Wiadomości", url: "sms:", kind: .apple),
        CatalogApp(id: "facetime", name: "FaceTime", url: "facetime://", kind: .apple),
        CatalogApp(id: "mail", name: "Mail", url: "message://", kind: .apple),
        CatalogApp(id: "safari", name: "Safari", url: "x-web-search://", kind: .apple),
        CatalogApp(id: "photos", name: "Zdjęcia", url: "photos-redirect://", kind: .apple),
        CatalogApp(id: "maps", name: "Mapy", url: "maps://", kind: .apple),
        CatalogApp(id: "music", name: "Muzyka", url: "music://", kind: .apple),
        CatalogApp(id: "calendar", name: "Kalendarz", url: "calshow://", kind: .apple),
        CatalogApp(id: "reminders", name: "Przypomnienia", url: "x-apple-reminderkit://", kind: .apple),
        CatalogApp(id: "notes", name: "Notatki", url: "mobilenotes://", kind: .apple),
        CatalogApp(id: "clock", name: "Zegar", url: "clock-alarm://", kind: .apple),
        CatalogApp(id: "weather", name: "Pogoda", url: "weather://", kind: .apple),
        CatalogApp(id: "wallet", name: "Portfel", url: "shoebox://", kind: .apple),
        CatalogApp(id: "files", name: "Pliki", url: "shareddocuments://", kind: .apple),
        CatalogApp(id: "podcasts", name: "Podcasty", url: "podcasts://", kind: .apple),
        CatalogApp(id: "books", name: "Książki", url: "ibooks://", kind: .apple),
        CatalogApp(id: "health", name: "Zdrowie", url: "x-apple-health://", kind: .apple),
        CatalogApp(id: "findmy", name: "Znajdź", url: "findmy://", kind: .apple),
        CatalogApp(id: "shortcuts", name: "Skróty", url: "shortcuts://", kind: .apple),
        CatalogApp(id: "appstore", name: "App Store", url: "itms-apps://", kind: .apple),
        CatalogApp(id: "settings", name: "Ustawienia", url: "App-prefs:", kind: .apple),
    ]

    static let popular: [CatalogApp] = [
        CatalogApp(id: "whatsapp", name: "WhatsApp", url: "whatsapp://", kind: .popular),
        CatalogApp(id: "messenger", name: "Messenger", url: "fb-messenger://", kind: .popular),
        CatalogApp(id: "signal", name: "Signal", url: "sgnl://", kind: .popular),
        CatalogApp(id: "telegram", name: "Telegram", url: "tg://", kind: .popular),
        CatalogApp(id: "gmail", name: "Gmail", url: "googlegmail://", kind: .popular),
        CatalogApp(id: "outlook", name: "Outlook", url: "ms-outlook://", kind: .popular),
        CatalogApp(id: "googlemaps", name: "Mapy Google", url: "comgooglemaps://", kind: .popular),
        CatalogApp(id: "waze", name: "Waze", url: "waze://", kind: .popular),
        CatalogApp(id: "spotify", name: "Spotify", url: "spotify://", kind: .popular),
        CatalogApp(id: "chrome", name: "Chrome", url: "googlechrome://", kind: .popular),
        CatalogApp(id: "google", name: "Google", url: "google://", kind: .popular),
        CatalogApp(id: "googledrive", name: "Dysk Google", url: "googledrive://", kind: .popular),
        CatalogApp(id: "slack", name: "Slack", url: "slack://", kind: .popular),
        CatalogApp(id: "teams", name: "Teams", url: "msteams://", kind: .popular),
        CatalogApp(id: "zoom", name: "Zoom", url: "zoomus://", kind: .popular),
        CatalogApp(id: "notion", name: "Notion", url: "notion://", kind: .popular),
        CatalogApp(id: "revolut", name: "Revolut", url: "revolut://", kind: .popular),
        CatalogApp(id: "uber", name: "Uber", url: "uber://", kind: .popular),
        CatalogApp(id: "linkedin", name: "LinkedIn", url: "linkedin://", kind: .popular, mindful: true),
        CatalogApp(id: "youtube", name: "YouTube", url: "youtube://", kind: .popular, mindful: true),
        CatalogApp(id: "instagram", name: "Instagram", url: "instagram://", kind: .popular, mindful: true),
        CatalogApp(id: "facebook", name: "Facebook", url: "fb://", kind: .popular, mindful: true),
        CatalogApp(id: "netflix", name: "Netflix", url: "nflx://", kind: .popular, mindful: true),
        CatalogApp(id: "x", name: "X", url: "twitter://", kind: .popular, mindful: true),
        CatalogApp(id: "snapchat", name: "Snapchat", url: "snapchat://", kind: .popular, mindful: true),
        CatalogApp(id: "discord", name: "Discord", url: "discord://", kind: .popular, mindful: true),
    ]

    /// IDs that start on the home screen for a new user.
    static let starterFavorites = ["phone", "messages", "maps", "music", "calendar", "notes"]

    /// A fresh launcher: Apple's essentials, a few favorites.
    static func starterData() -> LauncherData {
        let items = apple.map { $0.makeItem() }
        let favorites = starterFavorites.compactMap { id in items.first { $0.catalogID == id }?.id }
        return LauncherData(items: items, favoriteIDs: favorites)
    }

    static func search(_ query: String, kind: CatalogApp.Kind? = nil) -> [CatalogApp] {
        let pool = kind.map { kind in all.filter { $0.kind == kind } } ?? all
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let sorted = pool.sorted { $0.name.compare($1.name, locale: Formatters.polish) == .orderedAscending }
        guard !needle.isEmpty else { return sorted }
        return sorted.filter {
            $0.name.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive], locale: Formatters.polish) != nil
        }
    }
}
