import SwiftUI
import AppKit

struct MenuContentView: View {
    @ObservedObject private var manager = PrayerTimesManager.shared
    @ObservedObject private var settings = AppSettings.shared
    @State private var tick = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.secondary)
                Text("Prayer Times")
                    .font(.headline)
                Spacer()
                Button {
                    Task { @MainActor in
                        manager.fetchPrayerTimes()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Refresh prayer times")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Next prayer countdown
            if let next = manager.nextPrayer {
                VStack(spacing: 4) {
                    Text("Next: \(next.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(manager.countdownString())
                        .font(.system(size: 28, weight: .semibold, design: .monospaced))
                        .foregroundColor(countdownColor())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.secondary.opacity(0.06))
            } else if manager.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Fetching prayer times...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else if let error = manager.errorMessage {
                VStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
            } else {
                Text("Set your location in Settings")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }

            Divider()

            // Prayer times list
            VStack(spacing: 0) {
                ForEach(manager.prayers) { prayer in
                    PrayerRowView(prayer: prayer, isNext: prayer == manager.nextPrayer)
                    if prayer != manager.prayers.last {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }

            Divider()

            // Bottom buttons
            HStack {
                Button("Settings") {
                    AppDelegate.shared?.openSettings()
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 300)
        .padding(.bottom, 6)
        .onReceive(timer) { _ in
            tick = Date()
            Task { @MainActor in
                manager.updateNextPrayer()
                manager.fetchPrayerTimesIfNeeded()
            }
        }
        .onAppear {
            Task { @MainActor in
                manager.fetchPrayerTimesIfNeeded()
            }
        }
    }

    private func countdownColor() -> Color {
        guard settings.colorCodedCountdown else { return .primary }
        let remaining = manager.timeLeftUntilNextPrayer()
        if remaining < 1800 {
            return .red
        } else if remaining < 3600 {
            return .yellow
        }
        return .primary
    }
}

struct PrayerRowView: View {
    let prayer: Prayer
    let isNext: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isNext ? Color.accentColor : Color.secondary.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: prayerIcon(prayer.name))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isNext ? .white : .secondary)
            }

            Text(prayer.name)
                .font(.system(size: 14, weight: isNext ? .semibold : .regular))
                .foregroundColor(isNext ? .primary : .primary)

            Spacer()

            Text(prayer.timeString)
                .font(.system(size: 14, weight: isNext ? .semibold : .regular, design: .monospaced))
                .foregroundColor(isNext ? .accentColor : .secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isNext ? Color.accentColor.opacity(0.08) : Color.clear)
    }

    private func prayerIcon(_ name: String) -> String {
        switch name {
        case "Fajr":    return "sunrise.fill"
        case "Dhuhr":   return "sun.max.fill"
        case "Asr":     return "sun.haze.fill"
        case "Maghrib": return "sunset.fill"
        case "Isha":    return "moon.fill"
        default:        return "clock.fill"
        }
    }
}
