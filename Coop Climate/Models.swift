import Foundation
import SwiftUI

// MARK: - Coop
struct Coop: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var capacity: Int
    var occupied: Int
    var condition: CoopCondition
    var location: String
    var notes: String
    var createdAt: Date = Date()

    enum CoopCondition: String, Codable, CaseIterable {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"

        var color: Color {
            switch self {
            case .excellent: return Color(hex: "22C55E")
            case .good: return Color(hex: "4ADE80")
            case .fair: return Color(hex: "FACC15")
            case .poor: return Color(hex: "EF4444")
            }
        }
    }
}

// MARK: - BirdGroup
struct BirdGroup: Identifiable, Codable {
    var id: UUID = UUID()
    var birdType: String
    var count: Int
    var ageWeeks: Int
    var coopId: UUID?
    var notes: String
    var status: GroupStatus
    var createdAt: Date = Date()

    enum GroupStatus: String, Codable, CaseIterable {
        case healthy = "Healthy"
        case monitoring = "Monitoring"
        case attention = "Needs Attention"

        var color: Color {
            switch self {
            case .healthy: return Color(hex: "22C55E")
            case .monitoring: return Color(hex: "FACC15")
            case .attention: return Color(hex: "EF4444")
            }
        }
    }
}

// MARK: - ClimateReading
struct ClimateReading: Identifiable, Codable {
    var id: UUID = UUID()
    var coopId: UUID
    var temperature: Double
    var humidity: Double
    var ventilationLevel: VentilationLevel
    var date: Date = Date()
    var notes: String

    var riskLevel: RiskLevel {
        if temperature > 35 || temperature < 5 || humidity > 85 || humidity < 30 {
            return .danger
        } else if temperature > 30 || temperature < 10 || humidity > 75 || humidity < 40 {
            return .warning
        }
        return .normal
    }

    enum VentilationLevel: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case auto = "Auto"
    }

    enum RiskLevel: String, Codable {
        case normal = "Normal"
        case warning = "Warning"
        case danger = "Danger"

        var color: Color {
            switch self {
            case .normal: return Color(hex: "22C55E")
            case .warning: return Color(hex: "FACC15")
            case .danger: return Color(hex: "EF4444")
            }
        }
    }
}

// MARK: - Sensor
struct Sensor: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var type: SensorType
    var coopId: UUID?
    var isConnected: Bool
    var lastReading: Double
    var lastUpdated: Date = Date()
    var batteryLevel: Int

    enum SensorType: String, Codable, CaseIterable {
        case temperature = "Temperature"
        case humidity = "Humidity"
        case combined = "Temp + Humidity"
        case ammonia = "Ammonia"
        case co2 = "CO2"

        var icon: String {
            switch self {
            case .temperature: return "thermometer"
            case .humidity: return "humidity"
            case .combined: return "sensor.tag.radiowaves.forward"
            case .ammonia: return "aqi.medium"
            case .co2: return "wind"
            }
        }
    }
}

// MARK: - Alert
struct ClimateAlert: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var message: String
    var type: AlertType
    var coopId: UUID?
    var isResolved: Bool = false
    var isSnoozed: Bool = false
    var snoozeUntil: Date?
    var createdAt: Date = Date()

    enum AlertType: String, Codable, CaseIterable {
        case risk = "Risk"
        case missed = "Missed"
        case inspection = "Inspection"
        case temperature = "Temperature"
        case humidity = "Humidity"

        var icon: String {
            switch self {
            case .risk: return "exclamationmark.triangle.fill"
            case .missed: return "clock.badge.exclamationmark.fill"
            case .inspection: return "magnifyingglass.circle.fill"
            case .temperature: return "thermometer.sun.fill"
            case .humidity: return "humidity.fill"
            }
        }

        var color: Color {
            switch self {
            case .risk: return Color(hex: "EF4444")
            case .missed: return Color(hex: "FACC15")
            case .inspection: return Color(hex: "3B82F6")
            case .temperature: return Color(hex: "F97316")
            case .humidity: return Color(hex: "22D3EE")
            }
        }
    }
}

// MARK: - CoopTask
struct CoopTask: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var category: TaskCategory
    var coopId: UUID?
    var isDone: Bool = false
    var dueDate: Date
    var notes: String
    var createdAt: Date = Date()

    enum TaskCategory: String, Codable, CaseIterable {
        case cleaning = "Clean Coop"
        case water = "Check Water"
        case feeding = "Prepare Feed"
        case health = "Health Check"
        case ventilation = "Ventilation"
        case other = "Other"

        var icon: String {
            switch self {
            case .cleaning: return "sparkles"
            case .water: return "drop.fill"
            case .feeding: return "leaf.fill"
            case .health: return "cross.fill"
            case .ventilation: return "wind"
            case .other: return "checklist"
            }
        }
    }
}

// MARK: - Expense
struct Expense: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var amount: Double
    var category: ExpenseCategory
    var date: Date = Date()
    var notes: String
    var coopId: UUID?

    enum ExpenseCategory: String, Codable, CaseIterable {
        case feed = "Feed"
        case medicine = "Medicine"
        case transport = "Transport"
        case equipment = "Equipment"
        case other = "Other"

        var icon: String {
            switch self {
            case .feed: return "leaf.fill"
            case .medicine: return "cross.fill"
            case .transport: return "truck.box.fill"
            case .equipment: return "wrench.and.screwdriver.fill"
            case .other: return "tag.fill"
            }
        }

        var color: Color {
            switch self {
            case .feed: return Color(hex: "22C55E")
            case .medicine: return Color(hex: "EF4444")
            case .transport: return Color(hex: "F97316")
            case .equipment: return Color(hex: "3B82F6")
            case .other: return Color(hex: "6B7280")
            }
        }
    }
}

// MARK: - Note
struct CoopNote: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var coopId: UUID?
    var birdGroupId: UUID?
    var photoData: Data?
    var createdAt: Date = Date()
}

// MARK: - HistoryEntry
struct HistoryEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var action: String
    var entityType: EntityType
    var entityName: String
    var date: Date = Date()

    enum EntityType: String, Codable {
        case coop, group, reading, task, alert, expense, note, sensor
    }
}

// MARK: - VentilationSchedule
struct VentilationSchedule: Identifiable, Codable {
    var id: UUID = UUID()
    var coopId: UUID
    var startTime: Date
    var endTime: Date
    var daysOfWeek: [Int]
    var isActive: Bool = true
    var targetHumidity: Double = 60
    var targetTemperature: Double = 20
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Design tokens
extension Color {
    static let appBackground = Color(hex: "F7FDF9")
    static let appCardBackground = Color(hex: "FFFFFF")
    static let appSecondaryBackground = Color(hex: "ECFDF5")
    static let appDivider = Color(hex: "D1FAE5")
    static let appPrimary = Color(hex: "22C55E")
    static let appPrimaryActive = Color(hex: "16A34A")
    static let appPrimaryHighlight = Color(hex: "4ADE80")
    static let appBlue = Color(hex: "3B82F6")
    static let appBlueLight = Color(hex: "60A5FA")
    static let appCyan = Color(hex: "22D3EE")
    static let appOrange = Color(hex: "F97316")
    static let appOrangeLight = Color(hex: "FB923C")
    static let appWarning = Color(hex: "FACC15")
    static let appDanger = Color(hex: "EF4444")
    static let appTextPrimary = Color(hex: "064E3B")
    static let appTextSecondary = Color(hex: "065F46")
    static let appTextInactive = Color(hex: "6B7280")
}
