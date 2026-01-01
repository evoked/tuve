//
//  AppBlockerManager.swift
//  FocusGuard
//
//  Manages blocking and unblocking of distracting applications
//

import Foundation
import AppKit
import Combine

/// Manages the blocking of distracting applications during focus sessions
class AppBlockerManager: NSObject, ObservableObject {
    static let shared = AppBlockerManager()

    // MARK: - Published Properties
    @Published var isBlocking = false
    @Published var blockedAppsRunning: [RunningApp] = []
    @Published var accessibilityPermissionGranted = false

    // MARK: - Types
    struct RunningApp: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let bundleIdentifier: String
        let processIdentifier: pid_t

        func hash(into hasher: inout Hasher) {
            hasher.combine(bundleIdentifier)
            hasher.combine(processIdentifier)
        }

        static func == (lhs: RunningApp, rhs: RunningApp) -> Bool {
            return lhs.bundleIdentifier == rhs.bundleIdentifier && lhs.processIdentifier == rhs.processIdentifier
        }
    }

    // MARK: - Private Properties
    private var monitorTimer: Timer?
    private var blockedAppIdentifiers: Set<String> = []
    private var allowedAppIdentifiers: Set<String> = []
    private var terminatedApps: Set<String> = [] // Track apps we've terminated
    private var blockingWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    // Common distracting apps (default blocklist)
    static let defaultBlockedApps: [String: String] = [
        "com.apple.Safari": "Safari",
        "com.google.Chrome": "Google Chrome",
        "org.mozilla.firefox": "Firefox",
        "com.brave.Browser": "Brave Browser",
        "com.microsoft.edgemac": "Microsoft Edge",
        "com.apple.MobileSMS": "Messages",
        "com.apple.mail": "Mail",
        "com.tinyspeck.slackmacgap": "Slack",
        "com.hnc.Discord": "Discord",
        "us.zoom.xos": "Zoom",
        "com.spotify.client": "Spotify",
        "com.apple.Music": "Music",
        "com.apple.TV": "Apple TV",
        "com.netflix.Netflix": "Netflix",
        "com.twitter.twitter-mac": "Twitter",
        "com.facebook.Facebook": "Facebook",
        "com.instagram.Instagram": "Instagram",
        "com.reddit.Reddit": "Reddit",
        "tv.twitch.TwitchApp": "Twitch",
        "com.apple.AppStore": "App Store",
        "com.apple.news": "News",
        "com.apple.stocks": "Stocks",
        "com.valvesoftware.steam": "Steam",
        "com.epicgames.EpicGamesLauncher": "Epic Games",
    ]

    // Apps that should never be blocked
    static let systemApps: Set<String> = [
        "com.apple.finder",
        "com.apple.systempreferences",
        "com.apple.System-Preferences",
        "com.apple.Terminal",
        "com.focusguard.FocusGuard",
        "com.apple.ActivityMonitor",
        "com.apple.keychainaccess",
        "com.apple.SecurityAgent",
    ]

    // MARK: - Initialization
    private override init() {
        super.init()
        checkAccessibilityPermission()
    }

    // MARK: - Public Methods

    /// Start blocking apps with the given configuration
    func startBlocking(blockedApps: Set<String>, allowedApps: Set<String>) {
        self.blockedAppIdentifiers = blockedApps.subtracting(Self.systemApps)
        self.allowedAppIdentifiers = allowedApps.union(Self.systemApps)
        self.terminatedApps.removeAll()

        isBlocking = true
        startMonitoring()
        terminateBlockedApps()

        // Setup notification for new app launches
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidLaunch(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
    }

    /// Stop blocking apps
    func stopBlocking() {
        isBlocking = false
        stopMonitoring()
        terminatedApps.removeAll()
        blockedAppsRunning.removeAll()

        NSWorkspace.shared.notificationCenter.removeObserver(
            self,
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
    }

    /// Check if a specific app is blocked
    func isAppBlocked(_ bundleIdentifier: String) -> Bool {
        guard isBlocking else { return false }

        // If we have an allowlist and this app is in it, it's not blocked
        if !allowedAppIdentifiers.isEmpty && allowedAppIdentifiers.contains(bundleIdentifier) {
            return false
        }

        // If the app is in the blocklist, it's blocked
        if blockedAppIdentifiers.contains(bundleIdentifier) {
            return true
        }

        // If allowlist mode is active and app is not in allowlist, it's blocked
        if !allowedAppIdentifiers.isEmpty && !allowedAppIdentifiers.contains(bundleIdentifier) {
            // Except for system apps
            if Self.systemApps.contains(bundleIdentifier) {
                return false
            }
            return true
        }

        return false
    }

    /// Request accessibility permission
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        DispatchQueue.main.async {
            self.accessibilityPermissionGranted = accessEnabled
        }
    }

    /// Check current accessibility permission status
    func checkAccessibilityPermission() {
        let accessEnabled = AXIsProcessTrusted()
        DispatchQueue.main.async {
            self.accessibilityPermissionGranted = accessEnabled
        }
    }

    // MARK: - Private Methods

    private func startMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkRunningApps()
        }
    }

    private func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    private func checkRunningApps() {
        let runningApps = NSWorkspace.shared.runningApplications

        var blockedRunning: [RunningApp] = []

        for app in runningApps {
            guard let bundleId = app.bundleIdentifier else { continue }

            if isAppBlocked(bundleId) {
                blockedRunning.append(RunningApp(
                    name: app.localizedName ?? bundleId,
                    bundleIdentifier: bundleId,
                    processIdentifier: app.processIdentifier
                ))

                // Terminate the blocked app
                terminateApp(app)
            }
        }

        DispatchQueue.main.async {
            self.blockedAppsRunning = blockedRunning
        }
    }

    private func terminateBlockedApps() {
        let runningApps = NSWorkspace.shared.runningApplications

        for app in runningApps {
            guard let bundleId = app.bundleIdentifier else { continue }

            if isAppBlocked(bundleId) {
                terminateApp(app)
            }
        }
    }

    private func terminateApp(_ app: NSRunningApplication) {
        guard let bundleId = app.bundleIdentifier else { return }

        // Try graceful termination first
        if !app.terminate() {
            // Force terminate if graceful fails
            app.forceTerminate()
        }

        terminatedApps.insert(bundleId)

        // Show notification
        showBlockedNotification(appName: app.localizedName ?? bundleId)
    }

    @objc private func appDidLaunch(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier else { return }

        if isAppBlocked(bundleId) {
            // Small delay to let the app finish launching before terminating
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.terminateApp(app)
            }
        }
    }

    private func showBlockedNotification(appName: String) {
        let notification = NSUserNotification()
        notification.title = "App Blocked"
        notification.informativeText = "\(appName) was blocked. Complete your focus session to unlock."
        notification.soundName = NSUserNotificationDefaultSoundName

        NSUserNotificationCenter.default.deliver(notification)
    }

    /// Show a blocking overlay window
    func showBlockingOverlay(message: String) {
        guard blockingWindow == nil else { return }

        let screen = NSScreen.main ?? NSScreen.screens[0]
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .screenSaver
        window.backgroundColor = NSColor.black.withAlphaComponent(0.9)
        window.isOpaque = false
        window.ignoresMouseEvents = false

        let contentView = NSHostingView(rootView: BlockingOverlayView(message: message))
        window.contentView = contentView

        window.makeKeyAndOrderFront(nil)
        blockingWindow = window
    }

    /// Hide the blocking overlay
    func hideBlockingOverlay() {
        blockingWindow?.close()
        blockingWindow = nil
    }
}

// MARK: - Blocking Overlay View
import SwiftUI

struct BlockingOverlayView: View {
    let message: String
    @StateObject private var settings = SettingsManager.shared

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "eye.slash.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)

            Text("Focus Session Active")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(message)
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(spacing: 10) {
                Text("Need to unlock?")
                    .foregroundColor(.white.opacity(0.6))

                Text("Contact: \(settings.bypassEmail)")
                    .foregroundColor(.blue)
                    .underline()

                Button("Copy Email") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(settings.bypassEmail, forType: .string)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
