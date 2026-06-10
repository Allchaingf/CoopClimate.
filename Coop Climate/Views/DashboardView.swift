import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddGroup = false
    @State private var showAddReading = false
    @State private var showAlerts = false
    @State private var appeared = false
    @StateObject private var climateVM = ClimateViewModel()

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Good \(timeOfDay)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.appTextSecondary)
                            Text("Coop Climate")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(Color.appTextPrimary)
                        }
                        Spacer()
                        ZStack {
                            Circle().fill(Color.appPrimary.opacity(0.12)).frame(width: 44, height: 44)
                            Image(systemName: "thermometer.sun.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color.appPrimary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Main metric cards
                    if let latestReading = appState.climateReadings.sorted(by: { $0.date > $1.date }).first {
                        HStack(spacing: 12) {
                            MetricTile(
                                title: "Temperature",
                                value: formattedTemp(latestReading.temperature),
                                unit: appState.temperatureUnit == "Celsius" ? "°C" : "°F",
                                icon: "thermometer",
                                color: colorForTemp(latestReading.temperature),
                                trend: latestReading.riskLevel == .normal ? "Normal" : latestReading.riskLevel.rawValue
                            )
                            MetricTile(
                                title: "Humidity",
                                value: String(format: "%.0f", latestReading.humidity),
                                unit: "%",
                                icon: "humidity",
                                color: colorForHumidity(latestReading.humidity),
                                trend: latestReading.humidity > 75 ? "High" : latestReading.humidity < 40 ? "Low" : "OK"
                            )
                        }
                        .padding(.horizontal, 20)
                    } else {
                        AppCard {
                            VStack(spacing: 8) {
                                Image(systemName: "thermometer.sun")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color.appTextInactive)
                                Text("No readings yet")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.appTextInactive)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .padding(.horizontal, 20)
                    }

                    // Quick actions
                    HStack(spacing: 12) {
                        QuickActionButton(title: "Add Group", icon: "plus.circle.fill", color: Color.appPrimary) {
                            showAddGroup = true
                        }
                        QuickActionButton(title: "Add Record", icon: "square.and.pencil", color: Color.appBlue) {
                            showAddReading = true
                        }
                        QuickActionButton(title: "Open Alerts", icon: "bell.badge.fill", color: appState.activeAlerts.isEmpty ? Color.appTextInactive : Color.appDanger) {
                            showAlerts = true
                        }
                    }
                    .padding(.horizontal, 20)

                    // Bird groups
                    VStack(spacing: 12) {
                        SectionHeader(title: "Bird Groups")
                            .padding(.horizontal, 20)

                        if appState.birdGroups.isEmpty {
                            AppCard {
                                Text("No groups yet. Add your first flock.")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.appTextInactive)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .padding(.horizontal, 20)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(appState.birdGroups.prefix(5)) { group in
                                        BirdGroupCard(group: group, coop: appState.coops.first(where: { $0.id == group.coopId }))
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }

                    // Today's tasks
                    VStack(spacing: 12) {
                        SectionHeader(title: "Today's Tasks")
                            .padding(.horizontal, 20)

                        if appState.todayTasks.isEmpty {
                            AppCard {
                                Text("No tasks for today.")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.appTextInactive)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .padding(.horizontal, 20)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(appState.todayTasks.prefix(3)) { task in
                                    DashTaskRow(task: task)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }

                    // Alerts summary
                    if !appState.activeAlerts.isEmpty {
                        VStack(spacing: 12) {
                            SectionHeader(title: "Active Alerts", action: { showAlerts = true })
                                .padding(.horizontal, 20)

                            VStack(spacing: 8) {
                                ForEach(appState.activeAlerts.prefix(2)) { alert in
                                    DashAlertRow(alert: alert)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }

                    Spacer().frame(height: 100)
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAddGroup) { AddBirdGroupSheet() }
        .sheet(isPresented: $showAddReading) { AddClimateReadingSheet() }
        .sheet(isPresented: $showAlerts) { AlertsView().environmentObject(appState) }
    }

    private var timeOfDay: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Morning" }
        if h < 17 { return "Afternoon" }
        return "Evening"
    }

    private func formattedTemp(_ c: Double) -> String {
        if appState.temperatureUnit == "Fahrenheit" {
            return String(format: "%.1f", c * 9/5 + 32)
        }
        return String(format: "%.1f", c)
    }

    private func colorForTemp(_ t: Double) -> Color {
        if t > 32 || t < 8 { return Color.appDanger }
        if t > 28 || t < 12 { return Color.appWarning }
        return Color.appPrimary
    }

    private func colorForHumidity(_ h: Double) -> Color {
        if h > 85 || h < 30 { return Color.appDanger }
        if h > 75 || h < 40 { return Color.appWarning }
        return Color.appBlue
    }
}

// MARK: - Quick Action Button
private struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { pressed = false }
            }
            action()
        }) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.13))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.appTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
            .scaleEffect(pressed ? 0.93 : 1.0)
        }
    }
}

