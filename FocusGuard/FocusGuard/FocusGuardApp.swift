//
//  FocusGuardApp.swift
//  FocusGuard - Eye Tracking Focus App
//
//  A macOS app that tracks eye movement to ensure focused work sessions.
//  Blocks distracting apps until focus goals are met.
//

import SwiftUI
import AppKit

@main
struct FocusGuardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var focusManager = FocusSessionManager.shared
    @StateObject private var settings = SettingsManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(focusManager)
                .environmentObject(settings)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            // Remove quit command to prevent easy exit during focus sessions
            CommandGroup(replacing: .appTermination) {
                if !focusManager.isSessionActive || focusManager.canQuit {
                    Button("Quit FocusGuard") {
                        NSApplication.shared.terminate(nil)
                    }
                    .keyboardShortcut("q")
                } else {
                    Text("Quit disabled during focus session")
                        .foregroundColor(.secondary)
                }
            }
        }

        Settings {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(focusManager)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBarItem()
        requestPermissions()

        // Prevent app from being closed via Cmd+Q during active sessions
        NSApplication.shared.windows.forEach { window in
            window.standardWindowButton(.closeButton)?.isEnabled = !FocusSessionManager.shared.isSessionActive
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let manager = FocusSessionManager.shared
        if manager.isSessionActive && !manager.canQuit {
            // Show alert that user cannot quit
            DispatchQueue.main.async {
                self.showCannotQuitAlert()
            }
            return .terminateCancel
        }
        return .terminateNow
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep running in background
    }

    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "eye.circle.fill", accessibilityDescription: "FocusGuard")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open FocusGuard", action: #selector(openApp), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Status: Ready", action: nil, keyEquivalent: ""))
        statusItem?.menu = menu
    }

    @objc private func openApp() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }

    private func requestPermissions() {
        // Camera permission will be requested when eye tracking starts
        // Accessibility permission needed for app blocking
        print("FocusGuard initialized - permissions will be requested as needed")
    }

    private func showCannotQuitAlert() {
        let alert = NSAlert()
        alert.messageText = "Cannot Quit During Focus Session"
        alert.informativeText = "You must complete your focus goal of \(SettingsManager.shared.focusHoursRequired) hours or contact \(SettingsManager.shared.bypassEmail) to request an emergency unlock."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Continue Focusing")
        alert.addButton(withTitle: "Copy Support Email")

        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(SettingsManager.shared.bypassEmail, forType: .string)
        }
    }
}
