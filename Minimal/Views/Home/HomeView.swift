import SwiftUI

/// The calm home screen: time, a handful of words, nothing else.
struct HomeView: View {
    @EnvironmentObject private var store: LauncherStore
    @EnvironmentObject private var stats: UsageStats
    @EnvironmentObject private var coordinator: LaunchCoordinator
    @EnvironmentObject private var shield: ShieldModel
    @AppStorage(Pref.textScale) private var textScale: TextScale = .medium

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ClockView()
                .padding(.top, 28)

            Spacer(minLength: 28)

            favorites

            Spacer(minLength: 28)

            footer
        }
        .padding(.horizontal, Theme.gutter)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.background.ignoresSafeArea())
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    let vertical = value.translation.height
                    if vertical < -60, abs(value.translation.width) < abs(vertical) {
                        coordinator.isSearching = true
                    }
                }
        )
    }

    // MARK: - Favorites

    private var favorites: some View {
        VStack(alignment: .leading, spacing: textScale.itemSize * 0.22) {
            if store.favorites.isEmpty {
                Button {
                    coordinator.sheet = .favorites
                } label: {
                    Text("dodaj ulubione")
                        .minimalFont(textScale.itemSize)
                        .foregroundStyle(Theme.tertiary)
                }
                .buttonStyle(.dim)
            }

            ForEach(store.favorites) { item in
                Button {
                    coordinator.launch(item)
                } label: {
                    ItemLabel(item: item, size: textScale.itemSize)
                }
                .buttonStyle(.dim)
                .contextMenu { ItemMenu(item: item) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(alignment: .leading, spacing: 18) {
            if stats.resistedToday > 0 {
                Text(resistedText)
                    .font(.footnote)
                    .foregroundStyle(Theme.tertiary)
                    .transition(.opacity)
            }

            HStack(alignment: .center, spacing: 0) {
                Button {
                    coordinator.isSearching = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .frame(width: 44, height: 44, alignment: .leading)
                }
                .accessibilityLabel("Szukaj")

                Spacer()

                Button {
                    coordinator.sheet = .shield
                } label: {
                    Image(systemName: shield.isProtecting ? "checkmark.shield" : "shield")
                        .foregroundStyle(shield.isProtecting ? Theme.secondary : Theme.warning)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(shield.isProtecting ? "Tarcza aktywna" : "Tarcza wyłączona")

                Spacer()

                Button {
                    coordinator.sheet = .settings
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 44, height: 44, alignment: .trailing)
                }
                .accessibilityLabel("Ustawienia")
            }
            .minimalFont(19, weight: .light)
            .foregroundStyle(Theme.secondary)
            .buttonStyle(.dim)
        }
    }

    private var resistedText: String {
        let count = stats.resistedToday
        return count == 1 ? "dziś odpuszczone 1 raz" : "dziś odpuszczone \(count) razy"
    }
}

/// Item name as shown on the home screen and in search.
struct ItemLabel: View {
    let item: LaunchItem
    let size: CGFloat
    var color: Color = Theme.primary

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(item.name.lowercased(with: Formatters.polish))
                .minimalFont(size)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(minHeight: 44, alignment: .leading)
            if item.mindful {
                Circle()
                    .fill(Theme.tertiary)
                    .frame(width: 5, height: 5)
                    .accessibilityLabel("z pauzą")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Long-press menu shared by home and search.
struct ItemMenu: View {
    let item: LaunchItem
    @EnvironmentObject private var store: LauncherStore
    @EnvironmentObject private var coordinator: LaunchCoordinator

    var body: some View {
        if store.isFavorite(item) {
            Button {
                store.setFavorite(item, false)
            } label: {
                Label("Usuń z ulubionych", systemImage: "minus.circle")
            }
        } else {
            Button {
                store.setFavorite(item, true)
            } label: {
                Label("Dodaj do ulubionych", systemImage: "plus.circle")
            }
            .disabled(!store.canAddFavorite)
        }

        Button {
            var updated = item
            updated.mindful.toggle()
            store.update(updated)
        } label: {
            Label(item.mindful ? "Wyłącz pauzę" : "Pauza przed otwarciem", systemImage: "wind")
        }

        Button {
            coordinator.sheet = .editItem(item)
        } label: {
            Label("Edytuj", systemImage: "pencil")
        }

        Button {
            coordinator.sheet = .favorites
        } label: {
            Label("Ułóż ulubione", systemImage: "arrow.up.arrow.down")
        }
    }
}
