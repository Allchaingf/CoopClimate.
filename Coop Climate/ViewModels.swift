import SwiftUI
import Combine

// MARK: - ClimateViewModel
class ClimateViewModel: ObservableObject {
    @Published var selectedCoopId: UUID?
    @Published var showAddReading = false
    @Published var newTemperature: String = ""
    @Published var newHumidity: String = ""
    @Published var newVentilation: ClimateReading.VentilationLevel = .medium
    @Published var newNotes: String = ""
    @Published var toast: String? = nil

    func readings(for coopId: UUID, from appState: AppState) -> [ClimateReading] {
        appState.climateReadings
            .filter { $0.coopId == coopId }
            .sorted { $0.date > $1.date }
    }

    func temperatureValues(for coopId: UUID, from appState: AppState) -> [Double] {
        Array(readings(for: coopId, from: appState).prefix(14).reversed().map { $0.temperature })
    }

    func humidityValues(for coopId: UUID, from appState: AppState) -> [Double] {
        Array(readings(for: coopId, from: appState).prefix(14).reversed().map { $0.humidity })
    }

    func saveReading(appState: AppState) -> Bool {
        guard let coopId = selectedCoopId,
              let temp = Double(newTemperature),
              let hum = Double(newHumidity) else { return false }
        let reading = ClimateReading(
            coopId: coopId,
            temperature: temp,
            humidity: hum,
            ventilationLevel: newVentilation,
            notes: newNotes
        )
        appState.addClimateReading(reading)
        newTemperature = ""
        newHumidity = ""
        newNotes = ""
        toast = "Reading saved"
        return true
    }
}

// MARK: - CoopsViewModel
class CoopsViewModel: ObservableObject {
    @Published var showAddCoop = false
    @Published var showDetail: Coop? = nil
    @Published var filterText: String = ""

    @Published var newName = ""
    @Published var newCapacity = ""
    @Published var newOccupied = ""
    @Published var newCondition: Coop.CoopCondition = .good
    @Published var newLocation = ""
    @Published var newNotes = ""

    func filteredCoops(_ coops: [Coop]) -> [Coop] {
        guard !filterText.isEmpty else { return coops }
        return coops.filter { $0.name.localizedCaseInsensitiveContains(filterText) || $0.location.localizedCaseInsensitiveContains(filterText) }
    }

    func saveCoop(appState: AppState) -> Bool {
        guard !newName.isEmpty, let cap = Int(newCapacity), let occ = Int(newOccupied) else { return false }
        let coop = Coop(name: newName, capacity: cap, occupied: occ, condition: newCondition, location: newLocation, notes: newNotes)
        appState.addCoop(coop)
        resetForm()
        return true
    }

    func resetForm() {
        newName = ""; newCapacity = ""; newOccupied = ""; newCondition = .good; newLocation = ""; newNotes = ""
    }
}

// MARK: - BirdGroupsViewModel
class BirdGroupsViewModel: ObservableObject {
    @Published var showAddGroup = false
    @Published var filterText = ""

    @Published var newBirdType = ""
    @Published var newCount = ""
    @Published var newAge = ""
    @Published var newCoopId: UUID? = nil
    @Published var newNotes = ""
    @Published var newStatus: BirdGroup.GroupStatus = .healthy

    func filteredGroups(_ groups: [BirdGroup]) -> [BirdGroup] {
        guard !filterText.isEmpty else { return groups }
        return groups.filter { $0.birdType.localizedCaseInsensitiveContains(filterText) }
    }

    func saveGroup(appState: AppState) -> Bool {
        guard !newBirdType.isEmpty, let count = Int(newCount), let age = Int(newAge) else { return false }
        let group = BirdGroup(birdType: newBirdType, count: count, ageWeeks: age, coopId: newCoopId, notes: newNotes, status: newStatus)
        appState.addBirdGroup(group)
        resetForm()
        return true
    }

    func resetForm() {
        newBirdType = ""; newCount = ""; newAge = ""; newCoopId = nil; newNotes = ""
    }
}

// MARK: - TasksViewModel
class TasksViewModel: ObservableObject {
    @Published var showAddTask = false
    @Published var filter: TaskFilter = .all

    @Published var newTitle = ""
    @Published var newCategory: CoopTask.TaskCategory = .cleaning
    @Published var newCoopId: UUID? = nil
    @Published var newDueDate = Date()
    @Published var newNotes = ""

    enum TaskFilter: String, CaseIterable {
        case all = "All", today = "Today", pending = "Pending", done = "Done"
    }

    func filteredTasks(_ tasks: [CoopTask]) -> [CoopTask] {
        switch filter {
        case .all: return tasks
        case .today:
            return tasks.filter { Calendar.current.isDateInToday($0.dueDate) }
        case .pending:
            return tasks.filter { !$0.isDone }
        case .done:
            return tasks.filter { $0.isDone }
        }
    }

    func saveTask(appState: AppState) -> Bool {
        guard !newTitle.isEmpty else { return false }
        let task = CoopTask(title: newTitle, category: newCategory, coopId: newCoopId, isDone: false, dueDate: newDueDate, notes: newNotes)
        appState.addTask(task)
        resetForm()
        return true
    }

    func resetForm() {
        newTitle = ""; newCategory = .cleaning; newCoopId = nil; newDueDate = Date(); newNotes = ""
    }
}

// MARK: - AlertsViewModel
class AlertsViewModel: ObservableObject {
    @Published var filter: AlertFilter = .active

    enum AlertFilter: String, CaseIterable {
        case active = "Active", resolved = "Resolved", all = "All"
    }

