import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleStressAlert(stressLevel: StressLevel, hrv: Double) {
        guard stressLevel == .high || stressLevel == .overload else { return }
        let content = UNMutableNotificationContent()
        content.title = "Stress Alert"
        content.body  = "Your HRV is \(Int(hrv))ms – \(stressLevel.rawValue) stress. \(stressLevel.description)"
        content.sound = .default
        content.categoryIdentifier = "STRESS_ALERT"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "stress-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleHydrationReminder(atHour hour: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Stay Hydrated"
        content.body  = "Remember to drink water! Staying hydrated reduces stress."
        content.sound = .default

        var comps = DateComponents()
        comps.hour   = hour
        comps.minute = 0
        let trigger  = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request  = UNNotificationRequest(
            identifier: "hydration-\(hour)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}
