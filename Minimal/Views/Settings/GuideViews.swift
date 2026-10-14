import SwiftUI
import UIKit

/// One step of a guide: what to do, and where in iOS Settings to do it.
struct GuideStep: Identifiable {
    var id: String { title }
    let icon: String
    let title: String
    let text: String
    var path: String? = nil
    /// When the app can tell, whether the user already did this.
    var isDone: (() -> Bool)? = nil
}

/// How to turn an iPhone into a calm, minimal phone around Minimal.
struct SetupGuideView: View {
    private let homeScreen: [GuideStep] = [
        GuideStep(icon: "square.text.square", title: "Widżet Minimal",
                  text: "Przytrzymaj puste miejsce na ekranie głównym → Edytuj → Dodaj widżet → Minimal → „Ulubione” w dużym rozmiarze."),
        GuideStep(icon: "rectangle.stack", title: "Jedna strona",
                  text: "Przenieś pozostałe aplikacje do biblioteki aplikacji (przytrzymaj ikonę → Usuń aplikację → Usuń z ekranu głównego). Potem przytrzymaj ekran → Edytuj → Edycja stron i odznacz zbędne strony."),
        GuideStep(icon: "dock.rectangle", title: "Dock",
                  text: "Zostaw w Docku tylko Minimal. Wyszukiwanie każdej aplikacji to jedno stuknięcie."),
        GuideStep(icon: "tray.and.arrow.down", title: "Nowe aplikacje do biblioteki",
                  text: "Nowo pobrane aplikacje nie pojawią się na ekranie głównym.",
                  path: "Ustawienia → Ekran główny i biblioteka aplikacji → Tylko biblioteka aplikacji"),
        GuideStep(icon: "app.badge", title: "Bez czerwonych kropek",
                  text: "Liczniki powiadomień to najsilniejszy wabik. Wyłącz je w bibliotece aplikacji, a dla najbardziej natarczywych aplikacji także w ich powiadomieniach.",
                  path: "Ustawienia → Ekran główny i biblioteka aplikacji → Pokaż w bibliotece aplikacji (wyłącz), oraz Ustawienia → Powiadomienia → aplikacja → Plakietki"),
    ]

    private let calm: [GuideStep] = [
        GuideStep(icon: "circle.lefthalf.filled", title: "Czarna tapeta",
                  text: "Dodaj nową tapetę w czarnym kolorze — na ekranie blokady i ekranie głównym.",
                  path: "Ustawienia → Tapeta → Dodaj nową tapetę → Kolor"),
        GuideStep(icon: "camera.filters", title: "Skala szarości jednym gestem",
                  text: "Szary ekran jest zaskakująco nudny — i o to chodzi. Ustaw skrót: trzykrotne kliknięcie bocznego przycisku włącza i wyłącza szarość.",
                  path: "Ustawienia → Dostępność → Ekran i wielkość tekstu → Filtry barwne → Skala szarości, potem Dostępność → Skróty dostępności → Filtry barwne",
                  isDone: { UIAccessibility.isGrayscaleEnabled }),
        GuideStep(icon: "moon", title: "Tryb skupienia",
                  text: "Utwórz tryb skupienia, który przepuszcza tylko ważne osoby i aplikacje. Możesz go włączać automatycznie o stałych porach.",
                  path: "Ustawienia → Tryb skupienia"),
        GuideStep(icon: "bell.badge", title: "Podsumowanie powiadomień",
                  text: "Zbierz mniej pilne powiadomienia w zaplanowane podsumowanie — raz lub dwa razy dziennie.",
                  path: "Ustawienia → Powiadomienia"),
        GuideStep(icon: "wind", title: "Pauza dla pożeraczy czasu",
                  text: "W Minimal przytrzymaj nazwę aplikacji i wybierz „Pauza przed otwarciem”. Kilka sekund wystarczy, by impuls minął."),
    ]

    private let limits: [GuideStep] = [
        GuideStep(icon: "iphone", title: "Ekranu głównego nie da się podmienić",
                  text: "iOS nie pozwala żadnej aplikacji zastąpić ekranu głównego. Dlatego Minimal działa przez widżet, Dock i wyszukiwanie."),
        GuideStep(icon: "list.bullet", title: "Aplikacje nie widzą listy aplikacji",
                  text: "Minimal nie może sam odczytać, co masz zainstalowane. Zaznacz swoje aplikacje w katalogu, a resztę dodaj przez Skróty."),
        GuideStep(icon: "circle.lefthalf.filled", title: "Szarości nie włączy żadna aplikacja",
                  text: "Skalę szarości i bibliotekę aplikacji zmieniasz tylko w Ustawieniach — przewodnik powyżej prowadzi krok po kroku."),
    ]

