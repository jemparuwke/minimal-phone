import FamilyControls
import SwiftUI

/// The porn shield: three layers + a commitment lock, explained in plain words.
struct ShieldView: View {
    var showsDone = false

    @EnvironmentObject private var shield: ShieldModel
    @Environment(\.dismiss) private var dismiss

    @State private var provider: DNSProvider = .recommended
    @State private var pickerSelection = FamilyActivitySelection()
    @State private var showPicker = false
    @State private var confirmUnlock = false
    @State private var pendingDelay: ShieldModel.LockDelay?
    @State private var confirmPreventRemoval = false

    var body: some View {
        List {
            hero
            if shield.isFullEdition {
                webFilterSection
                dnsSection
                blockedAppsSection
                commitmentSection
            } else {
                FreeShieldSections()
            }
            moreSection
        }
        .navigationTitle("Tarcza")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsDone {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gotowe") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .familyActivityPicker(isPresented: $showPicker, selection: $pickerSelection)
        .onChange(of: showPicker) { _, presented in
            guard !presented else { return }
            Task { pickerSelection = await shield.updateBlocked(pickerSelection) }
        }
        .confirmationDialog(
            "Każde osłabienie tarczy będzie wymagało odczekania \(pendingDelay?.waitLabel ?? ""). Skrócić ten czas można tylko po odczekaniu.",
            isPresented: pendingDelayBinding,
            titleVisibility: .visible
        ) {
            Button("Ustaw \(pendingDelay?.label.lowercased() ?? "")") {
                if let delay = pendingDelay { shield.setLockDelay(delay) }
                pendingDelay = nil
            }
        }
        .confirmationDialog(
            "Dopóki ta opcja jest włączona, nie usuniesz z iPhone’a żadnej aplikacji — także Minimal.",
            isPresented: $confirmPreventRemoval,
            titleVisibility: .visible
        ) {
            Button("Blokuj usuwanie aplikacji") {
                Task { await shield.setPreventAppRemoval(true) }
            }
        }
        .alert("Tarcza", isPresented: messageBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(shield.message ?? "")
        }
        .task {
            await shield.refresh()
            provider = shield.dnsProvider ?? .recommended
        }
        .minimalSheet()
    }

    // MARK: - Hero

    private var hero: some View {
        Section {
            VStack(spacing: 14) {
                Image(systemName: shield.isProtecting ? "checkmark.shield.fill" : "shield.slash")
                    .minimalFont(60, weight: .light)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(shield.isProtecting ? Theme.good : Theme.warning)
                    .contentTransition(.symbolEffect(.replace))
                    .padding(.bottom, 2)
                Text(heroTitle)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(Theme.primary)
                Text(heroSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(index < shield.activeLayers ? Theme.good : Theme.hairline)
                            .frame(width: 28, height: 4)
                    }
                }
                .padding(.top, 4)
                .accessibilityElement()
                .accessibilityLabel("Aktywne warstwy: \(shield.activeLayers) z 3")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .listRowBackground(Color.clear)
    }

    private var heroTitle: String {
        if !shield.isFullEdition { return "Tarcza: \(shield.activeLayers) z 3 kroków" }
        return shield.isProtecting ? "Tarcza włączona" : "Tarcza wyłączona"
    }

    private var heroSubtitle: String {
        if !shield.isFullEdition {
            return "Minimal nie widzi ustawień iOS, więc zaznacz każdy krok, gdy go wykonasz."
        }
        switch shield.activeLayers {
        case 3: return "Wszystkie trzy warstwy działają. Porno jest zablokowane w całym telefonie."
        case 0: return "Włącz warstwy poniżej. Każda zamyka inną furtkę."
        default: return "Aktywne warstwy: \(shield.activeLayers) z 3. Włącz pozostałe, by zamknąć wszystkie furtki."
        }
    }

    // MARK: - Layer 1

    private var webFilterSection: some View {
        Section {
            LayerHeader(number: 1,
                        title: "Filtr stron dla dorosłych",
                        detail: "Wbudowany filtr Apple. Blokuje strony dla dorosłych w Safari, innych przeglądarkach i aplikacjach oraz wyłącza przeglądanie prywatne.",
                        isActive: shield.webFilterActive)
            if shield.webFilterActive {
                weakenButton("Wyłącz filtr") { shield.disableWebFilter() }
            } else {
                Button {
                    Task { await shield.enableWebFilter() }
                } label: {
                    Text("Włącz filtr").fontWeight(.semibold)
                }
            }
        } footer: {
            Text("iOS poprosi o zgodę na dostęp do Czasu przed ekranem. Wszystko zostaje na Twoim iPhonie.")
        }
        .minimalRow()
    }

    // MARK: - Layer 2

    private var dnsSection: some View {
        Section {
            LayerHeader(number: 2,
                        title: "Filtr DNS dla całego telefonu",
                        detail: "Szyfrowany rodzinny DNS. Strony porno przestają się otwierać — w każdej aplikacji i przeglądarce.",
                        isActive: shield.dnsEnabled)

            if shield.dnsInstalled && !shield.dnsEnabled {
                ActivationSteps()
                Button {
                    SystemSettings.open()
                } label: {
                    Text("Otwórz Ustawienia").fontWeight(.semibold)
                }
            }

            Picker("Dostawca", selection: $provider) {
                ForEach(DNSProvider.allCases) { provider in
                    Text(provider.name).tag(provider)
                }
            }
            Text(provider.summary)
                .font(.footnote)
                .foregroundStyle(Theme.secondary)

            if !shield.dnsInstalled || shield.dnsProvider != provider {
                Button {
                    Task { await shield.installDNS(provider) }
                } label: {
                    HStack {
                        Text(shield.dnsInstalled ? "Zmień na \(provider.name)" : "Zainstaluj filtr DNS")
                            .fontWeight(.semibold)
                        if shield.isWorking {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(shield.isWorking)
            }

            if shield.dnsInstalled {
                weakenButton("Usuń filtr DNS") { Task { await shield.removeDNS() } }
            }
        } footer: {
            Text("Po instalacji włącz filtr w Ustawieniach: Ogólne → VPN i urządzenia zarządzane → DNS → Minimal. Włączona aplikacja VPN omija filtr DNS — filtr Apple (warstwa 1) działa nadal.")
        }
        .minimalRow()
    }

    // MARK: - Layer 3

    private var blockedAppsSection: some View {
        Section {
            LayerHeader(number: 3,
                        title: "Zablokowane aplikacje",
                        detail: "Zablokuj aplikacje, w których łatwo trafić na porno — np. X, Reddit, Telegram, Tumblr — albo całe kategorie.",
                        isActive: shield.blockedAppsActive)
            Button {
                pickerSelection = shield.blockedSelection
                showPicker = true
            } label: {
                LabeledContent {
                    Text(shield.blockedCount > 0 ? "\(shield.blockedCount)" : "Brak")
                        .foregroundStyle(Theme.secondary)
                } label: {
                    Text("Wybierz aplikacje").fontWeight(.semibold)
                }
            }
        }
        .minimalRow()
    }

    // MARK: - Commitment

    private var commitmentSection: some View {
        Section {
            Picker("Opóźnienie osłabienia", selection: lockDelayBinding) {
                ForEach(ShieldModel.LockDelay.allCases) { delay in
                    Text(delay.label).tag(delay)
                }
            }
            Toggle("Blokuj usuwanie aplikacji", isOn: preventRemovalBinding)
            TimelineView(.periodic(from: .now, by: 1)) { context in
                lockRow(shield.lockState(at: context.date))
            }
        } header: {
            Text("Zobowiązanie")
        } footer: {
            Text("Wyłączenie lub osłabienie warstw w Minimal wymaga odczekania wybranego czasu, a data i godzina iPhone’a muszą się wtedy ustawiać automatycznie. Impuls mija, decyzja zostaje. Ustawienia iOS nadal pozwalają wyłączyć filtry — dlatego kod Czasu przed ekranem warto oddać zaufanej osobie. „Blokuj usuwanie aplikacji” nie pozwala usunąć z iPhone’a żadnej aplikacji, także Minimal.")
        }
        .minimalRow()
    }

    @ViewBuilder
    private func lockRow(_ state: ShieldModel.LockState) -> some View {
        switch state {
        case .off:
            Label("Zmiany działają od razu", systemImage: "lock.open")
                .foregroundStyle(Theme.secondary)
        case .locked:
            Button {
                confirmUnlock = true
            } label: {
                Label("Poproś o odblokowanie", systemImage: "lock")
            }
            .confirmationDialog("Odblokowanie nastąpi za \(shield.lockDelay.waitLabel). Potem przez 30 minut możesz osłabić tarczę.",
                                isPresented: $confirmUnlock, titleVisibility: .visible) {
                Button("Rozpocznij odliczanie") { shield.requestUnlock() }
            }
        case .waiting(let until):
            HStack {
                Label("Odblokowanie za \(Formatters.duration(until.timeIntervalSinceNow))", systemImage: "hourglass")
                    .foregroundStyle(Theme.warning)
                    .monospacedDigit()
                Spacer()
                Button("Anuluj") { shield.relock() }
                    .buttonStyle(.borderless)
            }
        case .open(let until):
            HStack {
                Label("Odblokowane jeszcze \(Formatters.duration(until.timeIntervalSinceNow))", systemImage: "lock.open")
                    .foregroundStyle(Theme.good)
                    .monospacedDigit()
                Spacer()
                Button("Zablokuj") { shield.relock() }
                    .buttonStyle(.borderless)
            }
        }
    }

    // MARK: - Confirmations

    private var pendingDelayBinding: Binding<Bool> {
        Binding(get: { pendingDelay != nil }, set: { if !$0 { pendingDelay = nil } })
    }

    // MARK: - More

    private var moreSection: some View {
        Section {
            NavigationLink {
                ShieldGuideView()
            } label: {
                Label("Maksymalna ochrona", systemImage: "lock.shield")
            }
        } footer: {
            Text("Kilka ustawień iOS, które domykają tarczę — np. kod Czasu przed ekranem u zaufanej osoby.")
        }
        .minimalRow()
    }

    // MARK: - Helpers

    /// A destructive button that is replaced by a lock hint while the shield is locked.
    @ViewBuilder
    private func weakenButton(_ title: String, action: @escaping () -> Void) -> some View {
        if shield.canWeaken {
            Button(title, role: .destructive, action: action)
        } else {
            Label("\(title) — zablokowane", systemImage: "lock")
                .foregroundStyle(Theme.tertiary)
        }
    }

    private var lockDelayBinding: Binding<ShieldModel.LockDelay> {
        Binding(get: { shield.lockDelay }, set: { delay in
            // Long commitments are easy to choose and hard to undo — confirm first.
            if delay.rawValue >= ShieldModel.LockDelay.oneDay.rawValue, delay.rawValue > shield.lockDelay.rawValue {
                pendingDelay = delay
            } else {
                shield.setLockDelay(delay)
            }
        })
    }

    private var preventRemovalBinding: Binding<Bool> {
        Binding(get: { shield.preventAppRemoval }, set: { value in
            if value {
                confirmPreventRemoval = true
            } else {
                Task { await shield.setPreventAppRemoval(false) }
            }
        })
    }

    private var messageBinding: Binding<Bool> {
        Binding(get: { shield.message != nil }, set: { if !$0 { shield.message = nil } })
    }
}

/// Header row of one shield layer: number, title, explanation and live status.
struct LayerHeader: View {
    let number: Int
    let title: String
    let detail: String
    let isActive: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(isActive ? Theme.good.opacity(0.18) : Theme.surface)
                if isActive {
                    Image(systemName: "checkmark")
                        .minimalFont(13, weight: .bold)
                        .foregroundStyle(Theme.good)
                } else {
                    Text("\(number)")
                        .font(.subheadline.weight(.semibold)).fontDesign(.rounded)
                        .foregroundStyle(Theme.secondary)
                }
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Theme.primary)
                    Spacer(minLength: 8)
                    Text(isActive ? "Aktywna" : "Wyłączona")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(isActive ? Theme.good : Theme.tertiary)
                }
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

/// Numbered steps for switching on the installed DNS filter in iOS Settings.
struct ActivationSteps: View {
    private let steps = [
        "Otwórz Ustawienia → Ogólne.",
        "Stuknij VPN i urządzenia zarządzane → DNS.",
        "Wybierz „Minimal”.",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ostatni krok — włącz w Ustawieniach")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.warning)
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(index + 1).")
                        .font(.subheadline.weight(.semibold)).fontDesign(.rounded)
                        .foregroundStyle(Theme.secondary)
                        .frame(width: 18, alignment: .trailing)
                    Text(step)
                        .font(.subheadline)
                        .foregroundStyle(Theme.primary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

enum SystemSettings {
    /// Opens the Settings app at its root. Falls back to this app's own settings page.
    static func open() {
        let candidates = ["prefs:", "App-prefs:", UIApplication.openSettingsURLString].compactMap(URL.init(string:))
        Task { @MainActor in
            for url in candidates {
                if await UIApplication.shared.open(url) { return }
            }
        }
    }
}
