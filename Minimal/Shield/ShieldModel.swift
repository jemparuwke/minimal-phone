import FamilyControls
import Foundation
import ManagedSettings
import NetworkExtension
import SwiftUI

/// The porn shield. Three independent layers, each covering the others' gaps:
///
/// 1. **Web filter** – Apple's own adult-website filter (Screen Time API). Works in Safari,
///    every WebKit browser and in-app web views; also turns off private browsing.
/// 2. **DNS filter** – encrypted family DNS for the whole phone, every app.
/// 3. **Blocked apps** – apps or categories the user chooses (e.g. X, Reddit, Telegram).
///
/// Plus a commitment lock: weakening the shield requires waiting out a delay first.
@MainActor
final class ShieldModel: ObservableObject {
    enum LockDelay: Int, CaseIterable, Identifiable {
        case none = 0
        case oneHour = 3_600
        case oneDay = 86_400
        case threeDays = 259_200
        case week = 604_800

        var id: Int { rawValue }

        var label: String {
            switch self {
            case .none: return "Brak"
            case .oneHour: return "1 godzina"
            case .oneDay: return "24 godziny"
            case .threeDays: return "3 dni"
            case .week: return "7 dni"
            }
        }

        /// "odczekaj 1 godzinę / 24 godziny / 3 dni"
        var waitLabel: String {
            switch self {
            case .oneHour: return "1 godzinę"
            default: return label.lowercased()
            }
        }

        var interval: TimeInterval { TimeInterval(rawValue) }
    }

    enum LockState: Equatable {
        /// No delay configured – changes apply immediately.
        case off
        /// Locked; the user may request an unlock.
        case locked
        /// Unlock requested; waiting until `Date`.
        case waiting(until: Date)
        /// Delay elapsed; weakening allowed until `Date`.
        case open(until: Date)
    }

    /// After the delay passes, changes are allowed for this long before it locks again.
    static let unlockWindow: TimeInterval = 30 * 60

    // MARK: Published state

    @Published private(set) var authorization: AuthorizationStatus
    @Published private(set) var webFilterOn: Bool
    @Published private(set) var preventAppRemoval: Bool
    @Published private(set) var blockedSelection: FamilyActivitySelection

    @Published private(set) var dnsInstalled = false
    @Published private(set) var dnsEnabled = false
    @Published private(set) var dnsProvider: DNSProvider?

    @Published private(set) var lockDelay: LockDelay
    @Published private(set) var unlockRequestedAt: Date?

    @Published var message: String?
    @Published private(set) var isWorking = false

    /// Free edition: steps the user confirmed doing in iOS Settings (see `FreeStep`).
    @Published private(set) var freeStepsDone: Set<String>

    enum FreeStep: String, CaseIterable {
        case webFilter, dnsProfile, appLimits
    }

    let isFullEdition = Edition.isFull

    private lazy var managed = ManagedSettingsStore()
    private let defaults: UserDefaults
    /// The system reports `.notDetermined` after every launch until authorization is
    /// requested again (silently, once granted). We do that once per launch.
    private var didRestoreAuthorization = false

    private enum Key {
        static let webFilter = "shield.webFilter"
        static let preventRemoval = "shield.preventRemoval"
        static let selection = "shield.selection"
        static let dnsProvider = "shield.dnsProvider"
        static let lockDelay = "shield.lockDelay"
        static let unlockRequestedAt = "shield.unlockRequestedAt"
        static let everAuthorized = "shield.everAuthorized"
        static let freeSteps = "shield.freeSteps"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        authorization = .notDetermined
        webFilterOn = defaults.bool(forKey: Key.webFilter)
        preventAppRemoval = defaults.bool(forKey: Key.preventRemoval)
        blockedSelection = defaults.data(forKey: Key.selection)
            .flatMap { try? JSONDecoder().decode(FamilyActivitySelection.self, from: $0) }
            ?? FamilyActivitySelection()
        dnsProvider = defaults.string(forKey: Key.dnsProvider).flatMap(DNSProvider.init(rawValue:))
        lockDelay = LockDelay(rawValue: defaults.integer(forKey: Key.lockDelay)) ?? .none
        let requested = defaults.double(forKey: Key.unlockRequestedAt)
        unlockRequestedAt = requested > 0 ? Date(timeIntervalSince1970: requested) : nil
        freeStepsDone = Set(defaults.stringArray(forKey: Key.freeSteps) ?? [])
        scheduleLockRefresh()
        if isFullEdition {
            authorization = AuthorizationCenter.shared.authorizationStatus
        }
    }

    // MARK: - Summary

    var isAuthorized: Bool {
        switch authorization {
        case .approved: return true
        case .notDetermined, .denied: return false
        default: return true // .approvedWithDataAccess (iOS 26.4+)
        }
    }

    var webFilterActive: Bool { webFilterOn && isAuthorized }

    var blockedCount: Int {
        blockedSelection.applicationTokens.count
            + blockedSelection.categoryTokens.count
            + blockedSelection.webDomainTokens.count
    }