    var body: some View {
        List {
            GuideSection(title: "Ekran główny iPhone’a", steps: homeScreen)
            GuideSection(title: "Spokój", steps: calm)
            GuideSection(title: "Czego iOS nie pozwala", steps: limits)
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
                  text: "Włącz Czas przed ekranem i ustaw kod, który wpisze ktoś zaufany — nie Ty. Gdy iPhone zaproponuje konto Apple do odzyskiwania kodu, pomiń ten krok. Bez kodu nie zmienisz ograniczeń zawartości ani nie wyłączysz Czasu przed ekranem, a od iOS 26.4 nie odbierzesz też Minimal dostępu do niego.",
                  path: "Ustawienia → Czas przed ekranem → Zablokuj ustawienia Czasu przed ekranem"),
        GuideStep(icon: "nosign", title: "Blokuj witryny dla dorosłych",
                  text: "Ten sam filtr Apple co warstwa 1 tarczy — ale chroniony kodem zaufanej osoby.",
                  path: "Ustawienia → Czas przed ekranem → Ograniczaj treść i prywatność → App Store, multimedia, Internet i gry → Zawartość www → Blokuj witryny dla dorosłych"),
        GuideStep(icon: "person.badge.key", title: "Zablokuj zmiany kodu i konta",
                  text: "Uniemożliwia obejście ograniczeń przez zmianę kodu lub konta Apple.",
                  path: "Ograniczaj treść i prywatność → Zmiany kodu: Nie pozwalaj, Zmiany danych konta: Nie pozwalaj"),
        GuideStep(icon: "eye.slash", title: "Ostrzeżenia o treściach wymagających dyskrecji",
                  text: "iPhone rozmywa nagie zdjęcia i wideo w Wiadomościach, AirDropie, FaceTimie i części aplikacji, zanim je zobaczysz.",
                  path: "Ustawienia → Prywatność i ochrona → Ostrzeżenia dotyczące treści wymagających dyskrecji"),
        GuideStep(icon: "icloud", title: "Przekazywanie prywatne iCloud",
                  text: "Gdy jest włączone, Safari może pytać o adresy stron serwery Apple, omijając filtr DNS. Filtr Apple (warstwa 1) działa nadal, ale dla pełnej ochrony je wyłącz.",
                  path: "Ustawienia → [Twoje imię] → iCloud → Przekazywanie prywatne"),
        GuideStep(icon: "network.badge.shield.half.filled", title: "Bez nowych aplikacji i VPN-ów",
                  text: "Aplikacje VPN i proxy mogą ominąć filtr DNS, a usunięcie Minimal wyłącza tarczę. Zablokuj instalowanie i usuwanie aplikacji — zmieni to tylko osoba z kodem. Uwaga: wtedy nie zainstalujesz też ponownie Minimal z Xcode (wersja Free co 7 dni) — osoba z kodem musi na chwilę na to pozwolić.",
                  path: "Ograniczaj treść i prywatność → Zakupy w iTunes Store i App Store → Instalowanie aplikacji i Usuwanie aplikacji: Nie pozwalaj"),
    ]

    var body: some View {
        List {
            Section {
                Text("Tarcza Minimal działa sama. Te ustawienia iOS sprawiają, że trudno ją wyłączyć w chwili słabości.")
                    .font(.subheadline)
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
                        .minimalFont(18, weight: .regular)
                        .foregroundStyle(Theme.primary)
                        .frame(width: 26)
                        .accessibilityHidden(true)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(step.title)
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(Theme.primary)
                            if step.isDone?() == true {
                                Spacer(minLength: 8)
                                Label("Wł.", systemImage: "checkmark.circle.fill")
                                    .labelStyle(.titleAndIcon)
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(Theme.good)
                            }
                        }
                        Text(step.text)
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        if let path = step.path {
                            Text(path)
                                .font(.footnote.weight(.medium))
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