// MARK: - Bird group card
private struct BirdGroupCard: View {
    let group: BirdGroup
    let coop: Coop?

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "bird.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.appPrimary)
                    Spacer()
                    StatusBadge(label: group.status.rawValue, color: group.status.color)
                }
                Text(group.birdType)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.appTextPrimary)
                Text("\(group.count) birds · \(group.ageWeeks)w")
                    .font(.system(size: 12))
                    .foregroundColor(Color.appTextSecondary)
                if let coop = coop {
                    Text(coop.name)
                        .font(.system(size: 11))
                        .foregroundColor(Color.appTextInactive)
                }
            }
        }
        .frame(width: 150)
    }
}

// MARK: - Dashboard task row
private struct DashTaskRow: View {
    @EnvironmentObject var appState: AppState
    let task: CoopTask

    var body: some View {
        AppCard {
            HStack(spacing: 12) {
                Button(action: { appState.toggleTask(task) }) {
                    ZStack {
                        Circle()
                            .stroke(task.isDone ? Color.appPrimary : Color.appDivider, lineWidth: 2)
                            .frame(width: 24, height: 24)
                        if task.isDone {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.appPrimary)
                        }
                    }
                }
                Image(systemName: task.category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color.appBlue)
                    .frame(width: 28)
                Text(task.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(task.isDone ? Color.appTextInactive : Color.appTextPrimary)
                    .strikethrough(task.isDone)
                Spacer()
            }
        }
    }
}

// MARK: - Dashboard alert row
private struct DashAlertRow: View {
    let alert: ClimateAlert

    var body: some View {
        AppCard {
            HStack(spacing: 12) {
                Image(systemName: alert.type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(alert.type.color)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.appTextPrimary)
                    Text(alert.message)
                        .font(.system(size: 12))
                        .foregroundColor(Color.appTextSecondary)
                        .lineLimit(2)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Add Bird Group Sheet
struct AddBirdGroupSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var vm = BirdGroupsViewModel()
    @State private var showError = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    AppTextField(placeholder: "Bird Type (e.g. Chickens)", text: $vm.newBirdType, icon: "bird")
                    AppTextField(placeholder: "Count", text: $vm.newCount, icon: "number")
                    AppTextField(placeholder: "Age (weeks)", text: $vm.newAge, icon: "calendar")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Coop").font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextSecondary)
                        Picker("Coop", selection: $vm.newCoopId) {
                            Text("None").tag(UUID?.none)
                            ForEach(appState.coops) { coop in
                                Text(coop.name).tag(Optional(coop.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(10)
                        .background(Color.appSecondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Status").font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextSecondary)
                        Picker("Status", selection: $vm.newStatus) {
                            ForEach(BirdGroup.GroupStatus.allCases, id: \.self) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    AppTextField(placeholder: "Notes", text: $vm.newNotes, icon: "note.text")

                    if showError {
                        Text("Please fill in all required fields.")
                            .font(.system(size: 13))
                            .foregroundColor(Color.appDanger)
                    }

                    PrimaryButton("Save Group", icon: "checkmark") {
                        if vm.saveGroup(appState: appState) {
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            showError = true
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Add Bird Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(Color.appPrimary)
                }
            }
        }
    }
}

// MARK: - Add Climate Reading Sheet
struct AddClimateReadingSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var vm = ClimateViewModel()
    @State private var showError = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Coop *").font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextSecondary)
                        Picker("Coop", selection: $vm.selectedCoopId) {
                            Text("Select Coop").tag(UUID?.none)
                            ForEach(appState.coops) { coop in
                                Text(coop.name).tag(Optional(coop.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(10)
                        .background(Color.appSecondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    AppTextField(placeholder: "Temperature (°C)", text: $vm.newTemperature, icon: "thermometer")
                    AppTextField(placeholder: "Humidity (%)", text: $vm.newHumidity, icon: "humidity")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ventilation").font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextSecondary)
                        Picker("Ventilation", selection: $vm.newVentilation) {
                            ForEach(ClimateReading.VentilationLevel.allCases, id: \.self) { v in
                                Text(v.rawValue).tag(v)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    AppTextField(placeholder: "Notes", text: $vm.newNotes, icon: "note.text")

                    if showError {
                        Text("Please select a coop and enter valid values.")
                            .font(.system(size: 13))
                            .foregroundColor(Color.appDanger)
                    }

                    PrimaryButton("Save Record", icon: "checkmark") {
                        if vm.saveReading(appState: appState) {
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            showError = true
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Add Climate Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(Color.appPrimary)
                }
            }
        }
    }
}
