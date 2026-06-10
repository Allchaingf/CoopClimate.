import SwiftUI

struct AlertsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = AlertsViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter picker
                Picker("Filter", selection: $vm.filter) {
                    ForEach(AlertsViewModel.AlertFilter.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .padding(16)

                let filtered = vm.filteredAlerts(appState.alerts)

                if filtered.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 52))
                            .foregroundColor(Color.appPrimary)
                        Text("No alerts")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color.appTextPrimary)
                        Text("Everything looks good.")
                            .font(.system(size: 15))
                            .foregroundColor(Color.appTextSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(filtered) { alert in
                                AlertCard(alert: alert)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 100)
                    }
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Alerts")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Alert Card
private struct AlertCard: View {
    @EnvironmentObject var appState: AppState
    let alert: ClimateAlert
    @State private var showSnooze = false

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(alert.type.color.opacity(0.13))
                            .frame(width: 40, height: 40)
                        Image(systemName: alert.type.icon)
                            .font(.system(size: 18))
                            .foregroundColor(alert.type.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(alert.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color.appTextPrimary)
                        Text(relativeDate(alert.createdAt))
                            .font(.system(size: 11))
                            .foregroundColor(Color.appTextInactive)
                    }
                    Spacer()
                    if alert.isResolved {
                        StatusBadge(label: "Resolved", color: Color.appPrimary)
                    } else if alert.isSnoozed {
                        StatusBadge(label: "Snoozed", color: Color.appTextInactive)
                    }
                }

                Text(alert.message)
                    .font(.system(size: 13))
                    .foregroundColor(Color.appTextSecondary)

                if !alert.isResolved {
                    HStack(spacing: 10) {
                        Button(action: { appState.resolveAlert(alert) }) {
                            Text("Resolve")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.appPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        Button(action: { showSnooze = true }) {
                            Text("Snooze")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.appTextSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(hex: "E2E8F0"))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        Spacer()
                    }
                }
            }
        }
        .actionSheet(isPresented: $showSnooze) {
            ActionSheet(title: Text("Snooze for…"), buttons: [
                .default(Text("1 Hour")) {
                    appState.snoozeAlert(alert, until: Date().addingTimeInterval(3600))
                },
                .default(Text("4 Hours")) {
                    appState.snoozeAlert(alert, until: Date().addingTimeInterval(3600 * 4))
                },
                .default(Text("Tomorrow")) {
                    appState.snoozeAlert(alert, until: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
                },
                .cancel()
            ])
        }
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
