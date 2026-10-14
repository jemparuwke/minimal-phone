import Foundation

/// A ready-made launcher entry for a well-known app.
struct CatalogApp: Identifiable, Hashable {
    enum Kind: String, CaseIterable, Identifiable {
        case apple, popular, poland

        var id: String { rawValue }

        var title: String {
            switch self {
            case .apple: return "Apple"
            case .popular: return "Popularne"
            case .poland: return "Polskie"
            }
        }
    }

    let id: String
    let name: String
    /// Tried in order until one opens. `https` entries are universal links and only
    /// open the app itself (never the browser).
    let urls: [String]
    let kind: Kind
    /// Feeds and other time sinks start with the mindful pause switched on.
    var mindful = false

    init(_ id: String, _ name: String, _ urls: [String], _ kind: Kind, mindful: Bool = false) {
        self.id = id
        self.name = name
        self.urls = urls
        self.kind = kind
        self.mindful = mindful
    }

    func makeItem() -> LaunchItem {
        LaunchItem(name: name, target: .url(urls.first ?? ""), mindful: mindful, catalogID: id)
    }
}

/// URL schemes come from Apple's documentation, vendors' docs and shipping launchers.
/// Apple apps without a public scheme (Phone, Camera, Clock…) are reached through
/// Shortcuts: it opens the app's private scheme on our behalf.
enum AppCatalog {
    static let all: [CatalogApp] = apple + popular + poland

    private static func viaShortcuts(_ scheme: String) -> String {
        "shortcuts://x-callback-url/run-shortcut?x-error=\(scheme)"
    }

    static let apple: [CatalogApp] = [
        CatalogApp("phone", "Telefon", [viaShortcuts("mobilephone://")], .apple),
        CatalogApp("messages", "Wiadomości", [viaShortcuts("iChat://"), "sms:"], .apple),
        CatalogApp("camera", "Aparat", [viaShortcuts("camera://")], .apple),
        CatalogApp("photos", "Zdjęcia", ["photos-redirect://"], .apple),
        CatalogApp("mail", "Mail", ["message://"], .apple),
        CatalogApp("safari", "Safari", ["x-web-search://"], .apple),
        CatalogApp("maps", "Mapy", ["maps://", "https://maps.apple.com/"], .apple),
        CatalogApp("music", "Muzyka", ["music://"], .apple),
        CatalogApp("calendar", "Kalendarz", ["calshow://"], .apple),
        CatalogApp("reminders", "Przypomnienia", ["x-apple-reminderkit://"], .apple),
        CatalogApp("notes", "Notatki", ["mobilenotes://"], .apple),
        CatalogApp("clock", "Zegar", [viaShortcuts("clock-timer://")], .apple),
        CatalogApp("calculator", "Kalkulator", [viaShortcuts("calc://")], .apple),
        CatalogApp("contacts", "Kontakty", [viaShortcuts("contact://")], .apple),
        CatalogApp("weather", "Pogoda", ["weather://"], .apple),
        CatalogApp("wallet", "Portfel", ["shoebox://"], .apple),
        CatalogApp("files", "Pliki", ["shareddocuments://"], .apple),
        CatalogApp("podcasts", "Podcasty", ["podcasts://"], .apple),
        CatalogApp("books", "Książki", ["ibooks://", "itms-books://"], .apple),
        CatalogApp("health", "Zdrowie", ["x-apple-health://"], .apple),
        CatalogApp("findmy", "Znajdź", ["findmyfriends://", "findmy://"], .apple),
        CatalogApp("translate", "Tłumacz", [viaShortcuts("translate://")], .apple),
        CatalogApp("voicememos", "Dyktafon", [viaShortcuts("voicememos://")], .apple),
        CatalogApp("shortcuts", "Skróty", ["shortcuts://"], .apple),
        CatalogApp("appstore", "App Store", ["itms-apps://itunes.apple.com"], .apple),
        CatalogApp("settings", "Ustawienia", ["prefs:", "App-prefs:"], .apple),
    ]

