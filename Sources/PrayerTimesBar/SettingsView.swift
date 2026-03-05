import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var manager = PrayerTimesManager.shared

    @State private var cityInput = ""
    @State private var countryInput = ""
    @State private var saveStatus: SaveStatus = .idle

    enum SaveStatus {
        case idle, saved, error
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: - Location
                SectionHeader(title: "Location", icon: "location.fill")

                VStack(alignment: .leading, spacing: 10) {
                    LabeledField(label: "City") {
                        TextField("e.g. London", text: $cityInput)
                            .textFieldStyle(.roundedBorder)
                    }
                    LabeledField(label: "Country") {
                        TextField("e.g. United Kingdom", text: $countryInput)
                            .textFieldStyle(.roundedBorder)
                    }
                    Text("Prayer times are fetched from the Aladhan API based on this location.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 4)

                Divider()

                // MARK: - Calculation Method
                SectionHeader(title: "Calculation Method", icon: "function")

                VStack(alignment: .leading, spacing: 10) {
                    Picker("Method", selection: $settings.calculationMethod) {
                        ForEach(calculationMethods) { method in
                            Text(method.name).tag(method.id)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity)

                    Divider()

                    Text("Asr Prayer Calculation")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Picker("Asr Method", selection: $settings.asrMethod) {
                        Text("Standard — Shafi'i, Maliki, Hanbali").tag(0)
                        Text("Hanafi").tag(1)
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()
                }
                .padding(.leading, 4)

                Divider()

                // MARK: - Display Options
                SectionHeader(title: "Display", icon: "eye.fill")

                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $settings.showPrayerName) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Prayer Name")
                                .font(.subheadline)
                            Text("Display the next prayer name alongside the countdown")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    Toggle(isOn: $settings.colorCodedCountdown) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Color Coded Countdown")
                                .font(.subheadline)
                            Text("Change countdown color as prayer approaches")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if settings.colorCodedCountdown {
                        VStack(alignment: .leading, spacing: 6) {
                            ColorLegendRow(color: .yellow, label: "Less than 1 hour remaining")
                            ColorLegendRow(color: .red, label: "Less than 30 minutes remaining")
                        }
                        .padding(.leading, 8)
                        .padding(.top, 2)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: settings.colorCodedCountdown)
                .padding(.leading, 4)

                Divider()

                // MARK: - Save Button
                HStack {
                    Button(action: saveAndRefresh) {
                        HStack(spacing: 6) {
                            if manager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 14, height: 14)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            Text("Save & Refresh")
                        }
                        .frame(minWidth: 130)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(cityInput.trimmingCharacters(in: .whitespaces).isEmpty || manager.isLoading)

                    if case .saved = saveStatus {
                        Label("Saved!", systemImage: "checkmark")
                            .font(.caption)
                            .foregroundColor(.green)
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut, value: saveStatus == .saved)
            }
            .padding(20)
        }
        .frame(width: 400, height: 560)
        .onAppear {
            cityInput = settings.city
            countryInput = settings.country
        }
    }

    private func saveAndRefresh() {
        settings.city = cityInput
        settings.country = countryInput
        Task { @MainActor in
            manager.fetchPrayerTimes()
        }
        saveStatus = .saved
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            saveStatus = .idle
        }
    }
}

// MARK: - Helper Views

private struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundColor(.primary)
    }
}

private struct LabeledField<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            content()
        }
    }
}

private struct ColorLegendRow: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

extension SettingsView.SaveStatus: Equatable {}
