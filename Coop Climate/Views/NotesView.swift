import SwiftUI

struct NotesView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = NotesViewModel()

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if appState.notes.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "note.text")
                                .font(.system(size: 52))
                                .foregroundColor(Color.appTextInactive)
                            Text("No notes yet.\nAdd observations, photos, and reminders.")
                                .font(.system(size: 15))
                                .foregroundColor(Color.appTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 60)
                    } else {
                        ForEach(appState.notes.sorted { $0.createdAt > $1.createdAt }) { note in
                            NoteCard(note: note)
                                .padding(.horizontal, 16)
                        }
                    }
                    Spacer().frame(height: 100)
                }
                .padding(.top, 8)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { vm.showAddNote = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.appPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $vm.showAddNote) { AddNoteSheet(vm: vm) }
    }
}

// MARK: - Note Card
private struct NoteCard: View {
    @EnvironmentObject var appState: AppState
    let note: CoopNote
    @State private var showDelete = false

    private var coopName: String {
        guard let id = note.coopId else { return "" }
        return appState.coops.first(where: { $0.id == id })?.name ?? ""
    }

    private var groupName: String {
        guard let id = note.birdGroupId else { return "" }
        return appState.birdGroups.first(where: { $0.id == id })?.birdType ?? ""
    }

    private static let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short; return f
    }()

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(note.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.appTextPrimary)
                    Spacer()
                    Button(action: { showDelete = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(Color.appDanger)
                    }
                }

                if !note.body.isEmpty {
                    Text(note.body)
                        .font(.system(size: 14))
                        .foregroundColor(Color.appTextSecondary)
                        .lineLimit(3)
                }

                HStack(spacing: 12) {
                    if !coopName.isEmpty {
                        Label(coopName, systemImage: "building.2.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.appPrimary)
                    }
                    if !groupName.isEmpty {
                        Label(groupName, systemImage: "bird.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.appBlue)
                    }
                    Spacer()
                    Text(Self.fmt.string(from: note.createdAt))
                        .font(.system(size: 11))
                        .foregroundColor(Color.appTextInactive)
                }
            }
        }
        .alert("Delete Note", isPresented: $showDelete) {
            Button("Delete", role: .destructive) { appState.deleteNote(note) }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Add Note Sheet
private struct AddNoteSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var vm: NotesViewModel
    @State private var showError = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    AppTextField(placeholder: "Title *", text: $vm.newTitle, icon: "note.text")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note").font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextSecondary)
                        TextEditor(text: $vm.newBody)
                            .font(.system(size: 15))
                            .foregroundColor(Color.appTextPrimary)
                            .frame(minHeight: 120)
                            .padding(10)
                            .background(Color.appSecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appDivider, lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Attach to Coop").font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextSecondary)
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
                        Text("Attach to Bird Group").font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextSecondary)
                        Picker("Group", selection: $vm.newGroupId) {
                            Text("None").tag(UUID?.none)
                            ForEach(appState.birdGroups) { group in
                                Text(group.birdType).tag(Optional(group.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(10)
                        .background(Color.appSecondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    if showError {
                        Text("Please enter a title.").font(.system(size: 13)).foregroundColor(Color.appDanger)
                    }

                    PrimaryButton("Save Note", icon: "checkmark") {
                        if vm.saveNote(appState: appState) {
                            presentationMode.wrappedValue.dismiss()
                        } else { showError = true }
                    }
                }
                .padding(20)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Add Note")
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
