//
//  FocusSessionManager.swift
//  FocusGuard
//
//  Manages focus sessions, tracking time and coordinating eye tracking with app blocking
//

import Foundation
import Combine
import AppKit

/// Manages the overall focus session state and coordination
class FocusSessionManager: ObservableObject {
    static let shared = FocusSessionManager()

    // MARK: - Published Properties
    @Published var isSessionActive = false
    @Published var isPaused = false
    @Published var focusTimeAccumulated: TimeInterval = 0
    @Published var sessionStartTime: Date?
    @Published var lastFocusStartTime: Date?
    @Published var distractionCount = 0
    @Published var currentStreak: TimeInterval = 0
    @Published var sessionStatus: SessionStatus = .idle
    @Published var canQuit = true // Controlled by session state

    // Progress
    var progress: Double {
        let required = SettingsManager.shared.focusDurationRequired
        guard required > 0 else { return 0 }
        return min(focusTimeAccumulated / required, 1.0)
    }

    var timeRemaining: TimeInterval {
        let required = SettingsManager.shared.focusDurationRequired
        return max(required - focusTimeAccumulated, 0)
    }

    var isGoalReached: Bool {
        return focusTimeAccumulated >= SettingsManager.shared.focusDurationRequired
    }

    // MARK: - Types
    enum SessionStatus: String {
        case idle = "Ready to Focus"
        case focusing = "Focused"
        case distracted = "Look at the screen!"
        case paused = "Paused"
        case completed = "Goal Reached!"
        case onBreak = "Taking a Break"
    }

    // MARK: - Private Properties
    private var focusTimer: Timer?
    private var lastUpdateTime: Date?
    private var eyeTrackingManager = EyeTrackingManager.shared
    private var appBlocker = AppBlockerManager.shared
    private var settings = SettingsManager.shared
    private var cancellables = Set<AnyCancellable>()

    // Break management
    private var breakStartTime: Date?
    private var lastBreakTime: Date?
    private var isOnBreak = false

    // MARK: - Initialization
    private init() {
        setupObservers()
    }

    // MARK: - Public Methods

    /// Start a new focus session
    func startSession() {
        guard !isSessionActive else { return }

        isSessionActive = true
        isPaused = false
        canQuit = false
        focusTimeAccumulated = 0
        distractionCount = 0
        currentStreak = 0
        sessionStartTime = Date()
        lastFocusStartTime = Date()
        lastBreakTime = Date()
        sessionStatus = .focusing

        // Start eye tracking
        eyeTrackingManager.startTracking()

        // Start app blocking
        if settings.useAllowlistMode {
            appBlocker.startBlocking(blockedApps: [], allowedApps: settings.allowedApps)
        } else {
            appBlocker.startBlocking(blockedApps: settings.blockedApps, allowedApps: [])
        }

        // Start the focus timer
        startFocusTimer()

        // Notification
        sendNotification(title: "Focus Session Started", body: "Stay focused! Your goal: \(settings.focusHoursRequired) hours")
    }

    /// End the current session (only if goal is reached or bypass)
    func endSession(forced: Bool = false) {
        guard isSessionActive else { return }

        if !forced && !isGoalReached {
            // Cannot end session unless goal is reached
            sendNotification(title: "Cannot End Session", body: "You must complete your focus goal or contact \(settings.bypassEmail)")
            return
        }

        // Stop everything
        eyeTrackingManager.stopTracking()
        appBlocker.stopBlocking()
        focusTimer?.invalidate()
        focusTimer = nil

        // Record statistics if completed
        if isGoalReached {
            let reward = settings.rewardAmount
            settings.recordCompletedSession(focusTime: focusTimeAccumulated, reward: reward)
            sessionStatus = .completed
            sendNotification(title: "Congratulations!", body: "You've earned \(settings.formattedReward)! Apps are now unblocked.")
        }

        isSessionActive = false
        canQuit = true
        isPaused = false
    }

    /// Emergency bypass (should require email confirmation in production)
    func emergencyBypass(code: String) -> Bool {
        // In a real app, this would validate against a server or time-based code
        // For demo purposes, we'll use a simple check
        let expectedCode = generateBypassCode()
        if code == expectedCode {
            endSession(forced: true)
            return true
        }
        return false
    }

