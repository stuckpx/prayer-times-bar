import AppKit
import SwiftUI
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var settingsWindow: NSWindow?
    private var ticker: Timer?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupPopover()

        // Start the 1-second ticker to keep the menu bar title fresh
        // Timer is added to RunLoop.main so its callback runs on the main thread
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateStatusBarTitle() }
        }
        RunLoop.main.add(ticker!, forMode: .common)

        // React to settings changes that affect the display
        let settings = AppSettings.shared
        Publishers.MergeMany(
            settings.$showPrayerName.map { _ in () }.eraseToAnyPublisher(),
            settings.$colorCodedCountdown.map { _ in () }.eraseToAnyPublisher()
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] in self?.updateStatusBarTitle() }
        .store(in: &cancellables)

        // Initial fetch if location is already configured
        PrayerTimesManager.shared.fetchPrayerTimesIfNeeded()
        updateStatusBarTitle()
    }

    // MARK: - Status Item Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.action = #selector(statusBarButtonClicked(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 390)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuContentView()
        )
    }

    // MARK: - Status Bar Title

    func updateStatusBarTitle() {
        guard let button = statusItem.button else { return }
        let manager = PrayerTimesManager.shared
        let settings = AppSettings.shared

        manager.updateNextPrayer()

        let countdown = manager.countdownString()
        var displayText: String

        if settings.showPrayerName, let next = manager.nextPrayer {
            displayText = "\(next.name)  \(countdown)"
        } else {
            displayText = countdown
        }

        if settings.colorCodedCountdown {
            let remaining = manager.timeLeftUntilNextPrayer()
            let color: NSColor
            if remaining < 1800 {
                color = .systemRed
            } else if remaining < 3600 {
                color = .systemYellow
            } else {
                // No color needed, use plain title
                button.attributedTitle = NSAttributedString(string: "")
                button.title = displayText
                return
            }
            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: color,
                .font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular),
            ]
            button.attributedTitle = NSAttributedString(string: displayText, attributes: attrs)
        } else {
            button.attributedTitle = NSAttributedString(string: "")
            button.title = displayText
        }
    }

    // MARK: - Popover Toggle

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - Settings Window

    func openSettings() {
        // Close popover first
        if popover.isShown {
            popover.performClose(nil)
        }

        if settingsWindow == nil {
            let hostingController = NSHostingController(rootView: SettingsView())
            let window = NSWindow(contentViewController: hostingController)
            window.title = "Prayer Times — Settings"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.setContentSize(NSSize(width: 420, height: 580))
            window.center()
            window.isReleasedWhenClosed = false
            window.delegate = self
            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - NSWindowDelegate

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if (notification.object as? NSWindow) === settingsWindow {
            settingsWindow = nil
        }
    }
}
