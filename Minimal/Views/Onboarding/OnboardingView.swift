import SwiftUI
import UIKit

/// First run: welcome → pick your apps → shield → make it your home screen.
struct OnboardingView: View {
    private enum Step: Int, CaseIterable {
        case welcome, apps, shield, homeScreen
    }

    @AppStorage(Pref.onboarded) private var onboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step: Step = OnboardingView.initialStep
    @State private var forward = true

    private static var initialStep: Step {
        #if DEBUG
        // CI screenshots: `-debug.onboardingStep 2`
        if let step = Step(rawValue: UserDefaults.standard.integer(forKey: "debug.onboardingStep")) { return step }
        #endif
        return .welcome
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            Group {
                switch step {
                case .welcome: WelcomePage(next: next)
                case .apps: AppsPage(next: next)
                case .shield: ShieldPage(next: next)
                case .homeScreen: HomeScreenPage(finish: finish)
                }
            }
            .transition(reduceMotion ? .opacity : .asymmetric(
                insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
            ))
        }
        // Swipe right goes back a page, like a navigation stack.
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.width > 80, abs(value.translation.height) < 60, step != .welcome {
                        go(to: Step(rawValue: step.rawValue - 1) ?? .welcome)
                    }
                }
        )
        .overlay(alignment: .top) {
            if step != .welcome {
                HStack {
                    Button {
                        go(to: Step(rawValue: step.rawValue - 1) ?? .welcome)
                    } label: {
                        Image(systemName: "chevron.left")
                            .minimalFont(18, weight: .medium)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.dim)
                    .foregroundStyle(Theme.secondary)
                    .accessibilityLabel("Wstecz")
                    Spacer()
                    PageDots(count: Step.allCases.count, current: step.rawValue)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 12)
            }
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled()
    }

    private func next() {
        go(to: Step(rawValue: step.rawValue + 1) ?? .homeScreen)
    }

    private func go(to target: Step) {
        forward = target.rawValue > step.rawValue
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.45, dampingFraction: 0.9)) {
            step = target
        }
        // Let VoiceOver start reading the new page from the top.
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }

    private func finish() {
        onboarded = true
    }
}

private struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == current ? Theme.primary : Theme.tertiary)
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Krok \(current + 1) z \(count)")
    }
}

/// Shared page scaffold: content on top, buttons pinned to the bottom.
private struct OnboardingPage<Content: View, Buttons: View>: View {
    @ViewBuilder var content: Content
    @ViewBuilder var buttons: Buttons

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack(spacing: 6) {
                buttons
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - 1. Welcome

private struct WelcomePage: View {
    let next: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private let features: [(icon: String, title: String, text: String)] = [
        ("textformat", "Tylko słowa", "Spokojny ekran z kilkoma najważniejszymi aplikacjami. Bez ikon, kolorów i czerwonych kropek."),
        ("magnifyingglass", "Wszystko pod ręką", "Każdą aplikację znajdziesz w sekundę — wystarczy zacząć pisać. Niczego nie tracisz."),
        ("wind", "Pauza", "Kilka sekund oddechu przed aplikacjami, które kradną czas."),
        ("checkmark.shield", "Tarcza", "Blokuje porno w przeglądarkach i aplikacjach — na całym iPhonie."),
    ]

    var body: some View {
        OnboardingPage {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("minimal")
                        .minimalFont(56, weight: .thin)
                        .foregroundStyle(Theme.primary)
                        .padding(.top, 72)
                    Text("Wszystko, czego potrzebujesz.\nNic, co rozprasza.")
                        .font(.title2)
                        .foregroundStyle(Theme.secondary)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 26) {
                        ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                            HStack(alignment: .top, spacing: 18) {
                                Image(systemName: feature.icon)
                                    .minimalFont(26, weight: .light)
                                    .accessibilityHidden(true)
                                    .foregroundStyle(Theme.primary)
                                    .frame(width: 36)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(feature.title)
                                        .font(.headline)
                                        .foregroundStyle(Theme.primary)
                                    Text(feature.text)
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared || reduceMotion ? 0 : 12)
                            .animation(.easeOut(duration: 0.5).delay(0.15 + Double(index) * 0.08), value: appeared)
                        }
                    }
                    .padding(.top, 48)
                }
                .padding(.horizontal, Theme.gutter)
            }
            .scrollIndicators(.hidden)
        } buttons: {
            Button("Zaczynamy", action: next)
                .buttonStyle(.primary)
        }
        .onAppear { appeared = true }
    }
}

// MARK: - 2. Apps

private struct AppsPage: View {
    let next: () -> Void
    @EnvironmentObject private var store: LauncherStore

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 0) {
                PageTitle(title: "Twoje aplikacje",
                          subtitle: "Zaznacz te, których używasz. Resztę dodasz później — każdą aplikację z iPhone’a.")
                    .padding(.horizontal, Theme.gutter)
                List {
                    ForEach(CatalogApp.Kind.allCases) { group in
                        Section(group.title) {
                            ForEach(AppCatalog.search("", kind: group)) { app in
                                CatalogRow(app: app)
                            }
                        }
                        .minimalRow()
                    }
                }
                .minimalSheet()
            }
        } buttons: {
            Button("Dalej", action: next)
                .buttonStyle(.primary)
            Text("Zaznaczone: \(store.items.count)")
                .font(.footnote)
                .foregroundStyle(Theme.tertiary)
                .frame(height: 30)
        }
    }
}

// MARK: - 3. Shield

private struct ShieldPage: View {
    let next: () -> Void
    @EnvironmentObject private var shield: ShieldModel
    @State private var showFreeShield = false

