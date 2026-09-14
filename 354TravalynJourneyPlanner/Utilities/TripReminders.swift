import Foundation
import UserNotifications

enum TripReminders {
    static func requestAccess(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }

    static func schedule(for destination: Destination) {
        cancel(for: destination.id)
        guard destination.visited == false else {
            return
        }
        schedule(destination: destination, daysBefore: 3, title: "3 days until \(destination.city)")
        schedule(destination: destination, daysBefore: 1, title: "Tomorrow: \(destination.city)")
    }

    static func cancel(for destinationId: UUID) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: identifiers(for: destinationId))
        center.removeDeliveredNotifications(withIdentifiers: identifiers(for: destinationId))
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    static func reschedule(destinations: [Destination]) {
        for destination in destinations {
            schedule(for: destination)
        }
    }

    private static func schedule(destination: Destination, daysBefore: Int, title: String) {
        guard let fireDate = fireDate(start: destination.startDate, daysBefore: daysBefore) else {
            return
        }
        if fireDate <= Date() {
            return
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "\(destination.city), \(destination.country) · \(TripFormat.dateRange(start: destination.startDate, end: destination.endDate))"
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier(for: destination.id, daysBefore: daysBefore),
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private static func fireDate(start: Date, daysBefore: Int) -> Date? {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        guard let day = calendar.date(byAdding: .day, value: -daysBefore, to: startDay) else {
            return nil
        }
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day)
    }

    private static func identifier(for destinationId: UUID, daysBefore: Int) -> String {
        "trip-\(destinationId.uuidString)-\(daysBefore)d"
    }

    private static func identifiers(for destinationId: UUID) -> [String] {
        [identifier(for: destinationId, daysBefore: 3), identifier(for: destinationId, daysBefore: 1)]
    }
}
