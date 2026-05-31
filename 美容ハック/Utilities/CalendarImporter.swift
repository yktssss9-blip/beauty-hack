import Foundation
import EventKit

class CalendarImporter {
    static let shared = CalendarImporter()
    private let store = EKEventStore()

    let keywords: [String: String] = [
        "カラコン": "カラコン", "コンタクト": "カラコン",
        "クリニック": "整形・エステ", "整形": "整形・エステ",
        "豊胸": "整形・エステ", "エステ": "整形・エステ",
        "ボトックス": "整形・エステ",
        "パーマ": "パーマ・カラー", "カラー": "パーマ・カラー",
        "サロン": "パーマ・カラー", "美容院": "パーマ・カラー",
    ]

    func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            return (try? await store.requestFullAccessToEvents()) ?? false
        }
        return false
    }

    func requestPermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return (try? await store.requestWriteOnlyAccessToEvents()) ?? false
        } else {
            return await withCheckedContinuation { continuation in
                store.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func addEvent(title: String, date: Date, notes: String? = nil) {
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = date
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: date)
        event.notes = notes
        event.calendar = store.defaultCalendarForNewEvents
        try? store.save(event, span: .thisEvent)
    }

    func fetchBeautyEvents() -> [EKEvent] {
        let start = Date()
        let end = Calendar.current.date(byAdding: .month, value: 3, to: start)!
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate).filter { event in
            keywords.keys.contains { event.title?.contains($0) == true }
        }
    }

    func autoDetectCategory(from title: String) -> String? {
        for (keyword, category) in keywords {
            if title.contains(keyword) { return category }
        }
        return nil
    }
}
