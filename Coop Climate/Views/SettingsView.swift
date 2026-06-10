import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var toastVisible = false
    @State private var toastMessage = ""
    @State private var showClearAlert = false
    @State private var showExport = false
    @State private var exportText = ""
    @State private var notificationPermission = false

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Appearance
                    SettingsSection(title: "Appearance", icon: "paintbrush.fill", color: Color.appPrimary) {
                        VStack(spacing: 0) {
                            SettingsPicker(
                                title: "Theme",
                                icon: "circle.lefthalf.filled",
                                selection: $appState.colorSchemeRaw,
                                options: [("system", "System"), ("light", "Light"), ("dark", "Dark")]
                            ) { value in
                                appState.colorSchemeRaw = value
                                showToast("Theme applied")
                            }
                        }
                    }

                    // Units
                    SettingsSection(title: "Units", icon: "ruler.fill", color: Color.appBlue) {
                        VStack(spacing: 0) {
                            SettingsPicker(
                                title: "Temperature",
                                icon: "thermometer",
                                selection: $appState.temperatureUnit,
                                options: [("Celsius", "Celsius (°C)"), ("Fahrenheit", "Fahrenheit (°F)")]
                            ) { value in
                                appState.temperatureUnit = value
                                showToast("Temperature unit saved")
                            }
                        }
                    }

                    // Notifications
                    SettingsSection(title: "Notifications", icon: "bell.fill", color: Color.appOrange) {
                        VStack(spacing: 0) {
                            SettingsToggle(
                                title: "Enable Notifications",
                                icon: "bell.badge",
                                isOn: $appState.notificationsEnabled
                            ) { enabled in
                                if enabled {
                                    NotificationManager.shared.requestPermission { granted in
                                        notificationPermission = granted
                                        if granted {
                                            applyNotifications()
                                            showToast("Notifications enabled")
                                        } else {
                                            appState.notificationsEnabled = false
                                            showToast("Permission denied — check Settings")
                                        }
                                    }
                                } else {
                                    NotificationManager.shared.cancelAllNotifications()
                                    showToast("Notifications disabled")
                                }
                            }

                            Divider().padding(.leading, 52)

                            SettingsToggle(
                                title: "Daily Care Reminder",
                                icon: "sun.max.fill",
                                isOn: $appState.dailyCareReminder
                            ) { _ in
                                applyNotifications()
                                showToast("Saved")
                            }
                            .disabled(!appState.notificationsEnabled)
                            .opacity(appState.notificationsEnabled ? 1 : 0.4)

                            Divider().padding(.leading, 52)

                            SettingsToggle(
                                title: "Health Check Reminder",
                                icon: "cross.fill",
                                isOn: $appState.healthCheckReminder
                            ) { _ in
                                applyNotifications()
                                showToast("Saved")
                            }
                            .disabled(!appState.notificationsEnabled)
                            .opacity(appState.notificationsEnabled ? 1 : 0.4)

                            Divider().padding(.leading, 52)

                            SettingsToggle(
                                title: "Low Stock Alert",
                                icon: "exclamationmark.circle.fill",
                                isOn: $appState.lowStockReminder
                            ) { _ in
                                applyNotifications()
                                showToast("Saved")
                            }
                            .disabled(!appState.notificationsEnabled)
                            .opacity(appState.notificationsEnabled ? 1 : 0.4)
                        }
                    }

                    // Data
                    SettingsSection(title: "Data & Backup", icon: "externaldrive.fill", color: Color.appWarning) {
                        VStack(spacing: 0) {
                            SettingsButton(title: "Export Data", icon: "square.and.arrow.up", color: Color.appBlue) {
                                exportText = appState.exportJSON()
                                showExport = true
                            }
                            Divider().padding(.leading, 52)
                            SettingsButton(title: "Clear All Data", icon: "trash.fill", color: Color.appDanger) {
                                showClearAlert = true
                            }
                        }
                    }

                    // App info
                    AppCard {
                        VStack(spacing: 8) {
                            Image(systemName: "thermometer.sun.fill")
                                .font(.system(size: 36))
                                .foregroundColor(Color.appPrimary)
                            Text("Coop Climate")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color.appTextPrimary)
                            Text("Version 1.0")
                                .font(.system(size: 13))
                                .foregroundColor(Color.appTextInactive)
                            Text("Smarter care for your flock.")
                                .font(.system(size: 13))
                                .foregroundColor(Color.appTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 100)
                }
                .padding(.top, 8)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .overlay(alignment: .top) {
            if toastVisible {
                ToastView(message: toastMessage, icon: "checkmark.circle.fill", color: Color.appPrimary)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .alert("Clear All Data", isPresented: $showClearAlert) {
            Button("Clear", role: .destructive) {
                appState.coops = []
                appState.birdGroups = []
                appState.climateReadings = []
                appState.sensors = []
                appState.alerts = []
                appState.tasks = []
                appState.expenses = []
                appState.notes = []
                appState.historyEntries = []
                appState.ventilationSchedules = []
                appState.saveAllData()
                showToast("All data cleared")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all coops, readings, and settings. This cannot be undone.")
        }
        .sheet(isPresented: $showExport) {
            ShareSheet(items: [exportText])
        }
    }

    private func applyNotifications() {
        NotificationManager.shared.applySettings(
            dailyCare: appState.dailyCareReminder && appState.notificationsEnabled,
            healthCheck: appState.healthCheckReminder && appState.notificationsEnabled,
            lowStock: appState.lowStockReminder && appState.notificationsEnabled
        )
    }

    private func showToast(_ message: String) {
        toastMessage = message
        withAnimation { toastVisible = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { toastVisible = false }
        }
    }
}

// MARK: - Settings Section
private struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content

    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title; self.icon = icon; self.color = color; self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 13)).foregroundColor(color)
                Text(title).font(.system(size: 13, weight: .semibold)).foregroundColor(Color.appTextInactive)
            }
            .padding(.horizontal, 20)

            AppCard(padding: 0) {
                content
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Settings Toggle
private struct SettingsToggle: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    let onChange: (Bool) -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color.appTextSecondary)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(Color.appTextPrimary)
            Spacer()
            Toggle("", isOn: Binding(
                get: { isOn },
                set: { val in isOn = val; onChange(val) }
            ))
            .tint(Color.appPrimary)
            .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

// MARK: - Settings Picker
private struct SettingsPicker: View {
    let title: String
    let icon: String
    @Binding var selection: String
    let options: [(String, String)]
    let onChange: (String) -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color.appTextSecondary)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(Color.appTextPrimary)
            Spacer()
            Menu {
                ForEach(options, id: \.0) { (value, label) in
                    Button(action: { selection = value; onChange(value) }) {
                        HStack {
                            Text(label)
                            if selection == value {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(options.first(where: { $0.0 == selection })?.1 ?? selection)
                        .font(.system(size: 14))
                        .foregroundColor(Color.appTextInactive)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(Color.appTextInactive)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

// MARK: - Settings Button
private struct SettingsButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(color)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(Color.appTextInactive)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
    }
}
