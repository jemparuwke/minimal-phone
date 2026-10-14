import Foundation

/// Tiny, local-only counters used by the mindful pause ("4th open today") and the home screen.
@MainActor
final class UsageStats: ObservableObject {
    private struct Day: Codable {
        var date: String
        var opens: [String: Int] = [:]
        var resisted = 0
    }

    private static let key = "stats.day.v1"
    private static let resistedTotalKey = "stats.resistedTotal"

    @Published private var day: Day
    @Published private(set) var resistedTotal: Int

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.data(forKey: Self.key).flatMap { try? JSONDecoder().decode(Day.self, from: $0) }
        day = stored ?? Day(date: Self.todayKey())
        resistedTotal = defaults.integer(forKey: Self.resistedTotalKey)
    }

    func opensToday(of item: LaunchItem) -> Int {
        day.date == Self.todayKey() ? day.opens[item.id.uuidString, default: 0] : 0
    }

    var resistedToday: Int {
        day.date == Self.todayKey() ? day.resisted : 0
    }

    func recordOpen(_ item: LaunchItem) {
        rollOver()
        day.opens[item.id.uuidString, default: 0] += 1
        save()
    }

    func recordResisted() {
        rollOver()
        day.resisted += 1
        resistedTotal += 1
        defaults.set(resistedTotal, forKey: Self.resistedTotalKey)
        save()
    }

    private func rollOver() {
        let today = Self.todayKey()
        if day.date != today { day = Day(date: today) }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(day) { defaults.set(data, forKey: Self.key) }
    }

    private static func todayKey() -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
}
