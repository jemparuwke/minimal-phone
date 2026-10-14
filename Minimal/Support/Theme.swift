import SwiftUI

enum Theme {
    static let background = Color.black
    static let primary = Color.white
    static let secondary = Color.white.opacity(0.55)
    static let tertiary = Color.white.opacity(0.3)
    static let hairline = Color.white.opacity(0.12)
    static let surface = Color.white.opacity(0.07)
    static let good = Color(red: 0.40, green: 0.86, blue: 0.58)
    static let warning = Color(red: 1.00, green: 0.76, blue: 0.32)
    static let bad = Color(red: 1.00, green: 0.42, blue: 0.40)

    static let gutter: CGFloat = 32
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
        case .small: return "Mały"
        case .medium: return "Średni"
        case .large: return "Duży"
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

/// Plain button that dims while pressed — no chrome, just text.
struct DimOnPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.35 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == DimOnPressStyle {
    static var dim: DimOnPressStyle { DimOnPressStyle() }
}

/// Big white call-to-action, as on Apple's own welcome screens.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.white.opacity(isEnabled ? 1 : 0.4), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
            .frame(maxWidth: .infinity)
            .frame(height: 44)
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
