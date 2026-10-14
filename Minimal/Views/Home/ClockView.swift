import SwiftUI
import UIKit

/// Big quiet clock with the date (and battery when the status bar is hidden).
struct ClockView: View {
    @AppStorage(Pref.use24h) private var use24h = Formatters.systemUses24h
    @AppStorage(Pref.showSeconds) private var showSeconds = false
    @AppStorage(Pref.hideStatusBar) private var hideStatusBar = true
    @AppStorage(Pref.textScale) private var textScale: TextScale = .medium

    @State private var batteryLevel: Int?
    @State private var isCharging = false

    var body: some View {
        Group {
            if showSeconds {
                TimelineView(.periodic(from: .now, by: 1)) { context in clock(context.date) }
            } else {
                TimelineView(.everyMinute) { context in clock(context.date) }
            }
        }
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            updateBattery()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)) { _ in
            updateBattery()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)) { _ in
            updateBattery()
        }
    }

    private func clock(_ date: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(time(date))
                .minimalFont(textScale.clockSize, weight: .thin)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(Theme.primary)
            Text(detail(date))
                .font(.body)
                .foregroundStyle(Theme.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText(date))
    }

    private func accessibilityText(_ date: Date) -> String {
        var text = "\(time(date)), \(Formatters.longDate.string(from: date))"
        if hideStatusBar, let batteryLevel {
            text += ", bateria \(batteryLevel)%"
            if isCharging { text += ", ładowanie" }
        }
        return text
    }

    private func time(_ date: Date) -> String {
        let formatter: DateFormatter
        switch (use24h, showSeconds) {
        case (true, false): formatter = Formatters.time24
        case (true, true): formatter = Formatters.time24Seconds
        case (false, false): formatter = Formatters.time12
        case (false, true): formatter = Formatters.time12Seconds
        }
        return formatter.string(from: date)
    }

    private func detail(_ date: Date) -> String {
        var text = Formatters.longDate.string(from: date)
        if hideStatusBar, let batteryLevel {
            text += "  ·  \(batteryLevel)%"
            if isCharging { text += " ⚡︎" }
        }
        return text
    }

    private func updateBattery() {
        let level = UIDevice.current.batteryLevel
        batteryLevel = level < 0 ? nil : Int((level * 100).rounded())
        let state = UIDevice.current.batteryState
        isCharging = state == .charging || state == .full
    }
}
