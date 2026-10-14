import SwiftUI

/// The shield for the Free edition (no paid developer account): the same three layers,
/// set up by hand in iOS Settings and with a bundled DNS profile. Each step can be ticked off.
struct FreeShieldSections: View {
    @EnvironmentObject private var shield: ShieldModel
    @State private var provider: DNSProvider = .recommended

    var body: some View {
        Section {
            LayerHeader(number: 1,
                        title: "Filtr stron dla dorosłych",
                        detail: "Wbudowany filtr Apple w Safari, innych przeglądarkach i aplikacjach.",
                        isActive: shield.isFreeStepDone(.webFilter))
            StepList(steps: [
                "Otwórz Ustawienia → Czas przed ekranem i włącz go.",
                "Ograniczaj treść i prywatność → włącz.",
                "App Store, multimedia, Internet i gry → Zawartość www → Blokuj witryny dla dorosłych.",
            ])
            Button {
                SystemSettings.open()
            } label: {
                Text("Otwórz Ustawienia").fontWeight(.semibold)
            }
            DoneToggle(step: .webFilter)
        }
        .minimalRow()

        Section {
            LayerHeader(number: 2,
                        title: "Filtr DNS dla całego telefonu",
                        detail: "Profil szyfrowanego, rodzinnego DNS. Blokuje porno w każdej aplikacji.",
                        isActive: shield.isFreeStepDone(.dnsProfile))
            Picker("Dostawca", selection: $provider) {
                ForEach(DNSProvider.allCases) { provider in
                    Text(provider.name).tag(provider)
                }
            }
            Text(provider.summary)
                .font(.footnote)
                .foregroundStyle(Theme.secondary)
            StepList(steps: [
                "Stuknij „Zapisz profil” i wybierz „Zapisz w Plikach”.",
                "Otwórz Pliki i stuknij zapisany profil.",
                "Ustawienia → Profil pobrany → Instaluj.",
            ])
            if let url = provider.profileURL {
                ShareLink(item: url, preview: SharePreview("Minimal · filtr DNS (\(provider.name))")) {
                    Label("Zapisz profil", systemImage: "square.and.arrow.down")
                        .fontWeight(.semibold)
                }
            }
            DoneToggle(step: .dnsProfile)
        } footer: {
            Text("Profil możesz też przesłać na iPhone’a AirDropem z folderu Profiles w projekcie.")
        }
        .minimalRow()

        Section {
            LayerHeader(number: 3,
                        title: "Blokada wybranych aplikacji",
                        detail: "Zablokuj aplikacje, w których łatwo trafić na porno — np. X, Reddit, Telegram.",
                        isActive: shield.isFreeStepDone(.appLimits))
            StepList(steps: [
                "Ustawienia → Czas przed ekranem → Limity aplikacji → Dodaj limit.",
                "Wybierz aplikacje i ustaw limit 1 minuty.",
                "Włącz „Blokuj po osiągnięciu limitu” (opcja pojawia się po ustawieniu kodu Czasu przed ekranem).",
            ])
            DoneToggle(step: .appLimits)
        } footer: {
            Text("Masz płatne konto Apple Developer? Ustaw MINIMAL_EDITION = Full w Config/Signing.xcconfig — wtedy tarcza włącza się jednym stuknięciem.")
        }
        .minimalRow()
    }
}

private struct StepList: View {
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(index + 1).")
                        .font(.subheadline.weight(.semibold)).fontDesign(.rounded)
                        .foregroundStyle(Theme.secondary)
                        .frame(width: 18, alignment: .trailing)
                    Text(step)
                        .font(.subheadline)
                        .foregroundStyle(Theme.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct DoneToggle: View {
    let step: ShieldModel.FreeStep
    @EnvironmentObject private var shield: ShieldModel

    var body: some View {
        Toggle("Zrobione", isOn: Binding(
            get: { shield.isFreeStepDone(step) },
            set: { shield.setFreeStep(step, done: $0) }
        ))
        .tint(Theme.good)
    }
}
