import SwiftUI

/// A few seconds of breathing before a distracting app opens.
struct PauseView: View {
    let item: LaunchItem

    @EnvironmentObject private var coordinator: LaunchCoordinator
    @EnvironmentObject private var stats: UsageStats
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var remaining: Int
    @State private var inhale = false

    init(item: LaunchItem) {
        self.item = item
        let seconds = UserDefaults.standard.integer(forKey: Pref.pauseSeconds)
        _remaining = State(initialValue: seconds > 0 ? seconds : 5)
    }

    private let breath: Double = 4

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Theme.hairline, lineWidth: 1)
                Circle()
                    .fill(Color.white.opacity(0.09))
                    .scaleEffect(reduceMotion ? 0.7 : (inhale ? 1 : 0.42))
                Text(remaining > 0 ? "\(remaining)" : "")
                    .minimalFont(44, weight: .ultraLight)
                    .monospacedDigit()
                    .foregroundStyle(Theme.secondary)
                    .contentTransition(.numericText(countsDown: true))
            }
            .frame(width: 220, height: 220)
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(inhale ? "wdech" : "wydech")
                    .font(.subheadline)
                    .foregroundStyle(Theme.tertiary)
                    .contentTransition(.opacity)
                Text(item.name)
                    .minimalFont(34)
                    .foregroundStyle(Theme.primary)
                    .multilineTextAlignment(.center)
                Text("Czy naprawdę potrzebujesz tego teraz?")
                    .font(.body)
                    .foregroundStyle(Theme.secondary)
                    .multilineTextAlignment(.center)
                if let opensText {
                    Text(opensText)
                        .font(.subheadline)
                        .foregroundStyle(Theme.tertiary)
                }
            }
            .padding(.top, 44)
            .padding(.horizontal, Theme.gutter)

            Spacer()

            VStack(spacing: 6) {
                Button {
                    coordinator.resist()
                } label: {
                    Text("Nie teraz")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Theme.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.dim)

                Button {
                    coordinator.open(item)
                } label: {
                    Text(remaining > 0 ? "Otwórz za \(remaining) s" : "Otwórz")
                        .font(.body)
                        .foregroundStyle(remaining > 0 ? Theme.tertiary : Theme.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .contentTransition(.numericText(countsDown: true))
                }
                .buttonStyle(.dim)
                .disabled(remaining > 0)
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .accessibilityAddTraits(.isModal)
        .task {
            while remaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                withAnimation(.easeOut(duration: 0.25)) { remaining -= 1 }
            }
        }
        .task {
            while !Task.isCancelled {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: breath)) { inhale.toggle() }
                try? await Task.sleep(for: .seconds(breath))
            }
        }
    }

    private var opensText: String? {
        let count = stats.opensToday(of: item)
        guard count > 0 else { return nil }
        return count == 1 ? "Dziś otwierane już 1 raz." : "Dziś otwierane już \(count) razy."
    }
}
