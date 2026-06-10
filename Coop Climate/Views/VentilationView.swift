import SwiftUI

struct VentilationView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = VentilationViewModel()
    @State private var toastVisible = false
    @State private var toastMessage = ""

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if appState.coops.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "wind")
                                .font(.system(size: 48))
                                .foregroundColor(Color.appTextInactive)
                            Text("Add a coop first to manage ventilation.")
                                .font(.system(size: 15))
                                .foregroundColor(Color.appTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 60)
                    } else {
                        // Coop selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(appState.coops) { coop in
                                    Button(action: {
                                        withAnimation(.spring()) { vm.selectedCoopId = coop.id }
                                    }) {
                                        Text(coop.name)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(vm.selectedCoopId == coop.id ? .white : Color.appTextSecondary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 9)
                                            .background(vm.selectedCoopId == coop.id ? Color.appCyan : Color.appCardBackground)
                                            .clipShape(Capsule())
                                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        if let coopId = vm.selectedCoopId {
                            let schedules = vm.filteredSchedules(appState.ventilationSchedules)

                            // Current ventilation status
                            if let latest = appState.latestReadingPerCoop[coopId] {
                                AppCard {
                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Current Level")
                                                .font(.system(size: 12)).foregroundColor(Color.appTextInactive)
                                            Text(latest.ventilationLevel.rawValue)
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(Color.appCyan)
                                        }
                                        Spacer()
                                        Image(systemName: "wind")
                                            .font(.system(size: 36))
                                            .foregroundColor(Color.appCyan.opacity(0.5))
                                    }
                                }
                                .padding(.horizontal, 20)

                                // Quick level controls
                                AppCard {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Set Ventilation Level")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color.appTextPrimary)
                                        HStack(spacing: 8) {
                                            ForEach(ClimateReading.VentilationLevel.allCases, id: \.self) { level in
                                                Button(action: {
                                                    updateVentilation(coopId: coopId, level: level)
                                                }) {
                                                    Text(level.rawValue)
                                                        .font(.system(size: 13, weight: .semibold))
                                                        .foregroundColor(latest.ventilationLevel == level ? .white : Color.appTextSecondary)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 8)
                                                        .background(latest.ventilationLevel == level ? Color.appCyan : Color(hex: "E2E8F0"))
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }

                            // Schedules
                            SectionHeader(title: "Schedules")
                                .padding(.horizontal, 20)

                            if schedules.isEmpty {
                                AppCard {
                                    Text("No schedules yet. Add one below.")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.appTextInactive)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                }
                                .padding(.horizontal, 20)
                            } else {
                                ForEach(schedules) { schedule in
                                    ScheduleCard(schedule: schedule)
                                        .padding(.horizontal, 20)
                                }
                            }

                            PrimaryButton("Add Schedule", icon: "plus") {
                                vm.showAddSchedule = true
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.top, 8)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Ventilation")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if vm.selectedCoopId == nil { vm.selectedCoopId = appState.coops.first?.id }
        }
        .sheet(isPresented: $vm.showAddSchedule) { AddScheduleSheet(vm: vm) }
        .overlay(alignment: .top) {
            if toastVisible {
                ToastView(message: toastMessage, icon: "checkmark.circle.fill", color: Color.appPrimary)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func updateVentilation(coopId: UUID, level: ClimateReading.VentilationLevel) {
        let reading = ClimateReading(
            coopId: coopId,
            temperature: appState.latestReadingPerCoop[coopId]?.temperature ?? 20,
            humidity: appState.latestReadingPerCoop[coopId]?.humidity ?? 60,
            ventilationLevel: level,
            notes: "Level updated manually"
        )
        appState.addClimateReading(reading)
        toastMessage = "Ventilation set to \(level.rawValue)"
        withAnimation { toastVisible = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { toastVisible = false }
        }
    }
}

// MARK: - Schedule Card
private struct ScheduleCard: View {
    @EnvironmentObject var appState: AppState
    let schedule: VentilationSchedule
    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private static let timeFmt: DateFormatter = { let f = DateFormatter(); f.timeStyle = .short; return f }()

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(Self.timeFmt.string(from: schedule.startTime)) – \(Self.timeFmt.string(from: schedule.endTime))")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color.appTextPrimary)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { schedule.isActive },
                        set: { val in
                            var updated = schedule; updated.isActive = val
                            appState.updateVentilationSchedule(updated)
                        }
                    ))
                    .tint(Color.appCyan)
                    .labelsHidden()
                }

                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { day in
                        Text(dayNames[day])
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(schedule.daysOfWeek.contains(day) ? .white : Color.appTextInactive)
                            .frame(width: 30, height: 24)
                            .background(schedule.daysOfWeek.contains(day) ? Color.appCyan : Color.appDivider)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }

                HStack(spacing: 16) {
                    Label(String(format: "Target T: %.0f°", schedule.targetTemperature), systemImage: "thermometer")
                        .font(.system(size: 12))
                        .foregroundColor(Color.appTextSecondary)
                    Label(String(format: "Target H: %.0f%%", schedule.targetHumidity), systemImage: "humidity")
                        .font(.system(size: 12))
                        .foregroundColor(Color.appTextSecondary)
                }

                Button(action: { appState.deleteVentilationSchedule(schedule) }) {
                    Text("Remove Schedule")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.appDanger)
                }
            }
        }
    }
}

// MARK: - Add Schedule Sheet
private struct AddScheduleSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var vm: VentilationViewModel
    @State private var showError = false
    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Time").font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextSecondary)
                        DatePicker("", selection: $vm.newStartTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .padding(10)
                            .background(Color.appSecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("End Time").font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextSecondary)
                        DatePicker("", selection: $vm.newEndTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .padding(10)
                            .background(Color.appSecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Days of Week").font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextSecondary)
                        HStack(spacing: 8) {
                            ForEach(0..<7, id: \.self) { day in
                                Button(action: {
                                    if vm.newDays.contains(day) { vm.newDays.remove(day) }
                                    else { vm.newDays.insert(day) }
                                }) {
                                    Text(dayNames[day])
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(vm.newDays.contains(day) ? .white : Color.appTextSecondary)
                                        .frame(width: 36, height: 30)
                                        .background(vm.newDays.contains(day) ? Color.appCyan : Color.appDivider)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Temperature: \(String(format: "%.0f", vm.newTargetTemperature))°C")
                            .font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextSecondary)
                        Slider(value: $vm.newTargetTemperature, in: 5...40, step: 1)
                            .tint(Color.appOrange)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Humidity: \(String(format: "%.0f", vm.newTargetHumidity))%")
                            .font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextSecondary)
                        Slider(value: $vm.newTargetHumidity, in: 30...90, step: 1)
                            .tint(Color.appBlue)
                    }

                    if showError {
                        Text("Please select a coop first.").font(.system(size: 13)).foregroundColor(Color.appDanger)
                    }

                    PrimaryButton("Save Schedule", icon: "checkmark") {
                        if vm.saveSchedule(appState: appState) {
                            presentationMode.wrappedValue.dismiss()
                        } else { showError = true }
                    }
                }
                .padding(20)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Add Schedule")
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
