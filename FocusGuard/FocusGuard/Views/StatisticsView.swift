//
//  StatisticsView.swift
//  FocusGuard
//
//  Display user statistics and progress
//

import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var showResetConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                headerSection

                // Main stats cards
                mainStatsSection

                // Achievements
                achievementsSection

                // Reset button
                resetSection
            }
            .padding(30)
        }
        .navigationTitle("Statistics")
        .alert("Reset Statistics?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                settings.resetStatistics()
            }
        } message: {
            Text("This will permanently delete all your focus statistics. This action cannot be undone.")
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 50))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("Your Focus Journey")
                .font(.title)
                .fontWeight(.bold)

            Text("Track your progress and celebrate your achievements")
                .foregroundColor(.secondary)
        }
    }

    private var mainStatsSection: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                // Total Focus Time
                StatCard(
                    title: "Total Focus Time",
                    value: formatTotalTime(settings.totalFocusTimeEarned),
                    subtitle: "\(Int(settings.totalFocusTimeEarned / 3600)) hours accumulated",
                    icon: "clock.fill",
                    color: .blue
                )

                // Total Rewards
                StatCard(
                    title: "Total Rewards Earned",
                    value: "\(settings.rewardCurrency)\(String(format: "%.2f", settings.totalRewardsEarned))",
                    subtitle: "Keep earning!",
                    icon: "gift.fill",
                    color: .green
                )
            }

            HStack(spacing: 20) {
                // Sessions Completed
                StatCard(
                    title: "Sessions Completed",
                    value: "\(settings.sessionsCompleted)",
                    subtitle: sessionSubtitle,
                    icon: "checkmark.circle.fill",
                    color: .purple
                )

                // Average Session
                StatCard(
                    title: "Average Session",
                    value: formatAverageSession(),
                    subtitle: "per completed session",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                )
            }
        }
    }

    private var sessionSubtitle: String {
        switch settings.sessionsCompleted {
        case 0: return "Start your first session!"
        case 1: return "Great start!"
        case 2...5: return "Building momentum!"
        case 6...10: return "You're on a roll!"
        case 11...25: return "Excellent consistency!"
        case 26...50: return "Focus master!"
        default: return "Legendary focus!"
        }
    }

    private func formatTotalTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }

    private func formatAverageSession() -> String {
        guard settings.sessionsCompleted > 0 else { return "N/A" }
        let average = settings.totalFocusTimeEarned / Double(settings.sessionsCompleted)
        return formatTotalTime(average)
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Achievements")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                AchievementBadge(
                    title: "First Focus",
                    description: "Complete your first session",
                    icon: "star.fill",
                    color: .yellow,
                    isUnlocked: settings.sessionsCompleted >= 1
                )

                AchievementBadge(
                    title: "Week Warrior",
                    description: "Complete 7 sessions",
                    icon: "flame.fill",
                    color: .orange,
                    isUnlocked: settings.sessionsCompleted >= 7
                )

                AchievementBadge(
                    title: "Focus Master",
                    description: "Accumulate 24 hours",
                    icon: "crown.fill",
                    color: .purple,
                    isUnlocked: settings.totalFocusTimeEarned >= 24 * 3600
                )

                AchievementBadge(
                    title: "Centurion",
                    description: "Earn 100 in rewards",
                    icon: "dollarsign.circle.fill",
                    color: .green,
                    isUnlocked: settings.totalRewardsEarned >= 100
                )

                AchievementBadge(
                    title: "Dedicated",
                    description: "Complete 30 sessions",
                    icon: "medal.fill",
                    color: .blue,
                    isUnlocked: settings.sessionsCompleted >= 30
                )

                AchievementBadge(
                    title: "Time Lord",
                    description: "Accumulate 100 hours",
                    icon: "hourglass.tophalf.filled",
                    color: .red,
                    isUnlocked: settings.totalFocusTimeEarned >= 100 * 3600
                )
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(15)
    }

    private var resetSection: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Reset Statistics")
                    .font(.subheadline)
                Text("Clear all your focus history and start fresh")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("Reset All") {
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

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(15)
    }
}

// MARK: - Achievement Badge
struct AchievementBadge: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? color : Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isUnlocked ? .white : .gray)
            }

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if isUnlocked {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(12)
        .opacity(isUnlocked ? 1 : 0.6)
    }
}

#Preview {
    StatisticsView()
        .environmentObject(SettingsManager.shared)
}
