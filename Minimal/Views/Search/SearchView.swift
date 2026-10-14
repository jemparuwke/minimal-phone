import SwiftUI

/// Every app the user has, one word per line, filtered as they type.
struct SearchView: View {
    @EnvironmentObject private var store: LauncherStore
    @EnvironmentObject private var coordinator: LaunchCoordinator
    @AppStorage(Pref.searchEngine) private var engine: SearchEngine = .duckDuckGo

    @State private var query = ""
    @FocusState private var focused: Bool

    private var trimmed: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var results: [LaunchItem] { store.search(query) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(results) { item in
                        Button {
                            focused = false
                            coordinator.launch(item)
                        } label: {
                            ItemLabel(item: item, size: 26)
                        }
                        .buttonStyle(.dim)
                        .contextMenu { ItemMenu(item: item) }
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

            footer
        }
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            DispatchQueue.main.async { focused = true }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            TextField("", text: $query, prompt: Text("szukaj").foregroundStyle(Theme.tertiary))
                .font(.minimal(30))
                .foregroundStyle(Theme.primary)
                .tint(Theme.primary)
                .focused($focused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .onSubmit(openBestMatch)

            Button("Gotowe") { close() }
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Theme.secondary)
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
            suggestion(icon: "globe", text: "Szukaj „\(trimmed)” w sieci")
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

    private func suggestion(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .light))
                .frame(width: 22)
            Text(text)
                .font(.minimal(19, weight: .regular))
                .lineLimit(1)
        }
        .foregroundStyle(Theme.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        HStack {
            Button {
                focused = false
                coordinator.sheet = .catalog
            } label: {
                Label("Twoje aplikacje", systemImage: "square.grid.2x2")
            }
            Spacer()
            Button {
                focused = false
                coordinator.sheet = .newItem(prefill: "")
            } label: {
                Label("Dodaj", systemImage: "plus")
            }
        }
        .labelStyle(.titleAndIcon)
        .font(.system(size: 15, weight: .regular))
        .foregroundStyle(Theme.tertiary)
        .buttonStyle(.dim)
        .padding(.horizontal, Theme.gutter)
        .padding(.vertical, 12)
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