    func filteredAlerts(_ alerts: [ClimateAlert]) -> [ClimateAlert] {
        switch filter {
        case .active: return alerts.filter { !$0.isResolved && !$0.isSnoozed }
        case .resolved: return alerts.filter { $0.isResolved }
        case .all: return alerts
        }
    }
}

// MARK: - ExpensesViewModel
class ExpensesViewModel: ObservableObject {
    @Published var showAddExpense = false
    @Published var filterCategory: Expense.ExpenseCategory? = nil

    @Published var newTitle = ""
    @Published var newAmount = ""
    @Published var newCategory: Expense.ExpenseCategory = .feed
    @Published var newDate = Date()
    @Published var newNotes = ""
    @Published var newCoopId: UUID? = nil

    func filteredExpenses(_ expenses: [Expense]) -> [Expense] {
        guard let cat = filterCategory else { return expenses }
        return expenses.filter { $0.category == cat }
    }

    func totalAmount(_ expenses: [Expense]) -> Double {
        filteredExpenses(expenses).reduce(0) { $0 + $1.amount }
    }

    func saveExpense(appState: AppState) -> Bool {
        guard !newTitle.isEmpty, let amount = Double(newAmount) else { return false }
        let expense = Expense(title: newTitle, amount: amount, category: newCategory, date: newDate, notes: newNotes, coopId: newCoopId)
        appState.addExpense(expense)
        resetForm()
        return true
    }

    func resetForm() {
        newTitle = ""; newAmount = ""; newCategory = .feed; newDate = Date(); newNotes = ""
    }
}

// MARK: - SensorsViewModel
class SensorsViewModel: ObservableObject {
    @Published var showAddSensor = false

    @Published var newName = ""
    @Published var newType: Sensor.SensorType = .combined
    @Published var newCoopId: UUID? = nil
    @Published var newBattery = "100"

    func saveSensor(appState: AppState) -> Bool {
        guard !newName.isEmpty else { return false }
        let sensor = Sensor(name: newName, type: newType, coopId: newCoopId, isConnected: true, lastReading: 0, batteryLevel: Int(newBattery) ?? 100)
        appState.addSensor(sensor)
        resetForm()
        return true
    }

    func resetForm() {
        newName = ""; newType = .combined; newCoopId = nil; newBattery = "100"
    }
}

// MARK: - NotesViewModel
class NotesViewModel: ObservableObject {
    @Published var showAddNote = false

    @Published var newTitle = ""
    @Published var newBody = ""
    @Published var newCoopId: UUID? = nil
    @Published var newGroupId: UUID? = nil

    func saveNote(appState: AppState) -> Bool {
        guard !newTitle.isEmpty else { return false }
        let note = CoopNote(title: newTitle, body: newBody, coopId: newCoopId, birdGroupId: newGroupId)
        appState.addNote(note)
        resetForm()
        return true
    }

    func resetForm() {
        newTitle = ""; newBody = ""; newCoopId = nil; newGroupId = nil
    }
}

// MARK: - ReportsViewModel
class ReportsViewModel: ObservableObject {
    @Published var selectedRange: DateRange = .week

    enum DateRange: String, CaseIterable {
        case week = "7 Days", month = "30 Days", all = "All Time"
    }

    func filteredReadings(_ readings: [ClimateReading]) -> [ClimateReading] {
        let cutoff: Date?
        switch selectedRange {
        case .week: cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        case .month: cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())
        case .all: cutoff = nil
        }
        guard let cut = cutoff else { return readings }
        return readings.filter { $0.date >= cut }
    }

    func avgTemperature(_ readings: [ClimateReading]) -> Double {
        let r = filteredReadings(readings)
        guard !r.isEmpty else { return 0 }
        return r.map(\.temperature).reduce(0, +) / Double(r.count)
    }

    func avgHumidity(_ readings: [ClimateReading]) -> Double {
        let r = filteredReadings(readings)
        guard !r.isEmpty else { return 0 }
        return r.map(\.humidity).reduce(0, +) / Double(r.count)
    }

    func riskCount(_ readings: [ClimateReading]) -> Int {
        filteredReadings(readings).filter { $0.riskLevel != .normal }.count
    }
}

// MARK: - VentilationViewModel
class VentilationViewModel: ObservableObject {
    @Published var showAddSchedule = false
    @Published var selectedCoopId: UUID? = nil

    @Published var newStartTime = Date()
    @Published var newEndTime = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
    @Published var newDays: Set<Int> = [2, 4, 6]
    @Published var newTargetHumidity: Double = 60
    @Published var newTargetTemperature: Double = 20

    func filteredSchedules(_ schedules: [VentilationSchedule]) -> [VentilationSchedule] {
        guard let id = selectedCoopId else { return schedules }
        return schedules.filter { $0.coopId == id }
    }

    func saveSchedule(appState: AppState) -> Bool {
        guard let coopId = selectedCoopId else { return false }
        let schedule = VentilationSchedule(
            coopId: coopId,
            startTime: newStartTime,
            endTime: newEndTime,
            daysOfWeek: Array(newDays),
            targetHumidity: newTargetHumidity,
            targetTemperature: newTargetTemperature
        )
        appState.addVentilationSchedule(schedule)
        return true
    }
}

// MARK: - HistoryViewModel
class HistoryViewModel: ObservableObject {
    @Published var filterType: HistoryEntry.EntityType? = nil
    @Published var searchText = ""

    func filteredEntries(_ entries: [HistoryEntry]) -> [HistoryEntry] {
        var result = entries
        if let t = filterType { result = result.filter { $0.entityType == t } }
        if !searchText.isEmpty {
            result = result.filter {
                $0.action.localizedCaseInsensitiveContains(searchText) ||
                $0.entityName.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }
}
