# Prayer Times Bar

A lightweight macOS menubar app that displays a live countdown to the next Islamic prayer time. Click the menubar to see all five daily prayers, and configure your location and calculation preferences in Settings.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Live countdown** in the menubar — updates every second
- **Next prayer name** optionally shown alongside the countdown
- **Color-coded countdown** — turns yellow when less than 1 hour remains, red when less than 30 minutes remain
- **Popup panel** showing all 5 prayers (Fajr, Dhuhr, Asr, Maghrib, Isha) with times and the next prayer highlighted
- **Settings window** for location, calculation method, and display preferences
- **Automatic daily refresh** — fetches new prayer times each day
- Runs as a menubar-only agent (no Dock icon)

## Screenshot

> Popup panel showing prayer times and live countdown

## Requirements

- macOS 13 (Ventura) or later
- Swift 5.9+ / Xcode 15+ (to build from source)

## Installation

### Build from source

```bash
git clone https://github.com/stuckpx/prayer-times-bar.git
cd prayer-times-bar
./build.sh
```

This produces `PrayerTimesBar.app` in the project directory.

**To run:**
```bash
open PrayerTimesBar.app
```

**To install permanently:**
```bash
cp -r PrayerTimesBar.app /Applications/
```

To launch automatically on login, open **System Settings → General → Login Items** and add `PrayerTimesBar.app`.

## Configuration

Click the menubar countdown to open the popup, then click **Settings** at the bottom.

### Location
Enter your **City** and **Country**. Prayer times are fetched from the [Aladhan API](https://aladhan.com/prayer-times-api) based on this location. The default is Orlando, United States.

### Calculation Method
Choose from 11 globally recognized methods:

| Method | Authority |
|--------|-----------|
| 1 | University of Islamic Sciences, Karachi |
| 2 | Islamic Society of North America (ISNA) *(default)* |
| 3 | Muslim World League |
| 4 | Umm Al-Qura University, Makkah |
| 5 | Egyptian General Authority of Survey |
| 8 | Gulf Region |
| 9 | Kuwait |
| 10 | Qatar |
| 13 | Diyanet İşleri Başkanlığı, Turkey |
| 14 | Spiritual Administration of Muslims of Russia |
| 15 | Moonsighting Committee Worldwide |

### Asr Prayer Calculation
- **Standard** — Shafi'i, Maliki, Hanbali (shadow factor 1)
- **Hanafi** (shadow factor 2)

### Display Options
| Option | Description |
|--------|-------------|
| Show Prayer Name | Display the next prayer name next to the countdown in the menubar |
| Color Coded Countdown | Yellow when < 1 hour remains; red when < 30 minutes remain |

## Project Structure

```
PrayerTimesBar/
├── Package.swift                        # Swift Package Manager config
├── Info.plist                           # App bundle metadata (LSUIElement, etc.)
├── build.sh                             # Build script → produces .app bundle
└── Sources/PrayerTimesBar/
    ├── main.swift                       # Entry point
    ├── AppDelegate.swift                # Status item, popover, timer, settings window
    ├── AppSettings.swift                # UserDefaults-backed preferences + calculation methods
    ├── Prayer.swift                     # Prayer model + Aladhan API response types
    ├── PrayerTimesManager.swift         # API fetching, countdown logic
    ├── MenuContentView.swift            # Popup SwiftUI view
    └── SettingsView.swift               # Settings window SwiftUI view
```

## How It Works

Prayer times are fetched from the free [Aladhan REST API](https://aladhan.com/prayer-times-api) using your configured city and country. No API key is required. Times are parsed into `Date` objects relative to today and refreshed automatically each day at midnight. After all five prayers have passed for the day, the countdown targets tomorrow's Fajr.

## License

MIT
