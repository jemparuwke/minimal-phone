import SwiftUI

/// One step of a guide: what to do, and where in iOS Settings to do it.
struct GuideStep: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let text: String
    var path: String? = nil
}

/// How to turn an iPhone into a calm, minimal phone around Minimal.
struct SetupGuideView: View {
    private let homeScreen: [GuideStep] = [
        GuideStep(icon: "square.text.square", title: "Widżet Minimal",
                  text: "Przytrzymaj puste miejsce na ekranie początkowym → Edytuj → Dodaj widżet → Minimal → „Ulubione” w dużym rozmiarze."),
        GuideStep(icon: "rectangle.stack", title: "Jedna strona",
                  text: "Przenieś pozostałe aplikacje do biblioteki aplikacji (przytrzymaj ikonę → Usuń aplikację → Usuń z ekranu początkowego). Potem w trybie edycji stuknij kropki stron i odznacz zbędne."),
        GuideStep(icon: "dock.rectangle", title: "Dock",
                  text: "Zostaw w Docku tylko Minimal. Wyszukiwanie każdej aplikacji to jedno stuknięcie."),
        GuideStep(icon: "tray.and.arrow.down", title: "Nowe aplikacje do biblioteki",
                  text: "Nowo pobrane aplikacje nie pojawią się na ekranie początkowym.",
                  path: "Ustawienia → Ekran początkowy i biblioteka aplikacji → Tylko biblioteka aplikacji"),
        GuideStep(icon: "app.badge", title: "Bez czerwonych kropek",
                  text: "Wyłącz plakietki — liczniki powiadomień to najsilniejszy wabik.",
                  path: "Ustawienia → Ekran początkowy i biblioteka aplikacji → Plakietki powiadomień"),
    ]

    private let calm: [GuideStep] = [
        GuideStep(icon: "circle.lefthalf.filled", title: "Czarna tapeta",
                  text: "Dodaj nową tapetę w kolorze czarnym — na ekranie blokady i początkowym.",
                  path: "Ustawienia → Tapeta → Dodaj nową tapetę → Kolor"),
        GuideStep(icon: "camera.filters", title: "Skala szarości jednym gestem",
                  text: "Szary ekran jest zaskakująco nudny — i o to chodzi. Ustaw skrót: trzykrotne kliknięcie bocznego przycisku włącza i wyłącza szarość.",
                  path: "Ustawienia → Dostępność → Ekran i wielkość tekstu → Filtry kolorów → Skala szarości, potem Dostępność → Skrót dostępności → Filtry kolorów"),
        GuideStep(icon: "moon", title: "Skupienie",
                  text: "Utwórz tryb Skupienia, który przepuszcza tylko ważne osoby i aplikacje. Możesz go włączać automatycznie o stałych porach.",
                  path: "Ustawienia → Skupienie"),
        GuideStep(icon: "bell.badge", title: "Podsumowanie powiadomień",
                  text: "Zbierz mniej pilne powiadomienia w jedno lub dwa podsumowania dziennie.",
                  path: "Ustawienia → Powiadomienia → Zaplanowane podsumowanie"),
        GuideStep(icon: "wind", title: "Pauza dla pożeraczy czasu",
                  text: "W Minimal przytrzymaj nazwę aplikacji i wybierz „Pauza przed otwarciem”. Kilka sekund wystarczy, by impuls minął."),
    ]

    var body: some View {
        List {
            GuideSection(title: "Ekran początkowy", steps: homeScreen)
            GuideSection(title: "Spokój", steps: calm)
        }
        .navigationTitle("Przewodnik")
        .navigationBarTitleDisplayMode(.inline)
        .minimalSheet()
    }
}

/// iOS settings that close the remaining gaps around the shield.
struct ShieldGuideView: View {
    private let steps: [GuideStep] = [
        GuideStep(icon: "hourglass", title: "Kod Czasu przed ekranem u zaufanej osoby",
                  text: "Włącz Czas przed ekranem i ustaw kod, który wpisze ktoś zaufany — nie Ty. Bez tego kodu nie da się wyłączyć filtrów.",
                  path: "Ustawienia → Czas przed ekranem → Zablokuj ustawienia Czasu przed ekranem"),
        GuideStep(icon: "nosign", title: "Ogranicz strony dla dorosłych",
                  text: "Ten sam filtr Apple co warstwa 1 tarczy — ale chroniony kodem zaufanej osoby.",
                  path: "Ustawienia → Czas przed ekranem → Ograniczenia zawartości i prywatności → Ograniczenia zawartości → Zawartość internetowa → Ogranicz strony dla dorosłych"),
        GuideStep(icon: "person.badge.key", title: "Zablokuj zmiany kodu i konta",
                  text: "Uniemożliwia obejście ograniczeń przez zmianę kodu lub konta Apple.",
                  path: "Ograniczenia zawartości i prywatności → Zmiany kodu: Nie zezwalaj, Zmiany konta: Nie zezwalaj"),
        GuideStep(icon: "eye.slash", title: "Ostrzeżenie o wrażliwej zawartości",
                  text: "iPhone rozmywa nagie zdjęcia i wideo w Wiadomościach, AirDropie, FaceTimie i części aplikacji, zanim je zobaczysz.",
                  path: "Ustawienia → Prywatność i ochrona → Ostrzeżenie o wrażliwej zawartości"),
        GuideStep(icon: "network.badge.shield.half.filled", title: "Uważaj na VPN-y",
                  text: "Aplikacje VPN i proxy mogą ominąć filtr DNS. Nie instaluj ich — a jeśli chcesz mieć pewność, zablokuj kategorię w warstwie 3 tarczy."),
        GuideStep(icon: "icloud", title: "Prywatny przekaźnik iCloud",
                  text: "Jeśli masz iCloud+, Prywatny przekaźnik może w Safari omijać filtr DNS. Filtr Apple (warstwa 1) nadal działa, ale dla pełnej ochrony wyłącz przekaźnik.",
                  path: "Ustawienia → [Twoje imię] → iCloud → Prywatny przekaźnik"),
    ]

    var body: some View {
        List {
            Section {
                Text("Tarcza Minimal działa sama. Te ustawienia iOS sprawiają, że trudno ją wyłączyć w chwili słabości.")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.secondary)
                    .listRowBackground(Color.clear)
            }
            GuideSection(title: "Krok po kroku", steps: steps)
        }
        .navigationTitle("Maksymalna ochrona")
        .navigationBarTitleDisplayMode(.inline)
        .minimalSheet()
    }
}

struct GuideSection: View {
    let title: String
    let steps: [GuideStep]

    var body: some View {
        Section(title) {
            ForEach(steps) { step in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: step.icon)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(Theme.primary)
                        .frame(width: 26)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(step.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.primary)
                        Text(step.text)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        if let path = step.path {
                            Text(path)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.tertiary)
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding(.vertical, 6)
                .accessibilityElement(children: .combine)
            }
        }
        .minimalRow()
    }
}