    var blockedAppsActive: Bool { blockedCount > 0 && isAuthorized }

    var isProtecting: Bool {
        if isFullEdition { return webFilterActive || dnsEnabled }
        return isFreeStepDone(.webFilter) || isFreeStepDone(.dnsProfile)
    }

    var activeLayers: Int {
        if !isFullEdition { return freeStepsDone.count }
        return [webFilterActive, dnsEnabled, blockedAppsActive].filter { $0 }.count
    }

    func isFreeStepDone(_ step: FreeStep) -> Bool {
        freeStepsDone.contains(step.rawValue)
    }

    func setFreeStep(_ step: FreeStep, done: Bool) {
        if done {
            freeStepsDone.insert(step.rawValue)
        } else {
            freeStepsDone.remove(step.rawValue)
        }
        defaults.set(Array(freeStepsDone), forKey: Key.freeSteps)
    }

    // MARK: - Refresh

    func refresh() async {
        guard isFullEdition else { return }
        authorization = AuthorizationCenter.shared.authorizationStatus
        if !isAuthorized, !didRestoreAuthorization, defaults.bool(forKey: Key.everAuthorized) {
            // Already approved earlier: this returns without any prompt and restores the status.
            didRestoreAuthorization = true
            try? await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorization = AuthorizationCenter.shared.authorizationStatus
            // Access was revoked in Settings: stop asking on every launch.
            if !isAuthorized { defaults.set(false, forKey: Key.everAuthorized) }
        }
        if isAuthorized { applyManagedSettings() }
        await refreshDNS()
    }

    // MARK: - Layer 1: Apple web filter

    func enableWebFilter() async {
        guard await ensureAuthorized() else { return }
        webFilterOn = true
        defaults.set(true, forKey: Key.webFilter)
        applyManagedSettings()
    }

    func disableWebFilter() {
        guard requireUnlocked() else { return }
        webFilterOn = false
        defaults.set(false, forKey: Key.webFilter)
        applyManagedSettings()
    }

    // MARK: - Layer 3: blocked apps

    /// Applies a new picker selection. Adding is always allowed; removing needs the lock open.
    /// Returns the selection that is actually in force.
    @discardableResult
    func updateBlocked(_ selection: FamilyActivitySelection) async -> FamilyActivitySelection {
        let old = blockedSelection
        let removesSomething =
            !selection.applicationTokens.isSuperset(of: old.applicationTokens)
            || !selection.categoryTokens.isSuperset(of: old.categoryTokens)
            || !selection.webDomainTokens.isSuperset(of: old.webDomainTokens)
        if removesSomething, !requireUnlocked() { return old }
        guard await ensureAuthorized() else { return old }
        blockedSelection = selection
        if let data = try? JSONEncoder().encode(selection) {
            defaults.set(data, forKey: Key.selection)
        }
        applyManagedSettings()
        return selection
    }

    // MARK: - Strict mode

    func setPreventAppRemoval(_ enabled: Bool) async {
        if !enabled, !requireUnlocked() { return }
        if enabled, !(await ensureAuthorized()) { return }
        preventAppRemoval = enabled
        defaults.set(enabled, forKey: Key.preventRemoval)
        applyManagedSettings()
    }

    // MARK: - Layer 2: DNS

    func installDNS(_ provider: DNSProvider) async {
        if let current = dnsProvider, dnsInstalled, provider.strictness < current.strictness, !requireUnlocked() {
            return
        }
        isWorking = true
        defer { isWorking = false }
        let manager = NEDNSSettingsManager.shared()
        do {
            try await manager.loadFromPreferences()
            manager.dnsSettings = provider.makeSettings()
            manager.localizedDescription = "Minimal"
            manager.onDemandRules = [NEOnDemandRuleConnect()]
            try await manager.saveToPreferences()
            dnsProvider = provider
            defaults.set(provider.rawValue, forKey: Key.dnsProvider)
        } catch {
            message = "Nie udało się zainstalować filtra DNS. \(error.localizedDescription)"
        }
        await refreshDNS()
    }

    func removeDNS() async {
        guard requireUnlocked() else { return }
        isWorking = true
        defer { isWorking = false }
        let manager = NEDNSSettingsManager.shared()
        do {
            try await manager.loadFromPreferences()
            try await manager.removeFromPreferences()
            dnsProvider = nil
            defaults.removeObject(forKey: Key.dnsProvider)
        } catch {
            message = "Nie udało się usunąć filtra DNS. \(error.localizedDescription)"
        }
        await refreshDNS()
    }

    private func refreshDNS() async {
        let manager = NEDNSSettingsManager.shared()
        do {
            try await manager.loadFromPreferences()
            dnsInstalled = manager.dnsSettings != nil
            dnsEnabled = dnsInstalled && manager.isEnabled
        } catch {
            dnsInstalled = false
            dnsEnabled = false
        }
    }

    // MARK: - Commitment lock

