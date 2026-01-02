//
//  SettingsManager.swift
//  FocusGuard
//
//  Manages user preferences and app settings with persistence
//

import Foundation
import Combine
import SwiftUI

/// Manages all user-configurable settings for FocusGuard
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    // MARK: - User Defaults Keys
    private enum Keys {
        static let focusHoursRequired = "focusHoursRequired"
        static let rewardAmount = "rewardAmount"
        static let rewardCurrency = "rewardCurrency"
        static let bypassEmail = "bypassEmail"
        static let blockedApps = "blockedApps"
        static let allowedApps = "allowedApps"
        static let useAllowlistMode = "useAllowlistMode"
        static let breakDuration = "breakDuration"
        static let breakInterval = "breakInterval"
        static let enableBreaks = "enableBreaks"
        static let distractionThreshold = "distractionThreshold"
        static let soundEnabled = "soundEnabled"
        static let notificationsEnabled = "notificationsEnabled"
        static let launchAtLogin = "launchAtLogin"
        static let darkModePreference = "darkModePreference"
        static let totalFocusTimeEarned = "totalFocusTimeEarned"
        static let totalRewardsEarned = "totalRewardsEarned"
        static let sessionsCompleted = "sessionsCompleted"
    }

    // MARK: - Published Properties (Settings)

    /// Hours of focus required to unlock apps (default 8 hours)
    @Published var focusHoursRequired: Double {
        didSet { save(focusHoursRequired, forKey: Keys.focusHoursRequired) }
    }

    /// Reward amount for completing focus goal
    @Published var rewardAmount: Double {
        didSet { save(rewardAmount, forKey: Keys.rewardAmount) }
    }

    /// Currency for reward display
    @Published var rewardCurrency: String {
        didSet { save(rewardCurrency, forKey: Keys.rewardCurrency) }
    }

    /// Email address for bypass requests
    @Published var bypassEmail: String {
        didSet { save(bypassEmail, forKey: Keys.bypassEmail) }
    }

    /// Bundle identifiers of apps to block
    @Published var blockedApps: Set<String> {
        didSet { saveStringSet(blockedApps, forKey: Keys.blockedApps) }
    }

    /// Bundle identifiers of apps to allow (allowlist mode)
    @Published var allowedApps: Set<String> {
        didSet { saveStringSet(allowedApps, forKey: Keys.allowedApps) }
    }

    /// Whether to use allowlist mode (only allow specific apps)
    @Published var useAllowlistMode: Bool {
        didSet { save(useAllowlistMode, forKey: Keys.useAllowlistMode) }
    }

    /// Break duration in minutes
    @Published var breakDuration: Int {
        didSet { save(breakDuration, forKey: Keys.breakDuration) }
    }

    /// Break interval in minutes (how often breaks are offered)
    @Published var breakInterval: Int {
        didSet { save(breakInterval, forKey: Keys.breakInterval) }
    }

    /// Whether breaks are enabled
    @Published var enableBreaks: Bool {
        didSet { save(enableBreaks, forKey: Keys.enableBreaks) }
    }

    /// Seconds of looking away before considered distracted
    @Published var distractionThreshold: Int {
        didSet { save(distractionThreshold, forKey: Keys.distractionThreshold) }
    }

    /// Whether sounds are enabled
    @Published var soundEnabled: Bool {
        didSet { save(soundEnabled, forKey: Keys.soundEnabled) }
    }

    /// Whether notifications are enabled
    @Published var notificationsEnabled: Bool {
        didSet { save(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }

    /// Whether app launches at login
    @Published var launchAtLogin: Bool {
        didSet {
            save(launchAtLogin, forKey: Keys.launchAtLogin)
            updateLaunchAtLogin(launchAtLogin)
        }
    }

    /// Dark mode preference: "system", "light", "dark"
    @Published var darkModePreference: String {
        didSet { save(darkModePreference, forKey: Keys.darkModePreference) }
    }

    // MARK: - Statistics (Read-Only for UI, managed internally)

    @Published private(set) var totalFocusTimeEarned: TimeInterval
    @Published private(set) var totalRewardsEarned: Double
    @Published private(set) var sessionsCompleted: Int

    // MARK: - Initialization

    private init() {
        let defaults = UserDefaults.standard

        // Load all settings with defaults
        self.focusHoursRequired = defaults.double(forKey: Keys.focusHoursRequired)
        if self.focusHoursRequired == 0 { self.focusHoursRequired = 8.0 }

        self.rewardAmount = defaults.double(forKey: Keys.rewardAmount)
        if self.rewardAmount == 0 { self.rewardAmount = 50.0 }

        self.rewardCurrency = defaults.string(forKey: Keys.rewardCurrency) ?? "$"

        self.bypassEmail = defaults.string(forKey: Keys.bypassEmail) ?? "support@focusguard.app"

        self.blockedApps = Self.loadStringSet(forKey: Keys.blockedApps) ?? Set(AppBlockerManager.defaultBlockedApps.keys)

        self.allowedApps = Self.loadStringSet(forKey: Keys.allowedApps) ?? []

        self.useAllowlistMode = defaults.bool(forKey: Keys.useAllowlistMode)

        self.breakDuration = defaults.integer(forKey: Keys.breakDuration)
        if self.breakDuration == 0 { self.breakDuration = 5 }

        self.breakInterval = defaults.integer(forKey: Keys.breakInterval)
        if self.breakInterval == 0 { self.breakInterval = 60 }

        self.enableBreaks = defaults.object(forKey: Keys.enableBreaks) as? Bool ?? true

        self.distractionThreshold = defaults.integer(forKey: Keys.distractionThreshold)
        if self.distractionThreshold == 0 { self.distractionThreshold = 3 }

        self.soundEnabled = defaults.object(forKey: Keys.soundEnabled) as? Bool ?? true
        self.notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.darkModePreference = defaults.string(forKey: Keys.darkModePreference) ?? "system"

        // Statistics
        self.totalFocusTimeEarned = defaults.double(forKey: Keys.totalFocusTimeEarned)
        self.totalRewardsEarned = defaults.double(forKey: Keys.totalRewardsEarned)
        self.sessionsCompleted = defaults.integer(forKey: Keys.sessionsCompleted)
    }

    // MARK: - Public Methods

    /// Add focus time to statistics
    func addFocusTime(_ time: TimeInterval) {
        totalFocusTimeEarned += time
        save(totalFocusTimeEarned, forKey: Keys.totalFocusTimeEarned)
    }

    /// Record a completed session
    func recordCompletedSession(focusTime: TimeInterval, reward: Double) {
        totalFocusTimeEarned += focusTime
        totalRewardsEarned += reward
        sessionsCompleted += 1

        save(totalFocusTimeEarned, forKey: Keys.totalFocusTimeEarned)
        save(totalRewardsEarned, forKey: Keys.totalRewardsEarned)
        save(sessionsCompleted, forKey: Keys.sessionsCompleted)
    }

    /// Reset all statistics
    func resetStatistics() {
        totalFocusTimeEarned = 0
        totalRewardsEarned = 0
        sessionsCompleted = 0

        save(totalFocusTimeEarned, forKey: Keys.totalFocusTimeEarned)
        save(totalRewardsEarned, forKey: Keys.totalRewardsEarned)
        save(sessionsCompleted, forKey: Keys.sessionsCompleted)
    }

    /// Reset all settings to defaults
    func resetToDefaults() {
        focusHoursRequired = 8.0
        rewardAmount = 50.0
        rewardCurrency = "$"
        bypassEmail = "support@focusguard.app"
        blockedApps = Set(AppBlockerManager.defaultBlockedApps.keys)
        allowedApps = []
        useAllowlistMode = false
        breakDuration = 5
        breakInterval = 60
        enableBreaks = true
        distractionThreshold = 3
        soundEnabled = true
        notificationsEnabled = true
        launchAtLogin = false
        darkModePreference = "system"
    }

    /// Get formatted reward string
    var formattedReward: String {
        return "\(rewardCurrency)\(String(format: "%.2f", rewardAmount))"
    }

    /// Get focus duration as TimeInterval
    var focusDurationRequired: TimeInterval {
        return focusHoursRequired * 3600
    }

    // MARK: - Private Methods

    private func save<T>(_ value: T, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    private func saveStringSet(_ set: Set<String>, forKey key: String) {
        UserDefaults.standard.set(Array(set), forKey: key)
    }

    private static func loadStringSet(forKey key: String) -> Set<String>? {
        guard let array = UserDefaults.standard.stringArray(forKey: key) else { return nil }
        return Set(array)
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        // Note: In a real app, you would use SMLoginItemSetEnabled or ServiceManagement
        // This is a simplified placeholder
        print("Launch at login set to: \(enabled)")
    }
}

// MARK: - App Info
extension SettingsManager {
    /// List of common apps with display names for the UI
    static let commonApps: [(name: String, bundleId: String, category: String)] = [
        // Browsers
        ("Safari", "com.apple.Safari", "Browsers"),
        ("Google Chrome", "com.google.Chrome", "Browsers"),
        ("Firefox", "org.mozilla.firefox", "Browsers"),
        ("Brave", "com.brave.Browser", "Browsers"),
        ("Microsoft Edge", "com.microsoft.edgemac", "Browsers"),
        ("Arc", "company.thebrowser.Browser", "Browsers"),

        // Communication
        ("Messages", "com.apple.MobileSMS", "Communication"),
        ("Mail", "com.apple.mail", "Communication"),
        ("Slack", "com.tinyspeck.slackmacgap", "Communication"),
        ("Discord", "com.hnc.Discord", "Communication"),
        ("Zoom", "us.zoom.xos", "Communication"),
        ("Microsoft Teams", "com.microsoft.teams", "Communication"),
        ("WhatsApp", "net.whatsapp.WhatsApp", "Communication"),
        ("Telegram", "ru.keepcoder.Telegram", "Communication"),

        // Social Media
        ("Twitter/X", "com.twitter.twitter-mac", "Social Media"),
        ("Facebook", "com.facebook.Facebook", "Social Media"),
        ("Instagram", "com.instagram.Instagram", "Social Media"),
        ("Reddit", "com.reddit.Reddit", "Social Media"),
        ("TikTok", "com.ss.mac.CapCut", "Social Media"),
        ("LinkedIn", "com.linkedin.LinkedIn", "Social Media"),

        // Entertainment
        ("Spotify", "com.spotify.client", "Entertainment"),
        ("Apple Music", "com.apple.Music", "Entertainment"),
        ("Apple TV", "com.apple.TV", "Entertainment"),
        ("Netflix", "com.netflix.Netflix", "Entertainment"),
        ("YouTube", "com.google.Chrome", "Entertainment"), // Usually browser-based
        ("Twitch", "tv.twitch.TwitchApp", "Entertainment"),

        // Games
        ("Steam", "com.valvesoftware.steam", "Games"),
        ("Epic Games", "com.epicgames.EpicGamesLauncher", "Games"),
        ("Battle.net", "com.blizzard.battlenet", "Games"),
        ("GOG Galaxy", "com.gog.galaxy", "Games"),

        // Productivity (for allowlist)
        ("Xcode", "com.apple.dt.Xcode", "Productivity"),
        ("Visual Studio Code", "com.microsoft.VSCode", "Productivity"),
        ("Sublime Text", "com.sublimetext.4", "Productivity"),
        ("Terminal", "com.apple.Terminal", "Productivity"),
        ("iTerm", "com.googlecode.iterm2", "Productivity"),
        ("Notes", "com.apple.Notes", "Productivity"),
        ("Notion", "notion.id", "Productivity"),
        ("Obsidian", "md.obsidian", "Productivity"),
        ("Bear", "net.shinyfrog.bear", "Productivity"),
        ("Figma", "com.figma.Desktop", "Productivity"),
        ("Sketch", "com.bohemiancoding.sketch3", "Productivity"),
    ]

    /// Get apps grouped by category
    static var appsByCategory: [String: [(name: String, bundleId: String)]] {
        var result: [String: [(name: String, bundleId: String)]] = [:]
        for app in commonApps {
            if result[app.category] == nil {
                result[app.category] = []
            }
            result[app.category]?.append((name: app.name, bundleId: app.bundleId))
        }
        return result
    }
}
