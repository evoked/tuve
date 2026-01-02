//
//  SettingsView.swift
//  FocusGuard
//
//  User settings and preferences
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var focusManager: FocusSessionManager
    @State private var showResetConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Focus Settings
                focusSettingsSection

                Divider()

                // Reward Settings
                rewardSettingsSection

                Divider()

                // Break Settings
                breakSettingsSection

                Divider()

                // Bypass Settings
                bypassSettingsSection

                Divider()

                // Notification Settings
                notificationSettingsSection

                Divider()

                // General Settings
                generalSettingsSection

                Divider()

                // Reset Section
                resetSection
            }
            .padding(30)
        }
        .navigationTitle("Settings")
        .alert("Reset Settings?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                settings.resetToDefaults()
            }
        } message: {
            Text("This will reset all settings to their default values. Your statistics will not be affected.")
        }
    }

    // MARK: - Focus Settings
    private var focusSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("Focus Settings", systemImage: "target")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Focus Hours Required:")
                    Spacer()
                    Text("\(String(format: "%.1f", settings.focusHoursRequired)) hours")
                        .foregroundColor(.secondary)
                }

                Slider(value: $settings.focusHoursRequired, in: 0.5...12, step: 0.5)

                Text("You must accumulate this many hours of focused time to complete a session and unlock blocked apps.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Distraction Threshold:")
                    Spacer()
                    Text("\(settings.distractionThreshold) seconds")
                        .foregroundColor(.secondary)
                }

                Slider(value: Binding(
                    get: { Double(settings.distractionThreshold) },
                    set: { settings.distractionThreshold = Int($0) }
                ), in: 1...10, step: 1)

                Text("How many seconds of looking away before time stops accumulating.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(10)
        }
    }

    // MARK: - Reward Settings
    private var rewardSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("Reward Settings", systemImage: "gift.fill")
                .font(.headline)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Currency Symbol")
                        .font(.subheadline)
                    TextField("$", text: $settings.rewardCurrency)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Reward Amount")
                        .font(.subheadline)
                    TextField("Amount", value: $settings.rewardAmount, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Session Reward")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(settings.formattedReward)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(10)

            Text("This is the virtual reward you earn for completing each focus session. Use it to motivate yourself!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Break Settings
    private var breakSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("Break Settings", systemImage: "pause.circle.fill")
                .font(.headline)

            Toggle("Enable Breaks", isOn: $settings.enableBreaks)
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(10)

            if settings.enableBreaks {
                HStack(spacing: 30) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Break Duration")
                            .font(.subheadline)
                        Stepper("\(settings.breakDuration) minutes", value: $settings.breakDuration, in: 1...30)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Break Interval")
                            .font(.subheadline)
                        Stepper("\(settings.breakInterval) minutes", value: $settings.breakInterval, in: 15...120, step: 15)
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(10)

                Text("You can take a \(settings.breakDuration)-minute break every \(settings.breakInterval) minutes. Break time does not count towards your focus goal.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Bypass Settings
    private var bypassSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("Emergency Bypass", systemImage: "lock.shield.fill")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Bypass Contact Email")
                    .font(.subheadline)

                TextField("support@example.com", text: $settings.bypassEmail)
                    .textFieldStyle(.roundedBorder)

                Text("Users who need to end a session early must contact this email address to receive a bypass code. This ensures the blocking cannot be easily circumvented.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(10)

            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Important: Make sure this is an email you can access, or you may lock yourself out!")
                    .font(.caption)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }

    // MARK: - Notification Settings
    private var notificationSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("Notifications", systemImage: "bell.fill")
                .font(.headline)

            VStack(spacing: 12) {
                Toggle("Enable Notifications", isOn: $settings.notificationsEnabled)
                Toggle("Enable Sounds", isOn: $settings.soundEnabled)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(10)
        }
    }

    // MARK: - General Settings
    private var generalSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("General", systemImage: "gear")
                .font(.headline)

            VStack(spacing: 12) {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)

                HStack {
                    Text("Appearance")
                    Spacer()
                    Picker("", selection: $settings.darkModePreference) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .frame(width: 120)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(10)
        }
    }

    // MARK: - Reset Section
    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("Reset", systemImage: "arrow.counterclockwise")
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text("Reset All Settings")
                        .font(.subheadline)
                    Text("Restore default values for all settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Reset Settings") {
                    showResetConfirmation = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(10)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager.shared)
        .environmentObject(FocusSessionManager.shared)
}
