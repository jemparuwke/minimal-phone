import SwiftUI
import WidgetKit

@main
struct MinimalWidgetBundle: WidgetBundle {
    var body: some Widget {
        FavoritesWidget()
        SearchWidget()
    }
}

private let polish = Locale(identifier: "pl_PL")

// MARK: - Timeline

struct FavoritesEntry: TimelineEntry {
    enum State {
        case ready
        /// The App Group is not provisioned, so the widget cannot see the app's data.
        case noAppGroup
        /// Minimal has not been opened yet (or has no favorites).
        case empty
    }

    let date: Date
    let items: [LaunchItem]
    let state: State
}

struct FavoritesProvider: TimelineProvider {
    func placeholder(in context: Context) -> FavoritesEntry {
        FavoritesEntry(date: Date(), items: Self.sample, state: .ready)
    }

    func getSnapshot(in context: Context, completion: @escaping (FavoritesEntry) -> Void) {
        let entry = makeEntry(at: Date())
        if context.isPreview, entry.state != .ready {
            completion(FavoritesEntry(date: Date(), items: Self.sample, state: .ready))
        } else {
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FavoritesEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now.addingTimeInterval(86_400)
        let current = makeEntry(at: now)

        guard current.state == .ready else {
            // Nothing to show yet: look again soon (the app also reloads us when it opens).
            completion(Timeline(entries: [current], policy: .after(now.addingTimeInterval(15 * 60))))
            return
        }
        // A second entry flips the date exactly at midnight; the app reloads us on every edit.
        let tomorrow = FavoritesEntry(date: midnight, items: current.items, state: .ready)
        completion(Timeline(entries: [current, tomorrow], policy: .after(midnight)))
    }

    private func makeEntry(at date: Date) -> FavoritesEntry {
        guard SharedConfig.isAppGroupAvailable else {
            return FavoritesEntry(date: date, items: [], state: .noAppGroup)
        }
        let favorites = LauncherData.load()?.favorites ?? []
        return FavoritesEntry(date: date, items: favorites, state: favorites.isEmpty ? .empty : .ready)
    }

    static let sample: [LaunchItem] = ["Telefon", "Wiadomości", "Aparat", "Mapy", "Muzyka", "Kalendarz"]
        .map { LaunchItem(name: $0, target: .url("")) }
}

// MARK: - Favorites widget (Home Screen + Lock Screen)

struct FavoritesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SharedConfig.favoritesWidgetKind, provider: FavoritesProvider()) { entry in
            FavoritesWidgetView(entry: entry)
        }
        .configurationDisplayName("Ulubione")
        .description("Twoje najważniejsze aplikacje. Tylko słowa.")
        .supportedFamilies([.systemMedium, .systemLarge, .accessoryRectangular])
    }
}

struct FavoritesWidgetView: View {
    let entry: FavoritesEntry
    @Environment(\.widgetFamily) private var family

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = polish
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter
    }()

    var body: some View {
        switch family {
        case .accessoryRectangular:
            lockScreen
        default:
            homeScreen
        }
    }

    // MARK: Home Screen

    private var homeScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            if family == .systemLarge {
                Text(Self.dateFormatter.string(from: entry.date))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 8)
            }

            switch entry.state {
            case .ready:
                if family == .systemMedium, entry.items.count > 4 {
                    HStack(alignment: .top, spacing: 12) {
                        column(Array(entry.items.prefix(4)))
                        column(Array(entry.items.dropFirst(4).prefix(4)))
                    }
                } else {
                    column(Array(entry.items.prefix(family == .systemLarge ? 8 : 4)))
                }
            case .empty:
                message("Otwórz Minimal i\u{00a0}wybierz ulubione.")
            case .noAppGroup:
                message("Widżet nie widzi danych Minimal. Sprawdź App Group w\u{00a0}Xcode (README).")
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) { Color.black }
        .widgetURL(SharedConfig.homeURL)
    }

    private var rowHeight: CGFloat { family == .systemLarge ? 36 : 31 }
    private var fontSize: CGFloat { family == .systemLarge ? 25 : 21 }

    /// Rows tile the height with no gaps, so every tap lands on an app, never on "nothing".
    private func column(_ items: [LaunchItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items) { item in
                Link(destination: SharedConfig.openURL(for: item.id)) {
                    Text(item.name.lowercased(with: polish))
                        .font(.system(size: fontSize, weight: .light))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, maxHeight: rowHeight, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .widgetAccentable()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(.white.opacity(0.6))
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Lock Screen

    private var lockScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            if entry.items.isEmpty {
                Text("minimal")
                    .font(.headline)
                Text("Dodaj ulubione w\u{00a0}aplikacji")
                    .font(.caption)
            } else {
                ForEach(entry.items.prefix(3)) { item in
                    Text(item.name.lowercased(with: polish))
                        .font(.system(.body, weight: .medium))
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(SharedConfig.homeURL)
    }
}

// MARK: - Search widget

struct SearchEntry: TimelineEntry {
    let date: Date
}

struct SearchProvider: TimelineProvider {
    func placeholder(in context: Context) -> SearchEntry { SearchEntry(date: Date()) }

    func getSnapshot(in context: Context, completion: @escaping (SearchEntry) -> Void) {
        completion(SearchEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SearchEntry>) -> Void) {
        completion(Timeline(entries: [SearchEntry(date: Date())], policy: .never))
    }
}

struct SearchWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SharedConfig.searchWidgetKind, provider: SearchProvider()) { _ in
            SearchWidgetView()
        }
        .configurationDisplayName("Szukaj")
        .description("Wyszukaj dowolną aplikację jednym stuknięciem.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

struct SearchWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Szukaj w Minimal")
            .accessibilityAddTraits(.isButton)
            .widgetURL(SharedConfig.searchURL)
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .medium))
            }
            .containerBackground(for: .widget) { Color.clear }
        default:
            VStack(alignment: .leading) {
                Text("minimal")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .light))
                    Text("szukaj")
                        .font(.system(size: 24, weight: .light))
                }
                .foregroundStyle(.white)
                .widgetAccentable()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerBackground(for: .widget) { Color.black }
        }
    }
}
