import SwiftUI
import Combine

class AppState: ObservableObject {
    // MARK: - Appearance
    @AppStorage("colorScheme") var colorSchemeRaw: String = "system" {
        didSet { objectWillChange.send() }
    }

    var preferredColorScheme: ColorScheme? {
        switch colorSchemeRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    // MARK: - Settings
    @AppStorage("temperatureUnit") var temperatureUnit: String = "Celsius"
    @AppStorage("language") var language: String = "English"
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    @AppStorage("dailyCareReminder") var dailyCareReminder: Bool = true
    @AppStorage("healthCheckReminder") var healthCheckReminder: Bool = true
    @AppStorage("lowStockReminder") var lowStockReminder: Bool = false
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    // MARK: - Data stores (JSON persistence)
    @Published var coops: [Coop] = []
    @Published var birdGroups: [BirdGroup] = []
    @Published var climateReadings: [ClimateReading] = []
    @Published var sensors: [Sensor] = []
    @Published var alerts: [ClimateAlert] = []
    @Published var tasks: [CoopTask] = []
    @Published var expenses: [Expense] = []
    @Published var notes: [CoopNote] = []
    @Published var historyEntries: [HistoryEntry] = []
    @Published var ventilationSchedules: [VentilationSchedule] = []

    init() {
        loadAllData()
        if coops.isEmpty { seedSampleData() }
    }

    // MARK: - Persistence helpers
    private func url(for key: String) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("\(key).json")
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            try? data.write(to: url(for: key))
        }
    }

    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = try? Data(contentsOf: url(for: key)) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func loadAllData() {
        coops = load([Coop].self, key: "coops") ?? []
        birdGroups = load([BirdGroup].self, key: "birdGroups") ?? []
        climateReadings = load([ClimateReading].self, key: "climateReadings") ?? []
        sensors = load([Sensor].self, key: "sensors") ?? []
        alerts = load([ClimateAlert].self, key: "alerts") ?? []
        tasks = load([CoopTask].self, key: "tasks") ?? []
        expenses = load([Expense].self, key: "expenses") ?? []
        notes = load([CoopNote].self, key: "notes") ?? []
        historyEntries = load([HistoryEntry].self, key: "history") ?? []
        ventilationSchedules = load([VentilationSchedule].self, key: "ventilationSchedules") ?? []
    }

    func saveAllData() {
        save(coops, key: "coops")
        save(birdGroups, key: "birdGroups")
        save(climateReadings, key: "climateReadings")
        save(sensors, key: "sensors")
        save(alerts, key: "alerts")
        save(tasks, key: "tasks")
        save(expenses, key: "expenses")
        save(notes, key: "notes")
        save(historyEntries, key: "history")
        save(ventilationSchedules, key: "ventilationSchedules")
    }

    // MARK: - CRUD
    func addCoop(_ coop: Coop) {
        coops.append(coop)
        save(coops, key: "coops")
        logHistory("Added coop", type: .coop, name: coop.name)
    }

    func updateCoop(_ coop: Coop) {
        if let idx = coops.firstIndex(where: { $0.id == coop.id }) {
            coops[idx] = coop
            save(coops, key: "coops")
            logHistory("Updated coop", type: .coop, name: coop.name)
        }
    }

    func deleteCoop(_ coop: Coop) {
        coops.removeAll { $0.id == coop.id }
        save(coops, key: "coops")
        logHistory("Deleted coop", type: .coop, name: coop.name)
    }

    func addBirdGroup(_ group: BirdGroup) {
        birdGroups.append(group)
        save(birdGroups, key: "birdGroups")
        logHistory("Added group", type: .group, name: group.birdType)
    }

    func updateBirdGroup(_ group: BirdGroup) {
        if let idx = birdGroups.firstIndex(where: { $0.id == group.id }) {
            birdGroups[idx] = group
            save(birdGroups, key: "birdGroups")
            logHistory("Updated group", type: .group, name: group.birdType)
        }
    }

    func deleteBirdGroup(_ group: BirdGroup) {
        birdGroups.removeAll { $0.id == group.id }
        save(birdGroups, key: "birdGroups")
        logHistory("Deleted group", type: .group, name: group.birdType)
    }

    func addClimateReading(_ reading: ClimateReading) {
        climateReadings.append(reading)
        save(climateReadings, key: "climateReadings")
        checkAndGenerateAlerts(for: reading)
        logHistory("Added climate reading", type: .reading, name: "T:\(reading.temperature)° H:\(reading.humidity)%")
    }

    func addTask(_ task: CoopTask) {
        tasks.append(task)
        save(tasks, key: "tasks")
        logHistory("Added task", type: .task, name: task.title)
    }

    func updateTask(_ task: CoopTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task
            save(tasks, key: "tasks")
        }
    }

    func toggleTask(_ task: CoopTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].isDone.toggle()
            save(tasks, key: "tasks")
            if tasks[idx].isDone {
                logHistory("Completed task", type: .task, name: task.title)
            }
        }
    }

    func deleteTask(_ task: CoopTask) {
        tasks.removeAll { $0.id == task.id }
        save(tasks, key: "tasks")
    }

    func addSensor(_ sensor: Sensor) {
        sensors.append(sensor)
        save(sensors, key: "sensors")
        logHistory("Added sensor", type: .sensor, name: sensor.name)
    }

    func updateSensor(_ sensor: Sensor) {
        if let idx = sensors.firstIndex(where: { $0.id == sensor.id }) {
            sensors[idx] = sensor
            save(sensors, key: "sensors")
        }
    }

    func deleteSensor(_ sensor: Sensor) {
        sensors.removeAll { $0.id == sensor.id }
        save(sensors, key: "sensors")
    }

    func resolveAlert(_ alert: ClimateAlert) {
        if let idx = alerts.firstIndex(where: { $0.id == alert.id }) {
            alerts[idx].isResolved = true
            save(alerts, key: "alerts")
            logHistory("Resolved alert", type: .alert, name: alert.title)
        }
    }

    func snoozeAlert(_ alert: ClimateAlert, until: Date) {
        if let idx = alerts.firstIndex(where: { $0.id == alert.id }) {
            alerts[idx].isSnoozed = true
            alerts[idx].snoozeUntil = until
            save(alerts, key: "alerts")
        }
    }

    func addExpense(_ expense: Expense) {
        expenses.append(expense)
        save(expenses, key: "expenses")
        logHistory("Added expense", type: .expense, name: expense.title)
    }

    func deleteExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
        save(expenses, key: "expenses")
    }

    func addNote(_ note: CoopNote) {
        notes.append(note)
        save(notes, key: "notes")
        logHistory("Added note", type: .note, name: note.title)
    }

    func deleteNote(_ note: CoopNote) {
        notes.removeAll { $0.id == note.id }
        save(notes, key: "notes")
    }

    func addVentilationSchedule(_ schedule: VentilationSchedule) {
        ventilationSchedules.append(schedule)
        save(ventilationSchedules, key: "ventilationSchedules")
    }

    func updateVentilationSchedule(_ schedule: VentilationSchedule) {
        if let idx = ventilationSchedules.firstIndex(where: { $0.id == schedule.id }) {
            ventilationSchedules[idx] = schedule
            save(ventilationSchedules, key: "ventilationSchedules")
        }
    }

    func deleteVentilationSchedule(_ schedule: VentilationSchedule) {
        ventilationSchedules.removeAll { $0.id == schedule.id }
        save(ventilationSchedules, key: "ventilationSchedules")
    }

    // MARK: - Alerts generation
    private func checkAndGenerateAlerts(for reading: ClimateReading) {
        let coopName = coops.first(where: { $0.id == reading.coopId })?.name ?? "Coop"
        switch reading.riskLevel {
        case .danger:
            let alert = ClimateAlert(
                title: "Danger: \(coopName)",
                message: "Temperature \(String(format: "%.1f", reading.temperature))°, Humidity \(String(format: "%.0f", reading.humidity))% — immediate action required.",
                type: reading.temperature > 35 ? .temperature : .humidity,
                coopId: reading.coopId
            )
            alerts.append(alert)
            save(alerts, key: "alerts")
        case .warning:
            let alert = ClimateAlert(
                title: "Warning: \(coopName)",
                message: "Climate conditions are outside optimal range.",
                type: reading.temperature > 30 ? .temperature : .humidity,
                coopId: reading.coopId
            )
            alerts.append(alert)
            save(alerts, key: "alerts")
        case .normal:
            break
        }
    }

    // MARK: - History
    private func logHistory(_ action: String, type: HistoryEntry.EntityType, name: String) {
        let entry = HistoryEntry(action: action, entityType: type, entityName: name)
        historyEntries.insert(entry, at: 0)
        if historyEntries.count > 200 { historyEntries = Array(historyEntries.prefix(200)) }
        save(historyEntries, key: "history")
    }

    // MARK: - Computed properties
    var activeAlerts: [ClimateAlert] {
        alerts.filter { !$0.isResolved && !$0.isSnoozed }
    }

    var todayTasks: [CoopTask] {
        let cal = Calendar.current
        return tasks.filter { cal.isDateInToday($0.dueDate) }
    }

    var latestReadingPerCoop: [UUID: ClimateReading] {
        var result: [UUID: ClimateReading] = [:]
        for reading in climateReadings.sorted(by: { $0.date > $1.date }) {
            if result[reading.coopId] == nil {
                result[reading.coopId] = reading
            }
        }
        return result
    }

    // MARK: - Seed data
    private func seedSampleData() {
        let coop1 = Coop(name: "Coop A", capacity: 50, occupied: 42, condition: .good, location: "North Field", notes: "Main flock")
        let coop2 = Coop(name: "Coop B", capacity: 30, occupied: 28, condition: .excellent, location: "East Side", notes: "Layers")
        coops = [coop1, coop2]

        let group1 = BirdGroup(birdType: "Chickens", count: 42, ageWeeks: 24, coopId: coop1.id, notes: "Broiler batch", status: .healthy)
        let group2 = BirdGroup(birdType: "Ducks", count: 28, ageWeeks: 18, coopId: coop2.id, notes: "Layer flock", status: .monitoring)
        birdGroups = [group1, group2]

        let now = Date()
        var readings: [ClimateReading] = []
        for i in 0..<14 {
            let date = Calendar.current.date(byAdding: .hour, value: -i * 6, to: now)!
            readings.append(ClimateReading(coopId: coop1.id, temperature: Double.random(in: 18...28), humidity: Double.random(in: 50...75), ventilationLevel: .medium, date: date, notes: ""))
            readings.append(ClimateReading(coopId: coop2.id, temperature: Double.random(in: 17...26), humidity: Double.random(in: 55...70), ventilationLevel: .high, date: date, notes: ""))
        }
        climateReadings = readings

        let sensor1 = Sensor(name: "Sensor Alpha", type: .combined, coopId: coop1.id, isConnected: true, lastReading: 22.4, batteryLevel: 87)
        let sensor2 = Sensor(name: "Sensor Beta", type: .temperature, coopId: coop2.id, isConnected: true, lastReading: 21.1, batteryLevel: 63)
        sensors = [sensor1, sensor2]

        tasks = [
            CoopTask(title: "Clean Coop A", category: .cleaning, coopId: coop1.id, isDone: false, dueDate: now, notes: "Weekly deep clean"),
            CoopTask(title: "Check Water", category: .water, coopId: coop1.id, isDone: true, dueDate: now, notes: ""),
            CoopTask(title: "Prepare Feed", category: .feeding, coopId: nil, isDone: false, dueDate: Calendar.current.date(byAdding: .day, value: 1, to: now)!, notes: "Organic mix")
        ]

        expenses = [
            Expense(title: "Monthly Feed", amount: 120.0, category: .feed, notes: ""),
            Expense(title: "Vitamins", amount: 35.0, category: .medicine, notes: ""),
            Expense(title: "New feeder", amount: 55.0, category: .equipment, notes: "")
        ]

        alerts = [
            ClimateAlert(title: "Risk: Coop A", message: "Humidity rising above 75% — consider increasing ventilation.", type: .humidity, coopId: coop1.id)
        ]

        saveAllData()
    }

    // MARK: - Export
    func exportJSON() -> String {
        let data: [String: Any] = [
            "coops": (try? JSONEncoder().encode(coops)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]",
            "readings": (try? JSONEncoder().encode(climateReadings)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]",
            "expenses": (try? JSONEncoder().encode(expenses)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        ]
        return data.map { "\($0.key): \($0.value)" }.joined(separator: "\n\n")
    }
}
