import SwiftUI

struct RootView: View {
    @EnvironmentObject private var coordinator: LaunchCoordinator
    @EnvironmentObject private var shield: ShieldModel
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(Pref.onboarded) private var onboarded = false
    @AppStorage(Pref.hideStatusBar) private var hideStatusBar = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            HomeView()
                .accessibilityHidden(coordinator.isSearching || coordinator.pausing != nil)

            if coordinator.isSearching {
                SearchView()
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom))
                    .accessibilityAddTraits(.isModal)
                    .zIndex(1)
            }

            if let item = coordinator.pausing {
                PauseView(item: item)
                    .id(item.id)
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.9), value: coordinator.isSearching)
        .animation(.easeInOut(duration: 0.25), value: coordinator.pausing?.id)
        .statusBarHidden(hideStatusBar && !coordinator.isSearching)
        .persistentSystemOverlays(hideStatusBar && !coordinator.isSearching ? .hidden : .automatic)
        .preferredColorScheme(.dark)
        .sheet(item: $coordinator.sheet) { sheet in
            sheetContent(sheet)
        }
        .fullScreenCover(isPresented: showOnboarding) {
            OnboardingView()
        }
        .alert("Nie udało się otworzyć", isPresented: showFailure, presenting: coordinator.failedItem) { item in
            Button("Edytuj") { coordinator.sheet = .editItem(item) }
            Button("OK", role: .cancel) {}
        } message: { item in
            Text(failureMessage(for: item))
        }
        #if DEBUG
        .task {
            // CI screenshots: `-debug.route search|shield|settings|debug-pause`
            if let route = UserDefaults.standard.string(forKey: "debug.route"),
               let url = URL(string: "\(SharedConfig.urlScheme)://\(route)") {
                try? await Task.sleep(for: .milliseconds(600))
                coordinator.handle(url)
            }
        }
        #endif
        .onChange(of: scenePhase, initial: true) { _, phase in
            coordinator.scenePhaseChanged(phase)
            if phase == .active {
                Task { await shield.refresh() }
            }
        }
        // Huge accessibility sizes would break the one-screen layouts; cap them everywhere,
        // including sheets and the welcome screens presented above.
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    @ViewBuilder
    private func sheetContent(_ sheet: LaunchCoordinator.Sheet) -> some View {
        switch sheet {
        case .settings:
            SettingsView()
        case .shield:
            NavigationStack { ShieldView(showsDone: true) }
                .minimalSheet()
        case .newItem(let prefill):
            NavigationStack { ItemEditorView(mode: .new(prefill: prefill)) }
                .minimalSheet()
        case .editItem(let item):
            NavigationStack { ItemEditorView(mode: .edit(item)) }
                .minimalSheet()
        case .favorites:
            NavigationStack { FavoritesEditorView() }
                .minimalSheet()
        case .catalog:
            NavigationStack { LibraryView() }
                .minimalSheet()
        }
    }

    private var showOnboarding: Binding<Bool> {
        Binding(get: { !onboarded }, set: { presented in if !presented { onboarded = true } })
    }

    private var showFailure: Binding<Bool> {
        Binding(get: { coordinator.failedItem != nil }, set: { presented in if !presented { coordinator.failedItem = nil } })
    }

    private func failureMessage(for item: LaunchItem) -> String {
        if case .shortcut(let shortcut) = item.target {
            return "Sprawdź, czy w aplikacji Skróty jest skrót o nazwie „\(shortcut)”. Nazwa musi się zgadzać co do znaku."
        }
        return "„\(item.name)” nie otwiera się — może nie jest zainstalowana albo jest ukryta. Stuknij „Edytuj” i wybierz „Skrót”: przez aplikację Skróty otworzysz każdą aplikację."
    }
}
