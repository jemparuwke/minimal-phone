import SwiftUI
import WidgetKit

@main
struct MinimalWidgetBundle: WidgetBundle {
    var body: some Widget {
        FavoritesWidget()
        SearchWidget()
    }
}

// MARK: - Timeline

struct FavoritesEntry: TimelineEntry {
    let date: Date
    let items: [LaunchItem]
}

struct FavoritesProvider: TimelineProvider {
    func placeholder(in context: Context) -> FavoritesEntry {
        FavoritesEntry(date: Date(), items: Self.sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (FavoritesEntry) -> Void) {
        let items = LauncherData.load()?.favorites ?? []
        completion(FavoritesEntry(date: Date(), items: context.isPreview && items.isEmpty ? Self.sample : items))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FavoritesEntry>) -> Void) {
        let now = Date()
        let entry = FavoritesEntry(date: now, items: LauncherData.load()?.favorites ?? [])
        // The app reloads timelines whenever favorites change; refresh at midnight for the date.
        let midnight = Calendar.current.startOfDay(for: now).addingTimeInterval(86_400 + 60)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    static let sample: [LaunchItem] = ["Telefon", "Wiadomości", "Mapy", "Muzyka", "Kalendarz", "Notatki"]
        .map { LaunchItem(name: $0, target: .url("")) }
}

// MARK: - Favorites widget (Home Screen + Lock Screen)

struct FavoritesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "pl.minimal.favorites", provider: FavoritesProvider()) { entry in
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
        formatter.locale = Locale(identifier: "pl_PL")
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

    private var maxItems: Int { family == .systemLarge ? 8 : 4 }
    private var fontSize: CGFloat { family == .systemLarge ? 25 : 21 }

    private var homeScreen: some View {
        VStack(alignment: .leading, spacing: family == .systemLarge ? 9 : 6) {
            if family == .systemLarge {
                Text(Self.dateFormatter.string(from: entry.date))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 6)
            }

            if entry.items.isEmpty {
                Text("Otwórz Minimal i wybierz ulubione.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }

            ForEach(entry.items.prefix(maxItems)) { item in
                Link(destination: SharedConfig.openURL(for: item.id)) {
                    Text(item.name.lowercased(with: Locale(identifier: "pl_PL")))
                        .font(.system(size: fontSize, weight: .light))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .widgetAccentable()
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) { Color.black }
        .widgetURL(SharedConfig.homeURL)
    }

    private var lockScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            if entry.items.isEmpty {
                Text("minimal")
                    .font(.headline)
            }
            ForEach(entry.items.prefix(3)) { item in
                Text(item.name.lowercased(with: Locale(identifier: "pl_PL")))
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)
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
        StaticConfiguration(kind: "pl.minimal.search", provider: SearchProvider()) { _ in
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
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .medium))
            }
            .containerBackground(for: .widget) { Color.clear }
            .widgetURL(SharedConfig.searchURL)
            .accessibilityLabel("Szukaj w Minimal")
        default:
            VStack(alignment: .leading) {
                Text("minimal")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
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
            .widgetURL(SharedConfig.searchURL)
        }
    }
}
