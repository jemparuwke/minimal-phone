import Foundation

/// `@AppStorage` keys. Kept in one place so names never drift apart.
enum Pref {
    static let onboarded = "pref.onboarded"
    static let textScale = "pref.textScale"
    static let use24h = "pref.use24h"
    static let showSeconds = "pref.showSeconds"
    static let hideStatusBar = "pref.hideStatusBar"
    static let pauseSeconds = "pref.pauseSeconds"
    static let searchEngine = "pref.searchEngine"
    static let haptics = "pref.haptics"
}

/// Web search used from the search screen. Both force strict SafeSearch.
enum SearchEngine: String, CaseIterable, Identifiable {
    case duckDuckGo, google

    var id: String { rawValue }

    var label: String {
        switch self {
        case .duckDuckGo: return "DuckDuckGo"
        case .google: return "Google"
        }
    }

    func url(for query: String) -> URL? {
        var components: URLComponents
        switch self {
        case .duckDuckGo:
            components = URLComponents(string: "https://duckduckgo.com/")!
            // kp=1 → SafeSearch: strict
            components.queryItems = [URLQueryItem(name: "q", value: query), URLQueryItem(name: "kp", value: "1")]
        case .google:
            components = URLComponents(string: "https://www.google.com/search")!
            // safe=active → SafeSearch filter on
            components.queryItems = [URLQueryItem(name: "q", value: query), URLQueryItem(name: "safe", value: "active")]
        }
        return components.url
    }
}

extension String {
    /// Lowercased, without diacritics, with "ł" folded to "l" (which diacritic folding keeps).
    var searchFolded: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Formatters.polish)
            .replacingOccurrences(of: "ł", with: "l")
            .replacingOccurrences(of: "Ł", with: "l")
            .lowercased()
    }
}

enum Formatters {
    static let polish = Locale(identifier: "pl_PL")

    /// Whether the user's iOS region settings use a 24-hour clock.
    static var systemUses24h: Bool {
        let format = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .autoupdatingCurrent) ?? "HH"
        return !format.contains("a")
    }

    static let time24: DateFormatter = make("HH:mm")
    static let time24Seconds: DateFormatter = make("HH:mm:ss")
    static let time12: DateFormatter = make("h:mm")
    static let time12Seconds: DateFormatter = make("h:mm:ss")
    static let longDate: DateFormatter = make("EEEE, d MMMM")
    static let shortDateTime: DateFormatter = make("d MMM, HH:mm")

    private static func make(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = polish
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = format
        return formatter
    }

    /// "4 godz. 12 min", "12 min", "45 s" — Polish iOS style, with non-breaking spaces.
    static func duration(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval.rounded(.up)))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 { return minutes > 0 ? "\(hours)\u{00a0}godz. \(minutes)\u{00a0}min" : "\(hours)\u{00a0}godz." }
        if minutes > 0 { return "\(minutes)\u{00a0}min" }
        return "\(seconds)\u{00a0}s"
    }
}
