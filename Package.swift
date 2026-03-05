// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PrayerTimesBar",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "PrayerTimesBar",
            path: "Sources/PrayerTimesBar"
        )
    ]
)
