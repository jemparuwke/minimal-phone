import SwiftUI

/// Add or edit one launcher item: a catalog app, a Shortcuts shortcut, or any URL.
struct ItemEditorView: View {
    enum Mode {
        case new(prefill: String)
        case edit(LaunchItem)
    }

    enum Kind: String, CaseIterable, Identifiable {
        case catalog, shortcut, url

        var id: String { rawValue }

        var label: String {
            switch self {
            case .catalog: return "Katalog"
            case .shortcut: return "Skrót"
            case .url: return "Adres"
            }
        }
    }

    let mode: Mode
    var showsCancel = true

    @EnvironmentObject private var store: LauncherStore
    @EnvironmentObject private var coordinator: LaunchCoordinator
    @Environment(\.dismiss) private var dismiss

    @State private var kind: Kind
    @State private var name: String
    @State private var shortcutName: String
    @State private var urlString: String
    @State private var mindful: Bool
    @State private var favorite = false
    @State private var catalogQuery: String
    @State private var confirmDelete = false

    init(mode: Mode, showsCancel: Bool = true) {
        self.mode = mode
        self.showsCancel = showsCancel
        switch mode {
        case .new(let prefill):
            let hasCatalogMatch = !prefill.isEmpty && !AppCatalog.search(prefill).isEmpty
            _kind = State(initialValue: prefill.isEmpty || hasCatalogMatch ? .catalog : .shortcut)
            _name = State(initialValue: prefill)
            _shortcutName = State(initialValue: prefill)
            _urlString = State(initialValue: "")
            _mindful = State(initialValue: false)
            _catalogQuery = State(initialValue: prefill)
        case .edit(let item):
            _name = State(initialValue: item.name)
            _mindful = State(initialValue: item.mindful)
            _catalogQuery = State(initialValue: "")
            switch item.target {
            case .shortcut(let shortcut):
                _kind = State(initialValue: .shortcut)
                _shortcutName = State(initialValue: shortcut)
                _urlString = State(initialValue: "")
            case .url(let url):
                _kind = State(initialValue: .url)
                _shortcutName = State(initialValue: "")
                _urlString = State(initialValue: url)
            }
        }
    }

    private var isNew: Bool {
        if case .new = mode { return true }
        return false
    }

    private var draftTarget: LaunchItem.Target {
        kind == .shortcut ? .shortcut(shortcutName.trimmed) : .url(urlString.trimmed)
    }

    private var draftURL: URL? {
        LaunchItem(name: name, target: draftTarget).url
    }

    private var resolvedName: String {
        if !name.trimmed.isEmpty { return name.trimmed }
        return kind == .shortcut ? shortcutName.trimmed : urlString.trimmed
    }

    private var isValid: Bool {
        kind != .catalog && draftURL != nil && !resolvedName.isEmpty
    }

    var body: some View {
        Form {
            if isNew {
                Section {
                    Picker("Rodzaj", selection: $kind) {
                        ForEach(Kind.allCases) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            switch kind {
            case .catalog:
                catalogSections
            case .shortcut:
                shortcutSections
                optionSections
            case .url:
                urlSections
                optionSections
            }

            if case .edit(let item) = mode {
                Section {
                    Button("Usuń „\(item.name)”", role: .destructive) { confirmDelete = true }
                }
                .minimalRow()
                .confirmationDialog("Usunąć „\(item.name)”?", isPresented: $confirmDelete, titleVisibility: .visible) {
                    Button("Usuń", role: .destructive) {
                        store.remove(item)
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle(isNew ? "Dodaj" : "Edytuj")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCancel {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { dismiss() }
                }
            }
            if kind != .catalog {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zapisz") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
        }
        .onAppear {
            if case .edit(let item) = mode { favorite = store.isFavorite(item) }
        }
    }

    // MARK: - Catalog

    @ViewBuilder
    private var catalogSections: some View {
        Section {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.tertiary)
                TextField("Szukaj w katalogu", text: $catalogQuery)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .minimalRow()

        ForEach(CatalogApp.Kind.allCases) { group in
            let apps = AppCatalog.search(catalogQuery, kind: group)
            if !apps.isEmpty {
                Section(group.title) {
                    ForEach(apps) { app in
                        let added = store.item(forCatalogID: app.id) != nil
                        Button {
                            store.add(app.makeItem())
                            dismiss()
                        } label: {
                            HStack {
                                Text(app.name)
                                    .foregroundStyle(added ? Theme.tertiary : Theme.primary)
                                Spacer()
                                if added {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.tertiary)
                                }
                            }
                        }
                        .disabled(added)
                    }
                }
                .minimalRow()
            }
        }

        Section {
            Button {
                withAnimation { kind = .shortcut }
            } label: {
                Label("Inna aplikacja — użyj skrótu", systemImage: "square.on.square")
            }
        } footer: {
            Text("Każdą aplikację z iPhone’a można dodać przez aplikację Skróty — nawet jeśli nie ma jej w katalogu.")
        }
        .minimalRow()
    }

    // MARK: - Shortcut

    @ViewBuilder
    private var shortcutSections: some View {
        Section {
            TextField("Nazwa na liście, np. Aparat", text: $name)
            TextField("Nazwa skrótu, np. Otwórz Aparat", text: $shortcutName)
                .autocorrectionDisabled()
        } header: {
            Text("Skrót")
        } footer: {
            Text("W aplikacji Skróty: ＋ → Dodaj czynność → „Otwórz aplikację” → wybierz aplikację → nazwij skrót dokładnie tak jak powyżej. Działa z każdą aplikacją.")
        }
        .minimalRow()

        Section {
            Button {
                if let url = URL(string: "shortcuts://create-shortcut") { coordinator.openURL(url) }
            } label: {
                Label("Otwórz Skróty", systemImage: "arrow.up.forward.app")
            }
        }
        .minimalRow()
    }

    // MARK: - URL

    @ViewBuilder
    private var urlSections: some View {
        Section {
            TextField("Nazwa", text: $name)
            TextField("np. spotify:// albo https://…", text: $urlString)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        } header: {
            Text("Adres")
        } footer: {
            Text("Schemat URL aplikacji albo dowolna strona internetowa.")
        }
        .minimalRow()
    }

    // MARK: - Options

    @ViewBuilder
    private var optionSections: some View {
        Section {
            Toggle("Na ekranie głównym", isOn: $favorite)
                .disabled(!favorite && !store.canAddFavorite && !isCurrentlyFavorite)
            Toggle("Pauza przed otwarciem", isOn: $mindful)
        } footer: {
            Text("Pauza to kilka sekund oddechu przed otwarciem. Idealna dla aplikacji, które kradną czas.")
        }
        .minimalRow()

        Section {
            Button {
                if let url = draftURL { coordinator.openURL(url) }
            } label: {
                Label("Wypróbuj", systemImage: "play")
            }
            .disabled(draftURL == nil)
        }
        .minimalRow()
    }

    private var isCurrentlyFavorite: Bool {
        if case .edit(let item) = mode { return store.isFavorite(item) }
        return false
    }

    private func save() {
        switch mode {
        case .new:
            store.add(LaunchItem(name: resolvedName, target: draftTarget, mindful: mindful), favorite: favorite)
        case .edit(let item):
            var updated = item
            if updated.target != draftTarget { updated.catalogID = nil }
            updated.name = resolvedName
            updated.target = draftTarget
            updated.mindful = mindful
            store.update(updated)
            store.setFavorite(updated, favorite)
        }
        dismiss()
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
