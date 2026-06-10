import SwiftUI

struct CoopsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = CoopsViewModel()

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Search bar
                    AppTextField(placeholder: "Filter coops…", text: $vm.filterText, icon: "magnifyingglass")
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    if vm.filteredCoops(appState.coops).isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "building.2")
                                .font(.system(size: 48))
                                .foregroundColor(Color.appTextInactive)
                            Text("No coops found.\nAdd your first coop to get started.")
                                .font(.system(size: 15))
                                .foregroundColor(Color.appTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 60)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(vm.filteredCoops(appState.coops)) { coop in
                                CoopCard(coop: coop)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }

                    Spacer().frame(height: 100)
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Coops")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { vm.showAddCoop = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.appPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $vm.showAddCoop) { AddCoopSheet(vm: vm) }
        .sheet(item: $vm.showDetail) { coop in CoopDetailView(coop: coop) }
    }
}

// MARK: - Coop Card
private struct CoopCard: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = CoopsViewModel()
    let coop: Coop
    @State private var showDetail = false
    @State private var showDelete = false

    private var occupancy: Double {
        coop.capacity > 0 ? Double(coop.occupied) / Double(coop.capacity) : 0
    }

    private var latestReading: ClimateReading? {
        appState.latestReadingPerCoop[coop.id]
    }

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(coop.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color.appTextPrimary)
                        Text(coop.location)
                            .font(.system(size: 13))
                            .foregroundColor(Color.appTextInactive)
                    }
                    Spacer()
                    StatusBadge(label: coop.condition.rawValue, color: coop.condition.color)
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Capacity")
                            .font(.system(size: 11)).foregroundColor(Color.appTextInactive)
                        Text("\(coop.occupied) / \(coop.capacity)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.appTextPrimary)
                    }
                    if let r = latestReading {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Temp")
                                .font(.system(size: 11)).foregroundColor(Color.appTextInactive)
                            Text(String(format: "%.1f°", r.temperature))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.appTextPrimary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Humidity")
                                .font(.system(size: 11)).foregroundColor(Color.appTextInactive)
                            Text(String(format: "%.0f%%", r.humidity))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.appTextPrimary)
                        }
                    }
                }

                // Occupancy bar
                VStack(alignment: .leading, spacing: 4) {
                    Text("Occupancy \(Int(occupancy * 100))%")
                        .font(.system(size: 11)).foregroundColor(Color.appTextInactive)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.appDivider)
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(occupancy > 0.9 ? Color.appDanger : Color.appPrimary)
                                .frame(width: geo.size.width * occupancy, height: 6)
                        }
                    }
                    .frame(height: 6)
                }

                HStack(spacing: 8) {
                    Button(action: { showDetail = true }) {
                        Text("Open")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.appPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.appPrimary.opacity(0.1))
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
        .sheet(isPresented: $showDetail) { CoopDetailView(coop: coop) }
        .alert("Delete Coop", isPresented: $showDelete) {
            Button("Delete", role: .destructive) { appState.deleteCoop(coop) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(coop.name)?")
        }
    }
}

// MARK: - Coop Detail
struct CoopDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    var coop: Coop
    @State private var editing = false
    @State private var editName: String = ""
    @State private var editCapacity: String = ""
    @State private var editOccupied: String = ""
    @State private var editCondition: Coop.CoopCondition = .good
    @State private var editLocation: String = ""
    @State private var editNotes: String = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if editing {
                        VStack(spacing: 12) {
                            AppTextField(placeholder: "Name", text: $editName, icon: "building.2")
                            AppTextField(placeholder: "Capacity", text: $editCapacity, icon: "person.3")
                            AppTextField(placeholder: "Occupied", text: $editOccupied, icon: "person.fill")
                            AppTextField(placeholder: "Location", text: $editLocation, icon: "mappin")
                            AppTextField(placeholder: "Notes", text: $editNotes, icon: "note.text")
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Condition").font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextSecondary)
                                Picker("Condition", selection: $editCondition) {
                                    ForEach(Coop.CoopCondition.allCases, id: \.self) { c in
                                        Text(c.rawValue).tag(c)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            PrimaryButton("Save Changes", icon: "checkmark") {
                                var updated = coop
                                updated.name = editName
                                updated.capacity = Int(editCapacity) ?? coop.capacity
                                updated.occupied = Int(editOccupied) ?? coop.occupied
                                updated.condition = editCondition
                                updated.location = editLocation
                                updated.notes = editNotes
                                appState.updateCoop(updated)
                                editing = false
                            }
                        }
                        .padding(20)
                    } else {
                        VStack(spacing: 16) {
                            AppCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    infoRow("Name", value: coop.name)
                                    infoRow("Capacity", value: "\(coop.capacity)")
                                    infoRow("Occupied", value: "\(coop.occupied)")
                                    infoRow("Location", value: coop.location)
                                    infoRow("Condition", value: coop.condition.rawValue)
                                    if !coop.notes.isEmpty { infoRow("Notes", value: coop.notes) }
                                }
                            }
                            .padding(.horizontal, 20)

                            // Bird groups in this coop
                            let groups = appState.birdGroups.filter { $0.coopId == coop.id }
                            if !groups.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Bird Groups")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Color.appTextPrimary)
                                        .padding(.horizontal, 20)
                                    ForEach(groups) { group in
                                        AppCard {
                                            HStack {
                                                Image(systemName: "bird.fill").foregroundColor(Color.appPrimary)
                                                Text("\(group.birdType) — \(group.count) birds, \(group.ageWeeks)w")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(Color.appTextPrimary)
                                                Spacer()
                                                StatusBadge(label: group.status.rawValue, color: group.status.color)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }
                        }
                    }
                    Spacer().frame(height: 40)
                }
                .padding(.top, 16)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(coop.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(Color.appPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editing ? "Cancel" : "Edit") {
                        if !editing {
                            editName = coop.name
                            editCapacity = "\(coop.capacity)"
                            editOccupied = "\(coop.occupied)"
                            editCondition = coop.condition
                            editLocation = coop.location
                            editNotes = coop.notes
                        }
                        editing.toggle()
                    }
                    .foregroundColor(Color.appPrimary)
                }
            }
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundColor(Color.appTextInactive)
            Spacer()
            Text(value).font(.system(size: 14, weight: .medium)).foregroundColor(Color.appTextPrimary)
        }
    }
}

// MARK: - Add Coop Sheet
private struct AddCoopSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var vm: CoopsViewModel
    @State private var showError = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    AppTextField(placeholder: "Name *", text: $vm.newName, icon: "building.2")
                    AppTextField(placeholder: "Capacity *", text: $vm.newCapacity, icon: "person.3")
                    AppTextField(placeholder: "Occupied *", text: $vm.newOccupied, icon: "person.fill")
                    AppTextField(placeholder: "Location", text: $vm.newLocation, icon: "mappin")
                    AppTextField(placeholder: "Notes", text: $vm.newNotes, icon: "note.text")
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Condition").font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextSecondary)
                        Picker("Condition", selection: $vm.newCondition) {
                            ForEach(Coop.CoopCondition.allCases, id: \.self) { c in
                                Text(c.rawValue).tag(c)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    if showError {
                        Text("Please fill required fields.").font(.system(size: 13)).foregroundColor(Color.appDanger)
                    }
                    PrimaryButton("Add Coop", icon: "plus") {
                        if vm.saveCoop(appState: appState) {
                            presentationMode.wrappedValue.dismiss()
                        } else { showError = true }
                    }
                }
                .padding(20)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Add Coop")
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
