<p align="center">
  <img src="Minimal/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="120" alt="Ikona Minimal">
</p>

<h1 align="center">minimal</h1>

<p align="center">
  <b>Wszystko, czego potrzebujesz. Nic, co rozprasza.</b><br>
  Minimalistyczny ekran dla iPhone’a — z tarczą, która blokuje porno w całym telefonie.
</p>

<p align="center">
  <img src="docs/screenshots/home.png" width="200" alt="Ekran główny">
  <img src="docs/screenshots/search.png" width="200" alt="Wyszukiwanie">
  <img src="docs/screenshots/pause.png" width="200" alt="Pauza">
  <img src="docs/screenshots/shield.png" width="200" alt="Tarcza">
</p>

---

## Co potrafi

| | |
|---|---|
| **Tylko słowa** | Zegar, data i kilka najważniejszych aplikacji, zapisanych zwykłym tekstem. Bez ikon, kolorów i czerwonych kropek. |
| **Wszystko pod ręką** | Każda aplikacja jest o jedno wyszukanie dalej. Niczego nie tracisz: gotowy katalog ponad 40 aplikacji, a każdą inną dodasz przez aplikację Skróty. |
| **Pauza** | Przy wybranych aplikacjach (Instagram, YouTube, X…) najpierw kilka sekund oddechu i pytanie, czy na pewno. Impuls mija, a Ty decydujesz świadomie. |
| **Tarcza** | Trzy warstwy blokady porno: filtr stron dla dorosłych Apple, szyfrowany rodzinny DNS dla całego telefonu i blokada wybranych aplikacji. Do tego opcjonalne opóźnienie, zanim tarczę da się wyłączyć. |
| **Widżety** | „Ulubione” na ekran początkowy i ekran blokady oraz „Szukaj”, który otwiera wyszukiwanie jednym stuknięciem. |
| **Prywatność** | Bez kont, bez serwerów, bez śledzenia. Wszystko zostaje na Twoim iPhonie. |

---

## Instalacja — około 15 minut

### Czego potrzebujesz

