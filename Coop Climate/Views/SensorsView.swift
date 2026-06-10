import SwiftUI

struct SensorsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = SensorsViewModel()

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if appState.sensors.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "sensor.tag.radiowaves.forward")
                                .font(.system(size: 52))
                                .foregroundColor(Color.appTextInactive)
                            Text("No sensors added yet.\nAdd a sensor to start monitoring.")
                                .font(.system(size: 15))
                                .foregroundColor(Color.appTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 60)
                    } else {
                        ForEach(appState.sensors) { sensor in
                            SensorCard(sensor: sensor)
                                .padding(.horizontal, 16)
                        }
                    }
                    Spacer().frame(height: 100)
                }
                .padding(.top, 8)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Sensors")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { vm.showAddSensor = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.appPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $vm.showAddSensor) { AddSensorSheet(vm: vm) }
    }
}

// MARK: - Sensor Card
private struct SensorCard: View {
    @EnvironmentObject var appState: AppState
    let sensor: Sensor
    @State private var showDelete = false

    private var coopName: String {
        guard let id = sensor.coopId else { return "Unassigned" }
        return appState.coops.first(where: { $0.id == id })?.name ?? "Unknown"
    }

    private var batteryColor: Color {
        if sensor.batteryLevel > 60 { return Color.appPrimary }
        if sensor.batteryLevel > 25 { return Color.appWarning }
        return Color.appDanger
    }

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.appBlue.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: sensor.type.icon)
                            .font(.system(size: 20))
                            .foregroundColor(Color.appBlue)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sensor.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.appTextPrimary)
                        Text(sensor.type.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(Color.appTextInactive)
                    }
                    Spacer()
                    Circle()
                        .fill(sensor.isConnected ? Color.appPrimary : Color.appDanger)
                        .frame(width: 10, height: 10)
                    Text(sensor.isConnected ? "Connected" : "Offline")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(sensor.isConnected ? Color.appPrimary : Color.appDanger)
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Coop").font(.system(size: 11)).foregroundColor(Color.appTextInactive)
                        Text(coopName).font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextPrimary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last Reading").font(.system(size: 11)).foregroundColor(Color.appTextInactive)
                        Text(String(format: "%.1f", sensor.lastReading))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.appTextPrimary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Battery").font(.system(size: 11)).foregroundColor(Color.appTextInactive)
                        HStack(spacing: 4) {
                            Image(systemName: "battery.75")
                                .foregroundColor(batteryColor)
                                .font(.system(size: 14))
                            Text("\(sensor.batteryLevel)%")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(batteryColor)
                        }
                    }
                }

                HStack {
                    Button(action: {
                        var updated = sensor
                        updated.isConnected.toggle()
                        appState.updateSensor(updated)
                    }) {
                        Text(sensor.isConnected ? "Disconnect" : "Connect")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(sensor.isConnected ? Color.appTextSecondary : Color.appPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background((sensor.isConnected ? Color(hex: "E2E8F0") : Color.appPrimary.opacity(0.1)))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    Spacer()
                    Button(action: { showDelete = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(Color.appDanger)
                    }
                }
            }
        }
        .alert("Remove Sensor", isPresented: $showDelete) {
            Button("Remove", role: .destructive) { appState.deleteSensor(sensor) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Remove \(sensor.name)?")
        }
    }
}

// MARK: - Add Sensor Sheet
private struct AddSensorSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var vm: SensorsViewModel
    @State private var showError = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    AppTextField(placeholder: "Sensor Name *", text: $vm.newName, icon: "sensor.tag.radiowaves.forward")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type").font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextSecondary)
                        Picker("Type", selection: $vm.newType) {
                            ForEach(Sensor.SensorType.allCases, id: \.self) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(10)
                        .background(Color.appSecondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Assign to Coop").font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextSecondary)
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

                    AppTextField(placeholder: "Battery Level (%)", text: $vm.newBattery, icon: "battery.100")

                    if showError {
                        Text("Please enter a sensor name.").font(.system(size: 13)).foregroundColor(Color.appDanger)
                    }

                    PrimaryButton("Add Sensor", icon: "plus") {
                        if vm.saveSensor(appState: appState) {
                            presentationMode.wrappedValue.dismiss()
                        } else { showError = true }
                    }
                }
                .padding(20)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Add Sensor")
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
