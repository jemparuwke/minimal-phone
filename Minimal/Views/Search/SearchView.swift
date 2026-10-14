import SwiftUI

/// Every app the user has, one word per line, filtered as they type.
struct SearchView: View {
    @EnvironmentObject private var store: LauncherStore
    @EnvironmentObject private var coordinator: LaunchCoordinator
    @EnvironmentObject private var stats: UsageStats
    @AppStorage(Pref.searchEngine) private var engine: SearchEngine = .duckDuckGo

    @State private var query = ""
    @FocusState private var focused: Bool

    private var trimmed: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var results: [LaunchItem] { store.search(query) }

    /// Shown above the full list before anything is typed, like Spotlight's Siri Suggestions.
    private var recents: [LaunchItem] {
        guard trimmed.isEmpty else { return [] }
        return stats.recentIDs.compactMap(store.item(id:))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    if !recents.isEmpty {
                        sectionLabel("Ostatnio")
                        ForEach(recents) { item in
                            Button {
                                focused = false
                                coordinator.launch(item)
                            } label: {
                                ItemLabel(item: item, size: 26)
                            }
                            .buttonStyle(.dim)
                            .contextMenu { ItemMenu(item: item) }
                            .accessibilityActions { ItemMenu(item: item) }
                        }
                        sectionLabel("Wszystkie")
                            .padding(.top, 12)
                    }

                    ForEach(results) { item in
                        Button {
                            focused = false
                            coordinator.launch(item)
                        } label: {
                            ItemLabel(item: item, size: 26)
                        }
                        .buttonStyle(.dim)
                        .contextMenu { ItemMenu(item: item) }
                        .accessibilityActions { ItemMenu(item: item) }
                    }

                    if !trimmed.isEmpty {
                        suggestions
                    }
                }
                .padding(.horizontal, Theme.gutter)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
            // The list scrolls under the footer and fades out instead of ending in a hard edge.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                footer
                    .background {
                        // A short fade above the buttons, then solid black so no list text
                        // ever shows through the labels.
                        VStack(spacing: 0) {
                            LinearGradient(colors: [Theme.background.opacity(0), Theme.background],
                                           startPoint: .top, endPoint: .bottom)
                                .frame(height: 20)
                            Theme.background
                        }
                        .ignoresSafeArea()
                        .accessibilityHidden(true)
                    }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .accessibilityAction(.escape) { close() }
        .onAppear {
            DispatchQueue.main.async { focused = true }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            TextField("", text: $query, prompt: Text("szukaj").foregroundStyle(Theme.tertiary))
                .minimalFont(30)
                .foregroundStyle(Theme.primary)
                .tint(Theme.primary)
                .focused($focused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .onSubmit(openBestMatch)
                .accessibilityLabel("Szukaj aplikacji")

            Button {
                close()
            } label: {
                Text("Anuluj")
                    .font(.body)
                    .foregroundStyle(Theme.secondary)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.dim)
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var suggestions: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(height: 1)
            .padding(.vertical, 4)

        Button {
            if let url = engine.url(for: trimmed) {
                coordinator.openURL(url)
                close()
            }
        } label: {
            suggestion(icon: "globe", text: "Szukaj „\(trimmed)” w sieci")
        }
        .buttonStyle(.dim)

        Button {
            focused = false
            coordinator.sheet = .newItem(prefill: trimmed)
        } label: {
            suggestion(icon: "plus", text: "Dodaj „\(trimmed)”")
        }
        .buttonStyle(.dim)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Theme.tertiary)
            .textCase(.uppercase)
            .accessibilityAddTraits(.isHeader)
    }

    private func suggestion(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .minimalFont(16, weight: .light)
                .frame(width: 22)
                .accessibilityHidden(true)
            Text(text)
                .font(.title3)
                .lineLimit(1)
        }
        .foregroundStyle(Theme.secondary)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }

    private var footer: some View {
        HStack {
            Button {
                focused = false
                coordinator.sheet = .catalog
            } label: {
                Label("Twoje aplikacje", systemImage: "square.grid.2x2")
                    .frame(minHeight: 44)
            }
            Spacer()
            Button {
                focused = false
                coordinator.sheet = .newItem(prefill: "")
            } label: {
                Label("Dodaj", systemImage: "plus")
                    .frame(minWidth: 44, minHeight: 44)
            }
        }
        .labelStyle(.titleAndIcon)
        .font(.subheadline)
        .foregroundStyle(Theme.tertiary)
        .buttonStyle(.dim)
        .padding(.horizontal, Theme.gutter)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    private func openBestMatch() {
        if let first = results.first, !trimmed.isEmpty {
            coordinator.launch(first)
        } else if !trimmed.isEmpty, let url = engine.url(for: trimmed) {
            coordinator.openURL(url)
            close()
        }
    }

    private func close() {
        focused = false
        query = ""
        coordinator.isSearching = false
    }
}