    func lockState(at now: Date = Date()) -> LockState {
        guard lockDelay != .none else { return .off }
        guard let requested = unlockRequestedAt else { return .locked }
        let opensAt = requested.addingTimeInterval(lockDelay.interval)
        let closesAt = opensAt.addingTimeInterval(Self.unlockWindow)
        if now < opensAt { return .waiting(until: opensAt) }
        if now < closesAt { return .open(until: closesAt) }
        return .locked
    }

    var canWeaken: Bool {
        switch lockState() {
        case .off, .open: return true
        case .locked, .waiting: return false
        }
    }

    func requestUnlock() {
        unlockRequestedAt = Date()
        defaults.set(Date().timeIntervalSince1970, forKey: Key.unlockRequestedAt)
        scheduleLockRefresh()
    }

    func relock() {
        unlockRequestedAt = nil
        defaults.removeObject(forKey: Key.unlockRequestedAt)
        scheduleLockRefresh()
    }

    private var lockRefreshTask: Task<Void, Never>?

    /// Re-renders the UI the moment the lock opens or closes again, so buttons that depend
    /// on `canWeaken` never show a stale state.
    private func scheduleLockRefresh() {
        lockRefreshTask?.cancel()
        let next: Date?
        switch lockState() {
        case .waiting(let until), .open(let until): next = until
        case .off, .locked: next = nil
        }
        guard let next else { return }
        lockRefreshTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(max(1, next.timeIntervalSinceNow + 0.5)))
            guard !Task.isCancelled, let self else { return }
            self.objectWillChange.send()
            if case .locked = self.lockState() { self.relock() } else { self.scheduleLockRefresh() }
        }
    }

    /// Making the delay longer is always allowed; shorter needs the lock open.
    func setLockDelay(_ delay: LockDelay) {
        guard delay != lockDelay else { return }
        if delay.rawValue < lockDelay.rawValue, !requireUnlocked() { return }
        lockDelay = delay
        defaults.set(delay.rawValue, forKey: Key.lockDelay)
        // Any change starts from a locked state: an old unlock request never carries over.
        relock()
        if isAuthorized { applyManagedSettings() }
    }

    // MARK: - Private

    private func requireUnlocked() -> Bool {
        if canWeaken { return true }
        if case .waiting(let until) = lockState() {
            message = "Tarcza odblokuje się za \(Formatters.duration(until.timeIntervalSinceNow)). Wtedy przez 30 minut możesz ją osłabić."
        } else {
            message = "Tarcza jest zablokowana. Poproś o odblokowanie w sekcji „Zobowiązanie” i odczekaj \(lockDelay.waitLabel)."
        }
        return false
    }

    private func ensureAuthorized() async -> Bool {
        if isAuthorized { return true }
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch let error as FamilyControlsError {
            message = Self.describe(error)
        } catch {
            message = "Nie udało się uzyskać dostępu do Czasu przed ekranem. Spróbuj ponownie."
        }
        authorization = AuthorizationCenter.shared.authorizationStatus
        if isAuthorized {
            didRestoreAuthorization = true
            defaults.set(true, forKey: Key.everAuthorized)
        }
        return isAuthorized
    }

    private static func describe(_ error: FamilyControlsError) -> String? {
        switch error {
        case .authorizationCanceled:
            return nil
        case .authenticationMethodUnavailable:
            return "Ten krok wymaga kodu blokady iPhone’a. Ustaw go w Ustawieniach, a potem spróbuj ponownie."
        case .restricted:
            return "Czas przed ekranem jest zablokowany na tym urządzeniu (np. przez zarządzanie rodzinne lub MDM)."
        case .networkError:
            return "Brak połączenia z internetem. Spróbuj ponownie za chwilę."
        case .invalidAccountType:
            return "To konto nie może używać Czasu przed ekranem dla siebie. Zaloguj się na konto Apple osoby dorosłej."
        case .unavailable:
            return "Czas przed ekranem jest teraz niedostępny. Upewnij się, że jest włączony w Ustawieniach."
        default:
            return "Nie udało się uzyskać dostępu do Czasu przed ekranem. Spróbuj ponownie."
        }
    }

    private func applyManagedSettings() {
        guard isAuthorized else { return }

        managed.webContent.blockedByFilter = webFilterOn ? .auto(BlockedDomains.domains) : nil
        managed.media.denyBookstoreErotica = webFilterOn ? true : nil
        managed.application.denyAppRemoval = preventAppRemoval ? true : nil
        // With a commitment delay, the clock cannot be moved forward to skip the wait.
        managed.dateAndTime.requireAutomaticDateAndTime = lockDelay != .none ? true : nil

        let apps = blockedSelection.applicationTokens
        let categories = blockedSelection.categoryTokens
        let domains = blockedSelection.webDomainTokens
        managed.shield.applications = apps.isEmpty ? nil : apps
        managed.shield.applicationCategories = categories.isEmpty ? nil : .specific(categories)
        managed.shield.webDomains = domains.isEmpty ? nil : domains
        managed.shield.webDomainCategories = categories.isEmpty ? nil : .specific(categories)
    }
}