- **iPhone** z iOS 17 lub nowszym (zalecany iOS 26).
- **Mac** z aplikacją **Xcode**, darmową z App Store.
- **Konto Apple**:
  - **płatne Apple Developer** (99 USD/rok): pełna, automatyczna tarcza, a aplikacja działa cały rok bez odświeżania. **Polecane.**
  - **zwykłe, darmowe Apple ID**: wszystko działa, ale tarczę ustawiasz ręcznie, prowadzi Cię przewodnik w aplikacji. Aplikację trzeba odświeżać co 7 dni. Szczegóły w sekcji [Wersja Free](#wersja-free-darmowe-apple-id).

### Krok po kroku

1. **Pobierz projekt.** Na GitHubie kliknij zielony przycisk **Code → Download ZIP** i rozpakuj plik. Możesz też wpisać w Terminalu `git clone`.
2. **Ustaw swój identyfikator.** Otwórz plik `Config/Signing.xcconfig` w dowolnym edytorze i zmień:
   ```
   BUNDLE_ID_PREFIX = com.twojeimie
   ```
   Prefiks musi być unikalny na świecie, np. `com.jankowalski`.
3. **Otwórz `Minimal.xcodeproj`** (dwuklik).
4. **Zaloguj się w Xcode:** **Xcode → Settings → Accounts → ＋ → Apple Account**.
5. **Wybierz zespół:** w lewym panelu kliknij niebieską ikonę **Minimal**, potem target **Minimal**, kartę **Signing & Capabilities** i w polu **Team** wybierz swoje konto. Powtórz to samo dla targetu **MinimalWidget**.
6. **Podłącz iPhone’a** kablem i odblokuj go. Jeśli zapyta „Ufać temu komputerowi?”, stuknij **Ufaj**.
7. **Włącz tryb dewelopera** na iPhonie: **Ustawienia → Prywatność i ochrona → Tryb dewelopera → Włącz**. iPhone uruchomi się ponownie.
8. **Wybierz iPhone’a** na górnym pasku Xcode i naciśnij **▶︎** (⌘R).
9. **Darmowe Apple ID?** Przy pierwszym uruchomieniu iPhone poprosi o zaufanie deweloperowi: **Ustawienia → Ogólne → VPN i zarządzanie urządzeniem → [Twoje Apple ID] → Ufaj**.
10. **Gotowe.** Minimal przeprowadzi Cię przez resztę: wybór aplikacji, tarczę i ustawienie ekranu.

> **Błąd „No profiles for … were found” albo „Failed to register bundle identifier”?** Prefiks z kroku 2 jest już zajęty albo nie wybrano zespołu w kroku 5. Zmień prefiks na inny i spróbuj ponownie.

### Ustaw ekran jak dumbphone (2 minuty)

iOS nie pozwala żadnej aplikacji zastąpić ekranu początkowego. Da się go jednak ustawić tak, że widzisz tylko Minimal:

1. **Widżet:** przytrzymaj puste miejsce na ekranie → **Edytuj → Dodaj widżet → Minimal → Ulubione** (duży).
2. **Reszta do biblioteki:** pozostałe ikony przenieś do biblioteki aplikacji i ukryj zbędne strony ekranu.
3. **Dock:** zostaw w nim tylko Minimal.
4. **Czerń i szarość:** ustaw czarną tapetę i skrót do skali szarości (trzykrotne kliknięcie bocznego przycisku).

Dokładne ścieżki znajdziesz w aplikacji: **⋯ → Przewodnik minimalizmu**.

---

## Tarcza

| Warstwa | Co blokuje | Jak działa |
|---|---|---|
| **1. Filtr stron dla dorosłych** | Strony porno w Safari, Chrome, Firefoksie i przeglądarkach wewnątrz aplikacji. Wyłącza też przeglądanie prywatne. | Wbudowany filtr Apple (Screen Time API), ten sam co „Ogranicz strony dla dorosłych”. |
| **2. Filtr DNS** | Strony porno w **każdej** aplikacji. Wymusza bezpieczne wyszukiwanie (także obrazów) i tryb ograniczony YouTube, blokuje VPN-y i proxy. | Szyfrowany rodzinny DNS ([CleanBrowsing Family](https://cleanbrowsing.org/filters/), do wyboru również AdGuard i Cloudflare). |
| **3. Zablokowane aplikacje** | Aplikacje, w których łatwo trafić na porno (np. X, Reddit, Telegram), albo całe kategorie. | Osłona Screen Time na wybranych aplikacjach. |
| **Zobowiązanie** | Wyłączenie czegokolwiek wymaga odczekania (1 h – 7 dni). Opcjonalnie blokada usuwania aplikacji. | Licznik w aplikacji i `denyAppRemoval`. |

**Po instalacji filtra DNS** włącz go jeszcze raz ręcznie: **Ustawienia → Ogólne → VPN i zarządzanie urządzeniem → DNS → Minimal**. iOS wymaga, żeby ten jeden krok zrobił człowiek.

### Uczciwie: czy da się to obejść?

Na prywatnym iPhonie każdą blokadę można w końcu wyłączyć. Tarcza ma sprawić, żeby było to trudne, powolne i świadome. Najmocniejszy zestaw:

- **Kod Czasu przed ekranem u zaufanej osoby.** W iOS 26.4 i nowszych bez tego kodu nie da się odebrać Minimal dostępu do Czasu przed ekranem.
- W Czasie przed ekranem zablokuj **zmiany kodu i konta**.
- Włącz **Ostrzeżenie o wrażliwej zawartości**, które rozmywa nagie zdjęcia w Wiadomościach, AirDropie i FaceTimie.
- Nie instaluj aplikacji VPN, bo omijają filtr DNS.

Pełna lista jest w aplikacji: **Tarcza → Maksymalna ochrona**.

---

## Wersja Free (darmowe Apple ID)

Darmowe konto Apple nie ma dostępu do Screen Time API ani ustawień DNS, więc tarcza nie może włączyć się sama. W pliku `Config/Signing.xcconfig` ustaw:

```
MINIMAL_EDITION = Free
```

Wszystko inne działa tak samo. W zakładce **Tarcza** aplikacja poprowadzi Cię przez:

1. wbudowany filtr Apple („Ogranicz strony dla dorosłych”),
2. instalację **profilu DNS**: gotowe pliki są w folderze [`Profiles/`](Profiles), a aplikacja może je od razu zapisać w Plikach,
3. limity aplikacji w Czasie przed ekranem.

Aplikacje zainstalowane z darmowego konta wygasają po 7 dniach. Wtedy podłącz iPhone’a i znowu naciśnij **▶︎** w Xcode.

### Tylko tarcza, bez aplikacji

Chcesz samą blokadę? Wyślij na iPhone’a jeden z plików z folderu [`Profiles/`](Profiles) (AirDrop, Mail, iCloud Drive) i otwórz go. Potem przejdź do **Ustawienia → Pobrany profil → Instaluj**.

---

## Jak dodać aplikację, której nie ma w katalogu

Każdą aplikację z iPhone’a da się otworzyć przez aplikację **Skróty**:

1. Skróty → **＋** → **Dodaj czynność** → **Otwórz aplikację** → wybierz aplikację.
2. Nazwij skrót, np. „Otwórz Aparat”.
3. W Minimal: **Szukaj → Dodaj → Skrót**, wpisz tę samą nazwę.

---

## Dla programistów

```
Minimal/            aplikacja (SwiftUI, iOS 17+)
  Model/            dane, katalog aplikacji, routing, statystyki
  Shield/           tarcza: FamilyControls, ManagedSettings, NEDNSSettingsManager
  Views/            ekrany
MinimalWidget/      widżety (WidgetKit)
Shared/             kod wspólny dla aplikacji i widżetu (App Group)
Profiles/           profile DNS (.mobileconfig) dla wersji Free
Config/             podpisywanie i edycja (Full/Free)
scripts/            generator projektu Xcode, ikona, profile, zrzuty ekranu
```

- Projekt Xcode jest generowany skryptem: `gem install xcodeproj && ruby scripts/generate_project.rb`. Uruchom go po dodaniu lub usunięciu plików.
- Przy każdym pushu CI (GitHub Actions, macOS) buduje aplikację na symulator i na iPhone’a oraz tworzy niepodpisany plik `.ipa`. Commit z `[shots]` w opisie dodatkowo odświeża zrzuty ekranu w `docs/screenshots`.
- Deep linki: `minimal://search`, `minimal://shield`, `minimal://settings`, `minimal://open/<id>`. Przydają się w Skrótach i pod przyciskiem czynności.