    static let popular: [CatalogApp] = [
        CatalogApp("whatsapp", "WhatsApp", ["whatsapp://"], .popular),
        CatalogApp("messenger", "Messenger", ["fb-messenger://"], .popular),
        CatalogApp("signal", "Signal", ["sgnl://"], .popular),
        CatalogApp("telegram", "Telegram", ["tg://", "telegram://"], .popular),
        CatalogApp("gmail", "Gmail", ["googlegmail://"], .popular),
        CatalogApp("outlook", "Outlook", ["ms-outlook://"], .popular),
        CatalogApp("googlemaps", "Mapy Google", ["comgooglemaps://", "https://maps.google.com/"], .popular),
        CatalogApp("waze", "Waze", ["waze://", "https://waze.com/ul"], .popular),
        CatalogApp("uber", "Uber", ["uber://", "https://m.uber.com/looking"], .popular),
        CatalogApp("spotify", "Spotify", ["spotify:", "https://open.spotify.com/home"], .popular),
        CatalogApp("youtubemusic", "YouTube Music", ["youtubemusic://"], .popular),
        CatalogApp("shazam", "Shazam", ["shazam://"], .popular),
        CatalogApp("chrome", "Chrome", ["googlechrome://"], .popular),
        CatalogApp("firefox", "Firefox", ["firefox://"], .popular),
        CatalogApp("google", "Google", ["google://"], .popular),
        CatalogApp("googledrive", "Dysk Google", ["googledrive://"], .popular),
        CatalogApp("googlephotos", "Zdjęcia Google", ["googlephotos://"], .popular),
        CatalogApp("googlecalendar", "Kalendarz Google", ["googlecalendar://", "comgooglecalendar://"], .popular),
        CatalogApp("chatgpt", "ChatGPT", ["chatgpt://"], .popular),
        CatalogApp("claude", "Claude", ["claude://"], .popular),
        CatalogApp("slack", "Slack", ["slack://"], .popular),
        CatalogApp("teams", "Teams", ["msteams://"], .popular),
        CatalogApp("zoom", "Zoom", ["zoomus://", "https://zoom.us/router?page=phone"], .popular),
        CatalogApp("notion", "Notion", ["notion://"], .popular),
        CatalogApp("obsidian", "Obsidian", ["obsidian://"], .popular),
        CatalogApp("things", "Things", ["things:///"], .popular),
        CatalogApp("todoist", "Todoist", ["todoist://"], .popular),
        CatalogApp("revolut", "Revolut", ["revolut://"], .popular),
        CatalogApp("strava", "Strava", ["strava://"], .popular),
        CatalogApp("duolingo", "Duolingo", ["duolingo://", "https://duolingo.com"], .popular),
        CatalogApp("kindle", "Kindle", ["kindle://"], .popular),
        CatalogApp("audible", "Audible", ["audible://"], .popular),
        CatalogApp("airbnb", "Airbnb", ["airbnb://", "https://www.airbnb.com"], .popular),
        CatalogApp("booking", "Booking.com", ["booking://", "https://www.booking.com"], .popular),
        CatalogApp("linkedin", "LinkedIn", ["linkedin://", "https://linkedin.com"], .popular, mindful: true),
        CatalogApp("youtube", "YouTube", ["youtube://", "https://www.youtube.com/"], .popular, mindful: true),
        CatalogApp("instagram", "Instagram", ["instagram://", "https://instagram.com/"], .popular, mindful: true),
        CatalogApp("facebook", "Facebook", ["fb://", "https://facebook.com"], .popular, mindful: true),
        CatalogApp("threads", "Threads", ["barcelona://"], .popular, mindful: true),
        CatalogApp("tiktok", "TikTok", ["snssdk1233://", "tiktok://", "https://www.tiktok.com/"], .popular, mindful: true),
        CatalogApp("x", "X", ["twitter://", "https://x.com"], .popular, mindful: true),
        CatalogApp("snapchat", "Snapchat", ["snapchat://"], .popular, mindful: true),
        CatalogApp("pinterest", "Pinterest", ["pinterest://", "https://pinterest.com/"], .popular, mindful: true),
        CatalogApp("discord", "Discord", ["discord://", "https://discord.gg/"], .popular, mindful: true),
        CatalogApp("netflix", "Netflix", ["nflx://"], .popular, mindful: true),
        CatalogApp("twitch", "Twitch", ["twitch://open"], .popular, mindful: true),
    ]

    /// Polish apps publish no URL schemes; their universal links open the app when it is
    /// installed. If one does not work on your phone, add the app through Shortcuts.
    static let poland: [CatalogApp] = [
        CatalogApp("allegro", "Allegro", ["https://allegro.pl/"], .poland),
        CatalogApp("olx", "OLX", ["https://www.olx.pl/"], .poland),
        CatalogApp("vinted", "Vinted", ["https://www.vinted.pl/"], .poland),
        CatalogApp("inpost", "InPost", ["https://inpost.pl/"], .poland),
        CatalogApp("jakdojade", "Jakdojade", ["https://jakdojade.pl/"], .poland),
        CatalogApp("pyszne", "Pyszne.pl", ["https://www.pyszne.pl/"], .poland),
        CatalogApp("glovo", "Glovo", ["https://glovoapp.com"], .poland),
        CatalogApp("wolt", "Wolt", ["https://wolt.com/"], .poland),
    ]

    static func app(id: String?) -> CatalogApp? {
        guard let id else { return nil }
        return all.first { $0.id == id }
    }

    /// IDs that start in favorites for a new user.
    static let starterFavorites = ["phone", "messages", "camera", "maps", "music", "calendar"]

    /// Apple apps a new user starts with (the rest is one tap away in the catalog).
    private static let starterApple = [
        "phone", "messages", "camera", "photos", "mail", "safari", "maps", "music", "calendar",
        "reminders", "notes", "clock", "calculator", "weather", "wallet", "files", "settings",
        "appstore",
    ]

    /// A fresh launcher: Apple's essentials, a few favorites.
    static func starterData() -> LauncherData {
        let items = starterApple.compactMap { id in app(id: id)?.makeItem() }
        let favorites = starterFavorites.compactMap { id in items.first { $0.catalogID == id }?.id }
        return LauncherData(items: items, favoriteIDs: favorites)
    }

    static func search(_ query: String, kind: CatalogApp.Kind? = nil) -> [CatalogApp] {
        let pool = kind.map { kind in all.filter { $0.kind == kind } } ?? all
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).searchFolded
        let sorted = pool.sorted { $0.name.compare($1.name, locale: Formatters.polish) == .orderedAscending }
        guard !needle.isEmpty else { return sorted }
        return sorted.filter { $0.name.searchFolded.contains(needle) }
    }
}
