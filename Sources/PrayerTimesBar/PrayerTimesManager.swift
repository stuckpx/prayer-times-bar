import Foundation
import Combine

@MainActor
class PrayerTimesManager: ObservableObject {
    static let shared = PrayerTimesManager()

    @Published var prayers: [Prayer] = []
    @Published var nextPrayer: Prayer?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastFetchDate: Date?

    // Timezone returned by the API for the configured city
    private(set) var cityTimezone: TimeZone = .current

    private var fetchTask: Task<Void, Never>?
    private var lastFetchDay: Int?

    private init() {}

    func fetchPrayerTimesIfNeeded() {
        // Check "today" using the city's timezone so a midnight rollover in the
        // city triggers a refresh even if the system clock is in a different zone
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = cityTimezone
        let today = cal.component(.day, from: Date())
        if lastFetchDay != today || prayers.isEmpty {
            fetchPrayerTimes()
        }
    }

    func fetchPrayerTimes() {
        let settings = AppSettings.shared
        guard !settings.city.isEmpty else {
            errorMessage = "Please set your city in Settings"
            return
        }

        isLoading = true
        errorMessage = nil

        let city = settings.city
        let country = settings.country
        let method = settings.calculationMethod
        let school = settings.asrMethod

        fetchTask?.cancel()
        fetchTask = Task {
            await performFetch(city: city, country: country, method: method, school: school)
        }
    }

    private func performFetch(city: String, country: String, method: Int, school: Int) async {
        var components = URLComponents(string: "https://api.aladhan.com/v1/timingsByCity")!
        components.queryItems = [
            URLQueryItem(name: "city", value: city),
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "method", value: "\(method)"),
            URLQueryItem(name: "school", value: "\(school)"),
        ]

        guard let url = components.url else {
            isLoading = false
            errorMessage = "Invalid location settings"
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                isLoading = false
                errorMessage = "Server error (\(httpResponse.statusCode)). Check city/country."
                return
            }

            let decoded = try JSONDecoder().decode(AladhanResponse.self, from: data)

            // Use the timezone the API tells us the city is in
            let tzIdentifier = decoded.data.meta.timezone
            let tz = TimeZone(identifier: tzIdentifier) ?? .current
            cityTimezone = tz

            let timings = decoded.data.timings
            let prayerData: [(String, String)] = [
                ("Fajr",    timings.Fajr),
                ("Dhuhr",   timings.Dhuhr),
                ("Asr",     timings.Asr),
                ("Maghrib", timings.Maghrib),
                ("Isha",    timings.Isha),
            ]

            var newPrayers: [Prayer] = []
            for (name, timeStr) in prayerData {
                if let date = parseTime(timeStr, in: tz) {
                    newPrayers.append(Prayer(id: name, name: name, time: date))
                }
            }

            prayers = newPrayers
            lastFetchDate = Date()
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = tz
            lastFetchDay = cal.component(.day, from: Date())
            updateNextPrayer()
            isLoading = false
        } catch {
            isLoading = false
            if Task.isCancelled { return }
            errorMessage = "Failed to fetch: \(error.localizedDescription)"
        }
    }

    // Parse "HH:mm" (or "HH:mm (TZ)") as a time in the given timezone for today
    private func parseTime(_ timeStr: String, in timezone: TimeZone) -> Date? {
        let clean = timeStr.components(separatedBy: " ").first ?? timeStr
        let parts = clean.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timezone

        // "Today" as seen from the city's timezone
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = parts[0]
        comps.minute = parts[1]
        comps.second = 0
        return cal.date(from: comps)
    }

    func updateNextPrayer() {
        let now = Date()
        nextPrayer = prayers.first { $0.time > now }
        // All prayers have passed — project Fajr to tomorrow so the countdown is meaningful
        if nextPrayer == nil, let fajr = prayers.first {
            let tomorrowFajr = fajr.time.addingTimeInterval(24 * 60 * 60)
            nextPrayer = Prayer(id: fajr.id, name: fajr.name, time: tomorrowFajr)
        }
    }

    func timeLeftUntilNextPrayer() -> TimeInterval {
        guard let next = nextPrayer else { return 0 }
        return max(0, next.time.timeIntervalSinceNow)
    }

    func countdownString() -> String {
        guard nextPrayer != nil else { return "--:--:--" }
        let total = Int(timeLeftUntilNextPrayer())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
