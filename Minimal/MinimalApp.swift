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
        _coordinator = StateObject(wrappedValue: LaunchCoordinator(store: store, stats: stats))
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
