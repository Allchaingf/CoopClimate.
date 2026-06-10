import SwiftUI

struct TasksView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = TasksViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Filter", selection: $vm.filter) {
                    ForEach(TasksViewModel.TaskFilter.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .padding(16)

                let filtered = vm.filteredTasks(appState.tasks)

                if filtered.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checklist")
                            .font(.system(size: 52))
                            .foregroundColor(Color.appTextInactive)
                        Text("No tasks found.")
                            .font(.system(size: 15))
                            .foregroundColor(Color.appTextSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(filtered) { task in
                                TaskRow(task: task)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.bottom, 100)
                    }
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { vm.showAddTask = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.appPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $vm.showAddTask) { AddTaskSheet().environmentObject(appState) }
    }
}

// MARK: - Task Row
private struct TaskRow: View {
    @EnvironmentObject var appState: AppState
    let task: CoopTask
    @State private var showDelete = false

    var body: some View {
        AppCard {
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                        appState.toggleTask(task)
                    }
                }) {
                    ZStack {
                        Circle()
                            .stroke(task.isDone ? Color.appPrimary : Color.appDivider, lineWidth: 2)
                            .frame(width: 26, height: 26)
                        if task.isDone {
                            Circle()
                                .fill(Color.appPrimary)
                                .frame(width: 16, height: 16)
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appBlue.opacity(0.1))
                        .frame(width: 34, height: 34)
                    Image(systemName: task.category.icon)
                        .font(.system(size: 16))
                        .foregroundColor(Color.appBlue)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(task.isDone ? Color.appTextInactive : Color.appTextPrimary)
                        .strikethrough(task.isDone, color: Color.appTextInactive)
                    HStack(spacing: 8) {
                        Text(task.category.rawValue)
                            .font(.system(size: 11))
                            .foregroundColor(Color.appTextInactive)
                        Text("·")
                            .foregroundColor(Color.appTextInactive)
                        Text(dueDateLabel(task.dueDate))
                            .font(.system(size: 11))
                            .foregroundColor(isOverdue(task) ? Color.appDanger : Color.appTextInactive)
                    }
                }

                Spacer()

                Button(action: { showDelete = true }) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 16))
                        .foregroundColor(Color.appTextInactive)
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { appState.deleteTask(task) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Task", isPresented: $showDelete) {
            Button("Delete", role: .destructive) { appState.deleteTask(task) }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func dueDateLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInTomorrow(date) { return "Tomorrow" }
        let f = DateFormatter(); f.dateStyle = .short
        return f.string(from: date)
    }

    private func isOverdue(_ task: CoopTask) -> Bool {
        !task.isDone && task.dueDate < Calendar.current.startOfDay(for: Date())
    }
}

// MARK: - Add Task Sheet
struct AddTaskSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var vm = TasksViewModel()
    @State private var showError = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    AppTextField(placeholder: "Task Title *", text: $vm.newTitle, icon: "checklist")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category").font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextSecondary)
                        Picker("Category", selection: $vm.newCategory) {
                            ForEach(CoopTask.TaskCategory.allCases, id: \.self) { c in
                                Label(c.rawValue, systemImage: c.icon).tag(c)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(10)
                        .background(Color.appSecondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Due Date").font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextSecondary)
                        DatePicker("", selection: $vm.newDueDate, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .padding(10)
                            .background(Color.appSecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Coop").font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextSecondary)
                        Picker("Coop", selection: $vm.newCoopId) {
                            Text("Any Coop").tag(UUID?.none)
                            ForEach(appState.coops) { coop in
                                Text(coop.name).tag(Optional(coop.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(10)
                        .background(Color.appSecondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    AppTextField(placeholder: "Notes", text: $vm.newNotes, icon: "note.text")

                    if showError {
                        Text("Please enter a task title.").font(.system(size: 13)).foregroundColor(Color.appDanger)
                    }

                    PrimaryButton("Add Task", icon: "checkmark") {
                        if vm.saveTask(appState: appState) {
                            presentationMode.wrappedValue.dismiss()
                        } else { showError = true }
                    }
                }
                .padding(20)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Add Task")
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
