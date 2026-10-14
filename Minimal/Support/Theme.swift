import SwiftUI
import UIKit

enum Theme {
    static let background = Color.black
    static let primary = Color.white
    // Secondary ≈ 7:1 and tertiary ≈ 4.7:1 contrast on black (WCAG AA for text);
    // both get brighter with Settings → Accessibility → Increase Contrast.
    static let secondary = white(0.62, increased: 0.80)
    static let tertiary = white(0.47, increased: 0.66)
    static let hairline = white(0.12, increased: 0.30)
    static let surface = white(0.07, increased: 0.14)
    // System colors adapt to Increase Contrast and match the rest of iOS.
    static let good = Color(uiColor: .systemGreen)
    static let warning = Color(uiColor: .systemYellow)
    static let bad = Color(uiColor: .systemRed)

    static let gutter: CGFloat = 32

    private static func white(_ alpha: CGFloat, increased: CGFloat) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(white: 1, alpha: traits.accessibilityContrast == .high ? increased : alpha)
        })
    }
}

/// System font at a designer-chosen size that still follows Dynamic Type.
struct ScaledSystemFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    private let weight: Font.Weight

    init(size: CGFloat, weight: Font.Weight, relativeTo textStyle: Font.TextStyle) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
        self.weight = weight
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight))
    }
}

extension View {
    /// Light system text at `size` points (at the default text size), scaled with Dynamic Type.
    func minimalFont(_ size: CGFloat, weight: Font.Weight = .light, relativeTo textStyle: Font.TextStyle = .title) -> some View {
        modifier(ScaledSystemFont(size: size, weight: weight, relativeTo: textStyle))
    }
}

/// Text size preference for the home screen.
enum TextScale: String, CaseIterable, Identifiable {
    case small, medium, large

    var id: String { rawValue }

    var label: String {
        switch self {
        case .small: return "Mała"
        case .medium: return "Średnia"
        case .large: return "Duża"
        }
    }

    var itemSize: CGFloat {
        switch self {
        case .small: return 26
        case .medium: return 31
        case .large: return 37
        }
    }

    var clockSize: CGFloat {
        switch self {
        case .small: return 64
        case .medium: return 76
        case .large: return 88
        }
    }
}

/// Plain button that dims while pressed — no chrome, just text. Shows a subtle shape when
/// Settings → Accessibility → Button Shapes is on.
struct DimOnPressStyle: ButtonStyle {
    @Environment(\.accessibilityShowButtonShapes) private var showButtonShapes

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, showButtonShapes ? 8 : 0)
            .background {
                if showButtonShapes {
                    RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Theme.surface)
                }
            }
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.35 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == DimOnPressStyle {
    static var dim: DimOnPressStyle { DimOnPressStyle() }
}

/// Haptics that respect the in-app "Haptyka" switch.
enum Haptics {
    static var isEnabled: Bool { UserDefaults.standard.object(forKey: Pref.haptics) as? Bool ?? true }

    static func tap() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func selection() {
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

/// Big white call-to-action, as on Apple's own welcome screens.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.black)
            .multilineTextAlignment(.center)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color.white.opacity(isEnabled ? 1 : 0.4), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Quiet text button under the primary one ("Pomiń", "Nie teraz").
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .foregroundStyle(Theme.secondary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.4 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

/// Black, dark-mode styling for sheets that use system lists and forms.
struct MinimalSheetStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            // No explicit .tint: buttons follow the white AccentColor, while switches keep
            // the system green so their "on" state stays readable.
            .preferredColorScheme(.dark)
    }
}

extension View {
    func minimalSheet() -> some View { modifier(MinimalSheetStyle()) }

    /// Row background used inside `List`/`Form` on black.
    func minimalRow() -> some View { listRowBackground(Theme.surface) }
}