    /// Pause the session (if breaks are enabled)
    func pauseSession() {
        guard isSessionActive && !isPaused && settings.enableBreaks else { return }

        // Check if enough time has passed since last break
        if let lastBreak = lastBreakTime {
            let timeSinceBreak = Date().timeIntervalSince(lastBreak)
            let requiredInterval = TimeInterval(settings.breakInterval * 60)
            if timeSinceBreak < requiredInterval {
                let remaining = Int((requiredInterval - timeSinceBreak) / 60)
                sendNotification(title: "Break Not Available", body: "You can take a break in \(remaining) minutes")
                return
            }
        }

        isPaused = true
        isOnBreak = true
        breakStartTime = Date()
        sessionStatus = .onBreak

        // Schedule auto-resume
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(settings.breakDuration * 60)) { [weak self] in
            self?.resumeSession()
        }
    }

    /// Resume from pause
    func resumeSession() {
        guard isPaused else { return }

        isPaused = false
        isOnBreak = false
        lastBreakTime = Date()
        lastFocusStartTime = Date()
        sessionStatus = .focusing

        sendNotification(title: "Break Ended", body: "Time to get back to focus!")
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // Observe eye tracking state
        eyeTrackingManager.$isLookingAtScreen
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLooking in
                self?.handleFocusStateChange(isLooking: isLooking)
            }
            .store(in: &cancellables)

        eyeTrackingManager.$isFaceDetected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] detected in
                if !detected && self?.isSessionActive == true && self?.isPaused == false {
                    self?.handleDistraction()
                }
            }
            .store(in: &cancellables)
    }

    private func startFocusTimer() {
        lastUpdateTime = Date()
        focusTimer?.invalidate()
        focusTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateFocusTime()
        }
    }

    private func updateFocusTime() {
        guard isSessionActive && !isPaused else { return }

        let now = Date()

        // Only count time if user is focused
        if eyeTrackingManager.isLookingAtScreen && eyeTrackingManager.isFaceDetected {
            if let lastUpdate = lastUpdateTime {
                let elapsed = now.timeIntervalSince(lastUpdate)
                focusTimeAccumulated += elapsed
                currentStreak += elapsed
            }
            sessionStatus = .focusing
        }

        lastUpdateTime = now

        // Check if goal is reached
        if isGoalReached {
            sessionStatus = .completed
            endSession()
        }
    }

    private func handleFocusStateChange(isLooking: Bool) {
        guard isSessionActive && !isPaused else { return }

        if isLooking {
            sessionStatus = .focusing
        } else {
            handleDistraction()
        }
    }

    private func handleDistraction() {
        guard isSessionActive && !isPaused else { return }

        distractionCount += 1
        currentStreak = 0
        sessionStatus = .distracted

        // Play alert sound if enabled
        if settings.soundEnabled {
            NSSound.beep()
        }

        // Show notification
        if settings.notificationsEnabled && distractionCount % 5 == 0 {
            sendNotification(title: "Stay Focused!", body: "Look at your screen to continue accumulating focus time")
        }
    }

    private func sendNotification(title: String, body: String) {
        guard settings.notificationsEnabled else { return }

        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = body
        notification.soundName = settings.soundEnabled ? NSUserNotificationDefaultSoundName : nil

        NSUserNotificationCenter.default.deliver(notification)
    }

    private func generateBypassCode() -> String {
        // Generate a time-based code (simplified for demo)
        // In production, this would involve server validation
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHH"
        let dateString = formatter.string(from: date)
        return String(dateString.hash.magnitude % 1000000).padding(toLength: 6, withPad: "0", startingAt: 0)
    }
}

// MARK: - Time Formatting Extensions
extension FocusSessionManager {
    /// Format time interval as HH:MM:SS
    static func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    /// Format time interval as human readable
    static func formatTimeHuman(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes) minutes"
        } else {
            return "Less than a minute"
        }
    }

    var formattedTimeAccumulated: String {
        Self.formatTime(focusTimeAccumulated)
    }

    var formattedTimeRemaining: String {
        Self.formatTime(timeRemaining)
    }
}
