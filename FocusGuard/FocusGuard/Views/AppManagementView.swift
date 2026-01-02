//
//  AppManagementView.swift
//  FocusGuard
//
//  Manage blocked and allowed applications
//

import SwiftUI
import AppKit

struct AppManagementView: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var searchText = ""
    @State private var selectedCategory: String = "All"
    @State private var showAddCustomApp = false

    private var categories: [String] {
        ["All"] + Array(SettingsManager.appsByCategory.keys).sorted()
    }

    private var filteredApps: [(name: String, bundleId: String, category: String)] {
        var apps = SettingsManager.commonApps

        // Filter by category
        if selectedCategory != "All" {
            apps = apps.filter { $0.category == selectedCategory }
        }

        // Filter by search text
        if !searchText.isEmpty {
            apps = apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        return apps
    }

    var body: some View {
        VStack(spacing: 0) {
            // Mode toggle
            modeToggleSection
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            HStack(spacing: 0) {
                // Left side: App list
                appListSection
                    .frame(maxWidth: .infinity)

                Divider()

                // Right side: Selected apps
                selectedAppsSection
                    .frame(width: 300)
            }
        }
        .navigationTitle("App Management")
        .sheet(isPresented: $showAddCustomApp) {
            AddCustomAppView()
        }
    }

    private var modeToggleSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Blocking Mode")
                .font(.headline)

            Picker("Mode", selection: $settings.useAllowlistMode) {
                Text("Block List (block specific apps)").tag(false)
                Text("Allow List (only allow specific apps)").tag(true)
            }
            .pickerStyle(.segmented)

            Text(settings.useAllowlistMode
                 ? "Only the apps you select below will be accessible during focus sessions. All other apps will be blocked."
                 : "The apps you select below will be blocked during focus sessions. All other apps will remain accessible.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var appListSection: some View {
        VStack(spacing: 0) {
            // Search and filter bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search apps...", text: $searchText)
                    .textFieldStyle(.plain)

                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .frame(width: 150)

                Button(action: { showAddCustomApp = true }) {
                    Label("Add Custom", systemImage: "plus")
                }
            }
            .padding()

            Divider()

            // App list
            List {
                ForEach(filteredApps, id: \.bundleId) { app in
                    AppRowView(
                        name: app.name,
                        bundleId: app.bundleId,
                        category: app.category,
                        isSelected: isAppSelected(app.bundleId),
                        onToggle: { toggleApp(app.bundleId) }
                    )
                }
            }
        }
    }

    private var selectedAppsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(settings.useAllowlistMode ? "Allowed Apps" : "Blocked Apps")
                    .font(.headline)
                Spacer()
                Text("\(selectedAppsCount)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
            }
            .padding()

            Divider()

            if selectedAppsCount == 0 {
                VStack {
                    Spacer()
                    Text("No apps selected")
                        .foregroundColor(.secondary)
                    Text(settings.useAllowlistMode
                         ? "Add apps to allow during focus"
                         : "Add apps to block during focus")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(selectedApps, id: \.self) { bundleId in
                        HStack {
                            if let appInfo = SettingsManager.commonApps.first(where: { $0.bundleId == bundleId }) {
                                Text(appInfo.name)
                            } else {
                                Text(bundleId)
                                    .font(.caption)
                            }
                            Spacer()
                            Button(action: { toggleApp(bundleId) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Divider()

            // Quick actions
            VStack(spacing: 10) {
                Button("Select All Distracting Apps") {
                    selectDefaultDistractingApps()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                Button("Clear All") {
                    clearAllApps()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }

    // MARK: - Helper Methods

    private var selectedApps: [String] {
        Array(settings.useAllowlistMode ? settings.allowedApps : settings.blockedApps).sorted()
    }

    private var selectedAppsCount: Int {
        settings.useAllowlistMode ? settings.allowedApps.count : settings.blockedApps.count
    }

    private func isAppSelected(_ bundleId: String) -> Bool {
        if settings.useAllowlistMode {
            return settings.allowedApps.contains(bundleId)
        } else {
            return settings.blockedApps.contains(bundleId)
        }
    }

    private func toggleApp(_ bundleId: String) {
        if settings.useAllowlistMode {
            if settings.allowedApps.contains(bundleId) {
                settings.allowedApps.remove(bundleId)
            } else {
                settings.allowedApps.insert(bundleId)
            }
        } else {
            if settings.blockedApps.contains(bundleId) {
                settings.blockedApps.remove(bundleId)
            } else {
                settings.blockedApps.insert(bundleId)
            }
        }
    }

    private func selectDefaultDistractingApps() {
        if settings.useAllowlistMode {
            // For allowlist, add productivity apps
            let productivityApps = SettingsManager.commonApps
                .filter { $0.category == "Productivity" }
                .map { $0.bundleId }
            settings.allowedApps = settings.allowedApps.union(Set(productivityApps))
        } else {
            // For blocklist, add all default blocked apps
            settings.blockedApps = Set(AppBlockerManager.defaultBlockedApps.keys)
        }
    }

    private func clearAllApps() {
        if settings.useAllowlistMode {
            settings.allowedApps.removeAll()
        } else {
            settings.blockedApps.removeAll()
        }
    }
}

// MARK: - App Row View
struct AppRowView: View {
    let name: String
    let bundleId: String
    let category: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack {
            // App icon placeholder
            Image(systemName: iconForCategory(category))
                .font(.title2)
                .foregroundColor(colorForCategory(category))
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                Text(bundleId)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(category)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(colorForCategory(category).opacity(0.2))
                .cornerRadius(8)

            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }

    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Browsers": return "globe"
        case "Communication": return "message.fill"
        case "Social Media": return "person.2.fill"
        case "Entertainment": return "play.circle.fill"
        case "Games": return "gamecontroller.fill"
        case "Productivity": return "doc.text.fill"
        default: return "app.fill"
        }
    }

    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Browsers": return .blue
        case "Communication": return .green
        case "Social Media": return .pink
        case "Entertainment": return .purple
        case "Games": return .orange
        case "Productivity": return .teal
        default: return .gray
        }
    }
}

// MARK: - Add Custom App View
struct AddCustomAppView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: SettingsManager
    @State private var customBundleId = ""
    @State private var runningApps: [NSRunningApplication] = []

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Custom Application")
                .font(.headline)

            // Manual entry
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter Bundle Identifier:")
                    .font(.subheadline)

                HStack {
                    TextField("com.example.app", text: $customBundleId)
                        .textFieldStyle(.roundedBorder)

                    Button("Add") {
                        addCustomApp(customBundleId)
                    }
                    .disabled(customBundleId.isEmpty)
                }
            }

            Divider()

            // Running apps
            VStack(alignment: .leading, spacing: 8) {
                Text("Or select from running applications:")
                    .font(.subheadline)

                List(runningApps, id: \.processIdentifier) { app in
                    if let bundleId = app.bundleIdentifier {
                        HStack {
                            if let icon = app.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 24, height: 24)
                            }
                            VStack(alignment: .leading) {
                                Text(app.localizedName ?? "Unknown")
                                Text(bundleId)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Add") {
                                addCustomApp(bundleId)
                            }
                        }
                    }
                }
                .frame(height: 200)
            }

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 450)
        .onAppear {
            loadRunningApps()
        }
    }

    private func loadRunningApps() {
        runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.bundleIdentifier != nil && $0.activationPolicy == .regular }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }

    private func addCustomApp(_ bundleId: String) {
        if settings.useAllowlistMode {
            settings.allowedApps.insert(bundleId)
        } else {
            settings.blockedApps.insert(bundleId)
        }
        customBundleId = ""
    }
}

#Preview {
    AppManagementView()
        .environmentObject(SettingsManager.shared)
}
