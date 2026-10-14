import AppIntents

/// "Szukaj w Minimal" and "Tarcza" for the Action Button, Spotlight and the Shortcuts app.
struct OpenSearchIntent: AppIntent {
    static let title: LocalizedStringResource = "Szukaj w Minimal"
    static let description = IntentDescription("Otwiera Minimal od razu z\u{00a0}wyszukiwaniem wszystkich aplikacji.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        LaunchCoordinator.current?.handle(SharedConfig.searchURL)
        return .result()
    }
}

struct OpenShieldIntent: AppIntent {
    static let title: LocalizedStringResource = "Pokaż tarczę Minimal"
    static let description = IntentDescription("Otwiera ustawienia tarczy blokującej treści dla dorosłych.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        LaunchCoordinator.current?.handle(SharedConfig.shieldURL)
        return .result()
    }
}

struct MinimalShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenSearchIntent(),
            phrases: ["Szukaj w \(.applicationName)", "Search in \(.applicationName)"],
            shortTitle: "Szukaj",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: OpenShieldIntent(),
            phrases: ["Tarcza \(.applicationName)", "Open \(.applicationName) shield"],
            shortTitle: "Tarcza",
            systemImageName: "checkmark.shield"
        )
    }
}