    var body: some View {
        OnboardingPage {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Image(systemName: shield.isProtecting ? "checkmark.shield.fill" : "shield")
                        .minimalFont(54, weight: .light)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(shield.isProtecting ? Theme.good : Theme.primary)
                        .contentTransition(.symbolEffect(.replace))
                        .padding(.top, 72)
                    PageTitle(title: "Tarcza",
                              subtitle: shield.isFullEdition
                                ? "Włącz obie warstwy, a strony porno przestaną się otwierać w przeglądarkach i aplikacjach. Później możesz dodać blokadę wybranych aplikacji."
                                : "Trzy krótkie kroki w Ustawieniach iOS i porno znika z Twojego iPhone’a. Minimal poprowadzi Cię przez każdy z nich.",
                              topPadding: 20)

                    VStack(spacing: 12) {
                        if shield.isFullEdition {
                            fullEditionCards
                        } else {
                            ShieldStepCard(
                                number: 1,
                                title: "Tarcza w trzech krokach",
                                text: "Filtr Apple, profil DNS i blokada aplikacji — krok po kroku, w Ustawieniach iOS.",
                                isDone: shield.activeLayers == ShieldModel.FreeStep.allCases.count,
                                action: "Ustaw"
                            ) {
                                showFreeShield = true
                            }
                        }
                    }
                    .padding(.top, 32)
                }
                .padding(.horizontal, Theme.gutter)
            }
            .scrollIndicators(.hidden)
        } buttons: {
            if shield.isProtecting {
                Button("Dalej", action: next)
                    .buttonStyle(.primary)
            } else {
                Button("Pomiń na razie", action: next)
                    .buttonStyle(.secondary)
            }
        }
        .sheet(isPresented: $showFreeShield) {
            NavigationStack { ShieldView(showsDone: true) }
        }
        .task { await shield.refresh() }
        .alert(shield.messageTitle, isPresented: Binding(get: { shield.message != nil }, set: { if !$0 { shield.message = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(shield.message ?? "")
        }
    }

    @ViewBuilder
    private var fullEditionCards: some View {
        ShieldStepCard(
            number: 1,
            title: "Filtr witryn dla dorosłych",
            text: "Wbudowany filtr Apple w Safari i innych przeglądarkach.",
            isDone: shield.webFilterActive,
            action: "Włącz"
        ) {
            Task { await shield.enableWebFilter() }
        }

        ShieldStepCard(
            number: 2,
            title: "Filtr DNS",
            text: shield.dnsInstalled && !shield.dnsEnabled
                ? "Zainstalowany. Włącz go: Ustawienia → Ogólne → VPN i urządzenia zarządzane → DNS → Minimal."
                : "CleanBrowsing Family: blokuje porno, a także Reddita, VPN-y i proxy; wymusza bezpieczne wyszukiwanie. Dostawcę zmienisz w Tarczy.",
            isDone: shield.dnsEnabled,
            action: shield.dnsInstalled ? "Ustawienia" : "Zainstaluj"
        ) {
            if shield.dnsInstalled {
                SystemSettings.open()
            } else {
                Task { await shield.installDNS(.recommended) }
            }
        }
    }
}

private struct ShieldStepCard: View {
    let number: Int
    let title: String
    let text: String
    let isDone: Bool
    let action: String
    let perform: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(isDone ? Theme.good.opacity(0.18) : Theme.surface)
                if isDone {
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

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Theme.primary)
                    Spacer(minLength: 8)
                    if isDone {
                        Label("Gotowe", systemImage: "checkmark")
                            .labelStyle(.titleAndIcon)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.good)
                    }
                }
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if !isDone {
                    Button(action: perform) {
                        Text(action)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 18)
                            .frame(minHeight: 36)
                            .background(Theme.primary, in: Capsule())
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.dim)
                    .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .animation(.snappy, value: isDone)
    }
}

// MARK: - 4. Home screen

private struct HomeScreenPage: View {
    let finish: () -> Void

    var body: some View {
        OnboardingPage {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    PageTitle(title: "Zrób z tego swój ekran",
                              subtitle: "iOS nie pozwala aplikacjom zastąpić ekranu głównego, ale w minutę ustawisz go tak, że Minimal stanie się wszystkim, co widzisz.",
                              topPadding: 72)

                    VStack(alignment: .leading, spacing: 22) {
                        GuideStepRow(number: 1, title: "Dodaj widżet",
                                     text: "Przytrzymaj ekran główny → Edytuj → Dodaj widżet → Minimal → Ulubione (duży).")
                        GuideStepRow(number: 2, title: "Schowaj resztę",
                                     text: "Przenieś pozostałe aplikacje do biblioteki aplikacji i ukryj dodatkowe strony ekranu głównego.")
                        GuideStepRow(number: 3, title: "Minimal w Docku",
                                     text: "Zostaw w Docku tylko Minimal — stąd jednym stuknięciem dotrzesz do każdej aplikacji.")
                        GuideStepRow(number: 4, title: "Czerń i szarość",
                                     text: "Ustaw czarną tapetę i skrót do skali szarości. Pełny przewodnik znajdziesz w aplikacji: ⋯ → Przewodnik po minimalizmie.")
                    }
                    .padding(.top, 32)
                }
                .padding(.horizontal, Theme.gutter)
            }
            .scrollIndicators(.hidden)
        } buttons: {
            Button("Gotowe", action: finish)
                .buttonStyle(.primary)
        }
    }
}

// MARK: - Shared bits

struct PageTitle: View {
    let title: String
    let subtitle: String
    var topPadding: CGFloat = 64

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.primary)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, topPadding)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct GuideStepRow: View {
    let number: Int
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(.subheadline.weight(.semibold)).fontDesign(.rounded)
                .foregroundStyle(Color.black)
                .frame(width: 26, height: 26)
                .background(Theme.primary, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.primary)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
