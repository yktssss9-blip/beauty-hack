import UserNotifications
import SwiftData

@MainActor
class NotificationManager {
    static let shared = NotificationManager()
    private let maxFreeReminders = 3

    func requestPermission() async {
        try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])
    }

    func scheduleNotifications(for record: BeautyRecord, isPro: Bool = false) {
        guard record.category?.isNotificationEnabled == true else { return }

        let ids = record.reminders.map { $0.id.uuidString }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)

        let enabledReminders = record.reminders.filter { $0.isEnabled }
        let limit = isPro ? enabledReminders.count : min(enabledReminders.count, maxFreeReminders)

        for reminder in enabledReminders.prefix(limit) {
            guard let triggerDate = notifyDate(for: record, reminder: reminder) else { continue }

            let content = UNMutableNotificationContent()
            content.title = "美容ハック"
            content.body = notificationBody(for: record, reminder: reminder)
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: triggerDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: reminder.id.uuidString,
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    private func notifyDate(for record: BeautyRecord, reminder: BeautyReminder) -> Date? {
        var baseDate: Date?
        switch reminder.type {
        case .beforeDays, .onDay:
            baseDate = record.nextDate ?? record.date
        case .aftercare:
            baseDate = record.date
        default:
            baseDate = record.nextDate
        }
        guard let base = baseDate else { return nil }
        let days = reminder.daysBefore ?? 0
        return Calendar.current.date(byAdding: .day, value: -days, to: base)
    }

    private func notificationBody(for record: BeautyRecord, reminder: BeautyReminder) -> String {
        switch reminder.type {
        case .stockAlert:
            return "「\(record.title)」の在庫が少なくなっています"
        case .progressPhoto:
            return "「\(record.title)」の経過写真を撮りましょう📸"
        case .aftercare:
            return "「\(record.title)」のアフターケアをお忘れなく🧴"
        case .nextCycleProposal:
            return "「\(record.title)」そろそろ次回の予約はどうですか？"
        default:
            let days = reminder.daysBefore ?? 0
            if days == 0 {
                return "「\(record.title)」は今日です"
            }
            return "「\(record.title)」まで\(days)日です"
        }
    }
}
