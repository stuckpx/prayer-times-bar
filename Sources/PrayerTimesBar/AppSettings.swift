import Foundation
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    @Published var city: String {
        didSet { defaults.set(city, forKey: Keys.city) }
    }
    @Published var country: String {
        didSet { defaults.set(country, forKey: Keys.country) }
    }
    @Published var calculationMethod: Int {
        didSet { defaults.set(calculationMethod, forKey: Keys.calculationMethod) }
    }
    @Published var asrMethod: Int {
        didSet { defaults.set(asrMethod, forKey: Keys.asrMethod) }
    }
    @Published var showPrayerName: Bool {
        didSet { defaults.set(showPrayerName, forKey: Keys.showPrayerName) }
    }
    @Published var colorCodedCountdown: Bool {
        didSet { defaults.set(colorCodedCountdown, forKey: Keys.colorCodedCountdown) }
    }

    private enum Keys {
        static let city = "city"
        static let country = "country"
        static let calculationMethod = "calculationMethod"
        static let asrMethod = "asrMethod"
        static let showPrayerName = "showPrayerName"
        static let colorCodedCountdown = "colorCodedCountdown"
    }

    private init() {
        self.city = defaults.string(forKey: Keys.city) ?? "Orlando"
        self.country = defaults.string(forKey: Keys.country) ?? "United States"
        let storedMethod = defaults.integer(forKey: Keys.calculationMethod)
        self.calculationMethod = storedMethod == 0 ? 2 : storedMethod
        self.asrMethod = defaults.integer(forKey: Keys.asrMethod)
        self.showPrayerName = defaults.object(forKey: Keys.showPrayerName) as? Bool ?? true
        self.colorCodedCountdown = defaults.bool(forKey: Keys.colorCodedCountdown)
    }
}

// Available calculation methods from the Aladhan API
struct CalculationMethod: Identifiable {
    let id: Int
    let name: String
}

let calculationMethods: [CalculationMethod] = [
    CalculationMethod(id: 1,  name: "University of Islamic Sciences, Karachi"),
    CalculationMethod(id: 2,  name: "Islamic Society of North America (ISNA)"),
    CalculationMethod(id: 3,  name: "Muslim World League"),
    CalculationMethod(id: 4,  name: "Umm Al-Qura University, Makkah"),
    CalculationMethod(id: 5,  name: "Egyptian General Authority of Survey"),
    CalculationMethod(id: 8,  name: "Gulf Region"),
    CalculationMethod(id: 9,  name: "Kuwait"),
    CalculationMethod(id: 10, name: "Qatar"),
    CalculationMethod(id: 13, name: "Diyanet İşleri Başkanlığı, Turkey"),
    CalculationMethod(id: 14, name: "Spiritual Administration of Muslims of Russia"),
    CalculationMethod(id: 15, name: "Moonsighting Committee Worldwide"),
]
