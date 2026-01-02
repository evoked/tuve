//
//  SessionView.swift
//  FocusGuard
//
//  Active session view with real-time tracking display
//

import SwiftUI

struct SessionView: View {
    @EnvironmentObject var focusManager: FocusSessionManager
    @EnvironmentObject var settings: SettingsManager
    @StateObject private var eyeTracker = EyeTrackingManager.shared
    @State private var showBypassSheet = false

    var body: some View {
        ZStack {
            if focusManager.isSessionActive {
                activeSessionView
            } else {
                inactiveSessionView
            }
        }
        .sheet(isPresented: $showBypassSheet) {
            BypassRequestView()
        }
    }

    private var inactiveSessionView: some View {
        VStack(spacing: 30) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            Text("No Active Session")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Start a focus session from the dashboard to begin tracking your focus time.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Button(action: { focusManager.startSession() }) {
                Label("Start Focus Session", systemImage: "play.fill")
                    .font(.headline)
                    .padding()
                    .frame(minWidth: 200)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var activeSessionView: some View {
        VStack(spacing: 0) {
            // Top status bar
            sessionStatusBar
                .padding()
                .background(statusBackgroundColor)

            Divider()

            // Main content
            HStack(spacing: 30) {
                // Left: Focus display
                focusDisplaySection
                    .frame(maxWidth: .infinity)

                Divider()

                // Right: Stats and controls
                VStack(spacing: 20) {
                    sessionStatsSection
                    Divider()
                    sessionControlsSection
                    Spacer()
                }
                .frame(width: 280)
                .padding()
            }
        }
    }

    private var sessionStatusBar: some View {
        HStack {
            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                    .shadow(color: statusColor, radius: 4)

                Text(focusManager.sessionStatus.rawValue)
                    .font(.headline)
            }

            Spacer()

            // Eye tracking indicators
            HStack(spacing: 15) {
                HStack(spacing: 4) {
                    Image(systemName: eyeTracker.isFaceDetected ? "face.smiling.fill" : "face.dashed")
                        .foregroundColor(eyeTracker.isFaceDetected ? .green : .red)
                    Text("Face")
                        .font(.caption)
                }

                HStack(spacing: 4) {
                    Image(systemName: eyeTracker.isLookingAtScreen ? "eye.fill" : "eye.slash.fill")
                        .foregroundColor(eyeTracker.isLookingAtScreen ? .green : .red)
                    Text("Eyes")
                        .font(.caption)
                }

                if eyeTracker.isTracking {
                    Text("Confidence: \(Int(eyeTracker.eyeConfidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Time display
            Text(focusManager.formattedTimeAccumulated)
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.bold)
        }
    }

    private var statusBackgroundColor: Color {
        switch focusManager.sessionStatus {
        case .focusing: return Color.green.opacity(0.1)
        case .distracted: return Color.red.opacity(0.1)
        case .paused, .onBreak: return Color.orange.opacity(0.1)
        case .completed: return Color.purple.opacity(0.1)
        case .idle: return Color.clear
        }
    }

    private var statusColor: Color {
        switch focusManager.sessionStatus {
        case .focusing: return .green
        case .distracted: return .red
        case .paused, .onBreak: return .orange
        case .completed: return .purple
        case .idle: return .gray
        }
    }

    private var focusDisplaySection: some View {
        VStack(spacing: 30) {
            // Large progress ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 25)

                // Progress ring
                Circle()
                    .trim(from: 0, to: focusManager.progress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.blue, .purple, .pink, .blue]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 25, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: focusManager.progress)

                // Center content
                VStack(spacing: 10) {
                    Text("\(Int(focusManager.progress * 100))%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))

                    Text(focusManager.formattedTimeAccumulated)
                        .font(.system(size: 24, design: .monospaced))
                        .foregroundColor(.secondary)

                    Text("of \(FocusSessionManager.formatTimeHuman(settings.focusDurationRequired))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 280, height: 280)

            // Motivational message
            Text(motivationalMessage)
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            // Distraction warning
            if focusManager.sessionStatus == .distracted {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Look at your screen to continue earning focus time!")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
            }
        }
        .padding()
    }

    private var motivationalMessage: String {
        let progress = focusManager.progress
        switch progress {
        case 0..<0.25:
            return "Great start! Keep going..."
        case 0.25..<0.5:
            return "You're making progress!"
        case 0.5..<0.75:
            return "Halfway there! Stay focused!"
        case 0.75..<1.0:
            return "Almost there! Don't give up!"
        default:
            return "Congratulations! You did it!"
        }
    }

    private var sessionStatsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Session Stats")
                .font(.headline)

            StatRow(label: "Time Accumulated", value: focusManager.formattedTimeAccumulated)
            StatRow(label: "Time Remaining", value: focusManager.formattedTimeRemaining)
            StatRow(label: "Current Streak", value: FocusSessionManager.formatTime(focusManager.currentStreak))
            StatRow(label: "Distractions", value: "\(focusManager.distractionCount)")

            if let startTime = focusManager.sessionStartTime {
                StatRow(label: "Started At", value: formatStartTime(startTime))
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    private func formatStartTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private var sessionControlsSection: some View {
        VStack(spacing: 15) {
            Text("Controls")
                .font(.headline)

            // Break button
            if settings.enableBreaks && !focusManager.isPaused {
                Button(action: { focusManager.pauseSession() }) {
                    Label("Take a Break", systemImage: "pause.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            if focusManager.isPaused {
                Button(action: { focusManager.resumeSession() }) {
                    Label("Resume Focus", systemImage: "play.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            Divider()

            // Emergency bypass
            VStack(spacing: 8) {
                Text("Need to stop?")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button(action: { showBypassSheet = true }) {
                    Text("Request Emergency Bypass")
                        .font(.caption)
                }
                .buttonStyle(.link)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .monospacedDigit()
        }
        .font(.callout)
    }
}

// MARK: - Bypass Request View
struct BypassRequestView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var focusManager: FocusSessionManager
    @EnvironmentObject var settings: SettingsManager
    @State private var bypassCode = ""
    @State private var showError = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.lock.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("Emergency Bypass Request")
                .font(.title2)
                .fontWeight(.bold)

            Text("To bypass the focus session, you must contact:")
                .foregroundColor(.secondary)

            Button(action: copyEmail) {
                HStack {
                    Text(settings.bypassEmail)
                        .font(.headline)
                    Image(systemName: "doc.on.doc")
                }
            }
            .buttonStyle(.bordered)

            Divider()

            Text("If you have received a bypass code, enter it below:")
                .font(.caption)
                .foregroundColor(.secondary)

            TextField("Enter bypass code", text: $bypassCode)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)

            if showError {
                Text("Invalid bypass code")
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Submit Code") {
                    if focusManager.emergencyBypass(code: bypassCode) {
                        dismiss()
                    } else {
                        showError = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(bypassCode.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 400)
    }

    private func copyEmail() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(settings.bypassEmail, forType: .string)
    }
}

#Preview {
    SessionView()
        .environmentObject(FocusSessionManager.shared)
        .environmentObject(SettingsManager.shared)
}
