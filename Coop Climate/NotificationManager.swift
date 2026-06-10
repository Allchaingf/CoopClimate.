import UserNotifications
import SwiftUI

class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func scheduleDailyCareReminder(at hour: Int = 8, minute: Int = 0) {
        let content = UNMutableNotificationContent()
        content.title = "Coop Climate"
        content.body = "Time for your daily coop check-up!"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyCare", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleHealthCheckReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Health Check"
        content.body = "Don't forget to log your coop climate readings today."
        content.sound = .default

        var components = DateComponents()
        components.hour = 18
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "healthCheck", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleLowStockReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Low Stock Alert"
        content.body = "Check feed and supply levels for your flocks."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60 * 60 * 24 * 3, repeats: true)
        let request = UNNotificationRequest(identifier: "lowStock", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func scheduleClimateAlert(title: String, body: String, coopId: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "climate_\(coopId)_\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func applySettings(dailyCare: Bool, healthCheck: Bool, lowStock: Bool) {
        cancelAllNotifications()
        if dailyCare { scheduleDailyCareReminder() }
        if healthCheck { scheduleHealthCheckReminder() }
        if lowStock { scheduleLowStockReminder() }
    }
}
