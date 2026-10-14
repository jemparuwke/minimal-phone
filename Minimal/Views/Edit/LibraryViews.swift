import SwiftUI

/// "Your apps": everything on the launcher, plus entry points to add more.
struct LibraryView: View {
    var showsDone = true

    @EnvironmentObject private var store: LauncherStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                NavigationLink {
                    FavoritesEditorView(showsDone: false)
                } label: {
                    LabeledContent {
                        Text("\(store.favorites.count)")
                    } label: {
                        Label("Ulubione", systemImage: "star")
                    }
                }
                NavigationLink {
                    CatalogView()
                } label: {
                    Label("Katalog aplikacji", systemImage: "square.grid.2x2")
                }
                NavigationLink {
                    ItemEditorView(mode: .new(prefill: ""), showsCancel: false)
                } label: {
                    Label("Dodaj skrót lub adres", systemImage: "plus")
                }
            }
            .minimalRow()

            Section {
                ForEach(store.sortedItems) { item in
                    NavigationLink {
                        ItemEditorView(mode: .edit(item), showsCancel: false)
                    } label: {
                        HStack {
                            Text(item.name)
                            Spacer()
                            if item.mindful {
                                Image(systemName: "wind")
                                    .foregroundStyle(Theme.tertiary)
                            }
                            if store.isFavorite(item) {
                                Image(systemName: "house")
                                    .foregroundStyle(Theme.tertiary)
                            }
                        }
                    }
                }
                .onDelete { offsets in
                    let sorted = store.sortedItems
                    offsets.map { sorted[$0] }.forEach(store.remove)
                }
            } header: {
                Text("Wszystkie · \(store.items.count)")
            }
            .minimalRow()
        }
        .navigationTitle("Twoje aplikacje")
        .toolbar {
            if showsDone {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gotowe") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

/// Reorder / pick the few words that live on the home screen.
struct FavoritesEditorView: View {
    var showsDone = true

    @EnvironmentObject private var store: LauncherStore
    @Environment(\.dismiss) private var dismiss

    private var others: [LaunchItem] {
        store.sortedItems.filter { !store.isFavorite($0) }
    }

    var body: some View {
        List {
            Section {
                if store.favorites.isEmpty {
                    Text("Pusto. Dodaj coś poniżej.")
                        .foregroundStyle(Theme.tertiary)
                }
                ForEach(store.favorites) { item in
                    Text(item.name)
                }
                .onMove { source, destination in store.moveFavorites(from: source, to: destination) }
                .onDelete { offsets in store.removeFavorites(at: offsets) }
            } header: {
                Text("Ulubione")
            } footer: {
                Text("Maksymalnie \(LauncherStore.maxFavorites). Mniej znaczy spokojniej.")
            }
            .minimalRow()

            Section("Dodaj") {
                ForEach(others) { item in
                    Button {
                        withAnimation { store.setFavorite(item, true) }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .minimalFont(20, weight: .regular)
                                .foregroundStyle(store.canAddFavorite ? Theme.good : Theme.tertiary)
                            Text(item.name)
                                .foregroundStyle(store.canAddFavorite ? Theme.primary : Theme.tertiary)
                        }
                    }
                    .disabled(!store.canAddFavorite)
                }
            }
            .minimalRow()
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("Ulubione")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsDone {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gotowe") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

/// Check the apps you have. Ready-made links for popular apps.
struct CatalogView: View {
    @EnvironmentObject private var store: LauncherStore
    @State private var query = ""

    var body: some View {
        List {
            ForEach(CatalogApp.Kind.allCases) { group in
                let apps = AppCatalog.search(query, kind: group)
                if !apps.isEmpty {
                    Section(group.title) {
                        ForEach(apps) { app in
                            CatalogRow(app: app)
                        }
                    }
                    .minimalRow()
                }
            }

            Section {
                EmptyView()
            } footer: {
                Text("Nie ma Twojej aplikacji? Dodaj ją przez „Dodaj skrót lub adres” — skrót z aplikacji Skróty otworzy każdą aplikację.")
            }
        }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Szukaj")
        .navigationTitle("Katalog")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CatalogRow: View {
    let app: CatalogApp
    @EnvironmentObject private var store: LauncherStore

    var body: some View {
        let included = store.item(forCatalogID: app.id) != nil
        Button {
            withAnimation(.snappy) { store.setCatalogApp(app, included: !included) }
        } label: {
            HStack {
                Text(app.name)
                    .foregroundStyle(Theme.primary)
                Spacer()
                Image(systemName: included ? "checkmark.circle.fill" : "circle")
                    .minimalFont(21, weight: .regular)
                    .foregroundStyle(included ? Theme.primary : Theme.tertiary)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .sensoryFeedback(.selection, trigger: included)
    }
}
