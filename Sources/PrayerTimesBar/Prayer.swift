import Foundation

struct Prayer: Identifiable, Equatable {
    let id: String
    let name: String
    let time: Date

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }

    static func == (lhs: Prayer, rhs: Prayer) -> Bool {
        lhs.id == rhs.id
    }
}

// Aladhan API response models
struct AladhanResponse: Codable {
    let code: Int
    let data: AladhanData
}

struct AladhanData: Codable {
    let timings: AladhanTimings
    let meta: AladhanMeta
}

struct AladhanTimings: Codable {
    let Fajr: String
    let Dhuhr: String
    let Asr: String
    let Maghrib: String
    let Isha: String
}

struct AladhanMeta: Codable {
    let timezone: String
}
