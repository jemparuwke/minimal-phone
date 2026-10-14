import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: LauncherStore
    @EnvironmentObject private var stats: UsageStats
    @EnvironmentObject private var shield: ShieldModel
    @Environment(\.dismiss) private var dismiss

    @AppStorage(Pref.textScale) private var textScale: TextScale = .medium
    @AppStorage(Pref.use24h) private var use24h = Formatters.systemUses24h
    @AppStorage(Pref.showSeconds) private var showSeconds = false
    @AppStorage(Pref.hideStatusBar) private var hideStatusBar = true
    @AppStorage(Pref.pauseSeconds) private var pauseSeconds = 5
    @AppStorage(Pref.searchEngine) private var engine: SearchEngine = .duckDuckGo
    @AppStorage(Pref.haptics) private var haptics = true
    @AppStorage(Pref.onboarded) private var onboarded = true

    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                header

                if !SharedConfig.isAppGroupAvailable {
                    Section {
                        Label("Widżet nie widzi Twoich ulubionych. W Xcode dodaj App Group „\(SharedConfig.appGroup)” do obu targetów (Signing & Capabilities) i zainstaluj ponownie.", systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(Theme.warning)
                    }
                    .minimalRow()
                }

                Section {
                    NavigationLink {
                        ShieldView()
                    } label: {
                        SettingsRow(icon: shield.isProtecting ? "checkmark.shield.fill" : "shield",
                                    color: shield.isProtecting ? Theme.good : Theme.warning,
                                    title: "Tarcza",
                                    value: shield.isProtecting ? "Włączona" : "Wyłączona")
                    }
                    NavigationLink {
                        SetupGuideView()
                    } label: {
                        SettingsRow(icon: "sparkles", color: .white, title: "Przewodnik minimalizmu")
                    }
                }
                .minimalRow()

                Section("Układ") {
                    NavigationLink {
                        FavoritesEditorView(showsDone: false)
                    } label: {
                        SettingsRow(icon: "star", color: .white, title: "Ulubione", value: "\(store.favorites.count)")
                    }
                    NavigationLink {
                        LibraryView(showsDone: false)
                    } label: {
                        SettingsRow(icon: "square.grid.2x2", color: .white, title: "Twoje aplikacje", value: "\(store.items.count)")
                    }
                    Picker(selection: $textScale) {
                        ForEach(TextScale.allCases) { scale in
                            Text(scale.label).tag(scale)
                        }
                    } label: {
                        SettingsRow(icon: "textformat.size", color: .white, title: "Wielkość tekstu")
                    }
                    Toggle(isOn: $use24h) {
                        SettingsRow(icon: "clock", color: .white, title: "Czas 24-godzinny")
                    }
                    Toggle(isOn: $showSeconds) {
                        SettingsRow(icon: "stopwatch", color: .white, title: "Pokazuj sekundy")
                    }
                    Toggle(isOn: $hideStatusBar) {
                        SettingsRow(icon: "rectangle.dashed", color: .white, title: "Ukryj pasek stanu")
                    }
                }
                .minimalRow()

                Section {
                    Picker(selection: $pauseSeconds) {
                        ForEach([3, 5, 10, 15, 30], id: \.self) { seconds in
                            Text("\(seconds) s").tag(seconds)
                        }
                    } label: {
                        SettingsRow(icon: "wind", color: .white, title: "Długość pauzy")
                    }
                    Picker(selection: $engine) {
                        ForEach(SearchEngine.allCases) { engine in
                            Text(engine.label).tag(engine)
                        }
                    } label: {
                        SettingsRow(icon: "globe", color: .white, title: "Wyszukiwarka")
                    }
                    Toggle(isOn: $haptics) {
                        SettingsRow(icon: "hand.tap", color: .white, title: "Haptyka")
                    }
                } header: {
                    Text("Zachowanie")
                } footer: {
                    Text("Wyszukiwanie w sieci zawsze używa ścisłego filtra SafeSearch.")
                }
                .minimalRow()

                Section {
                    Button {
                        dismiss()
                        // Let the sheet finish closing before the welcome screen is presented.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { onboarded = false }
                    } label: {
                        SettingsRow(icon: "hand.wave", color: .white, title: "Pokaż powitanie")
                    }
                    Button(role: .destructive) {
                        confirmReset = true
                    } label: {
                        Text("Przywróć domyślną listę aplikacji")
                    }
                    .confirmationDialog("Przywrócić domyślną listę? Twoje własne skróty zostaną usunięte.",
                                        isPresented: $confirmReset, titleVisibility: .visible) {
                        Button("Przywróć", role: .destructive) { store.resetToStarter() }
                    }
                } footer: {
                    Text(footerText)
                }
                .minimalRow()
            }
            .navigationTitle("Ustawienia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gotowe") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .minimalSheet()
    }

    private var header: some View {
        Section {
            VStack(spacing: 6) {
                Text("minimal")
                    .minimalFont(34, weight: .thin)
                    .foregroundStyle(Theme.primary)
                Text(stats.resistedTotal > 0
                     ? "Odpuszczone pokusy: \(stats.resistedTotal)"
                     : "Mniej ekranu. Więcej życia.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .listRowBackground(Color.clear)
    }

    private var footerText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        return "Minimal \(version) · Bez kont, bez reklam, bez śledzenia. Minimal niczego nie wysyła — tylko filtr DNS pyta wybranego dostawcę o adresy stron."
    }
}

/// Settings-style row: small SF Symbol, title, optional trailing value.
struct SettingsRow: View {
    let icon: String
    var color: Color = .white
    let title: String
    var value: String? = nil

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .minimalFont(16, weight: .regular)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(title)
                .foregroundStyle(Theme.primary)
            if let value {
                Spacer()
                Text(value)
                    .foregroundStyle(Theme.secondary)
            }
        }
    }
}
