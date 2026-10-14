import SwiftUI

@main
struct MinimalApp: App {
    @StateObject private var store: LauncherStore
    @StateObject private var stats: UsageStats
    @StateObject private var coordinator: LaunchCoordinator
    @StateObject private var shield: ShieldModel

    init() {
        let store = LauncherStore()
        let stats = UsageStats()
        _store = StateObject(wrappedValue: store)
        _stats = StateObject(wrappedValue: stats)
        // Created eagerly so App Intents find it even on a cold launch.
        let coordinator = LaunchCoordinator(store: store, stats: stats)
        _coordinator = StateObject(wrappedValue: coordinator)
        _shield = StateObject(wrappedValue: ShieldModel())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(stats)
                .environmentObject(coordinator)
                .environmentObject(shield)
                .onOpenURL { url in coordinator.handle(url) }
        }
    }
}
