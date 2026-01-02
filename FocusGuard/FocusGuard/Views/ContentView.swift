//
//  ContentView.swift
//  FocusGuard
//
//  Main content view with navigation between dashboard, session, and settings
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var focusManager: FocusSessionManager
    @EnvironmentObject var settings: SettingsManager
    @State private var selectedTab: Tab = .dashboard

    enum Tab {
        case dashboard
        case session
        case apps
        case settings
        case stats
    }

    var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            detailContent
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    private var sidebarContent: some View {
        List(selection: $selectedTab) {
            Section("Focus") {
                Label("Dashboard", systemImage: "house.fill")
                    .tag(Tab.dashboard)

                Label("Session", systemImage: "eye.circle.fill")
                    .tag(Tab.session)
            }

            Section("Configure") {
                Label("Blocked Apps", systemImage: "xmark.app.fill")
                    .tag(Tab.apps)

                Label("Settings", systemImage: "gear")
                    .tag(Tab.settings)
            }

            Section("Progress") {
                Label("Statistics", systemImage: "chart.bar.fill")
                    .tag(Tab.stats)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selectedTab {
        case .dashboard:
            DashboardView()
        case .session:
            SessionView()
        case .apps:
            AppManagementView()
        case .settings:
            SettingsView()
        case .stats:
            StatisticsView()
        }
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var focusManager: FocusSessionManager
    @EnvironmentObject var settings: SettingsManager
    @StateObject private var eyeTracker = EyeTrackingManager.shared
    @StateObject private var appBlocker = AppBlockerManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                headerSection

                // Quick Start Card
                if !focusManager.isSessionActive {
                    quickStartCard
                } else {
                    activeSessionCard
                }

                // Status Cards
                HStack(spacing: 20) {
                    statusCard(
                        title: "Focus Goal",
                        value: "\(Int(settings.focusHoursRequired))h",
                        icon: "target",
                        color: .blue
                    )

                    statusCard(
                        title: "Reward",
                        value: settings.formattedReward,
                        icon: "gift.fill",
                        color: .green
                    )

                    statusCard(
                        title: "Blocked Apps",
                        value: "\(settings.blockedApps.count)",
                        icon: "xmark.app.fill",
                        color: .red
                    )

                    statusCard(
                        title: "Sessions",
                        value: "\(settings.sessionsCompleted)",
                        icon: "checkmark.circle.fill",
                        color: .purple
                    )
                }
                .padding(.horizontal)

                // Permissions Status
                permissionsCard

                Spacer()
            }
            .padding()
        }
        .navigationTitle("FocusGuard")
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "eye.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("FocusGuard")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Track your focus. Block distractions. Earn rewards.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var quickStartCard: some View {
        VStack(spacing: 20) {
            Text("Ready to Focus?")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start a \(Int(settings.focusHoursRequired))-hour focus session to earn \(settings.formattedReward)")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { focusManager.startSession() }) {
                Label("Start Focus Session", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: 300)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(30)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var activeSessionCard: some View {
        VStack(spacing: 20) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                Text(focusManager.sessionStatus.rawValue)
                    .font(.headline)
            }

            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 15)

                Circle()
                    .trim(from: 0, to: focusManager.progress)
                    .stroke(
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: focusManager.progress)

                VStack {
                    Text(focusManager.formattedTimeAccumulated)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))

                    Text("/ \(FocusSessionManager.formatTimeHuman(settings.focusDurationRequired))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 180, height: 180)

            // Eye tracking status
            HStack(spacing: 20) {
                VStack {
                    Image(systemName: eyeTracker.isFaceDetected ? "face.smiling" : "face.dashed")
                        .font(.title)
                        .foregroundColor(eyeTracker.isFaceDetected ? .green : .orange)
                    Text("Face")
                        .font(.caption)
                }

                VStack {
                    Image(systemName: eyeTracker.isLookingAtScreen ? "eye.fill" : "eye.slash")
                        .font(.title)
                        .foregroundColor(eyeTracker.isLookingAtScreen ? .green : .orange)
                    Text("Focus")
                        .font(.caption)
                }

                VStack {
                    Text("\(focusManager.distractionCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("Distractions")
                        .font(.caption)
                }
            }
        }
        .padding(30)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
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

    private func statusCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    private var permissionsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Permissions Status")
                .font(.headline)

            HStack(spacing: 30) {
                permissionItem(
                    name: "Camera",
                    granted: eyeTracker.cameraPermissionGranted,
                    action: { eyeTracker.startTracking() }
                )

                permissionItem(
                    name: "Accessibility",
                    granted: appBlocker.accessibilityPermissionGranted,
                    action: { appBlocker.requestAccessibilityPermission() }
                )
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    private func permissionItem(name: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundColor(granted ? .green : .orange)

            Text(name)

            if !granted {
                Button("Enable") {
                    action()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(FocusSessionManager.shared)
        .environmentObject(SettingsManager.shared)
}
