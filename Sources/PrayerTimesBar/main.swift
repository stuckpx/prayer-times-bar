import AppKit

// main.swift always runs on the main thread, so assumeIsolated is safe here
let app = NSApplication.shared
let delegate = MainActor.assumeIsolated { AppDelegate() }
app.delegate = delegate
app.run()
