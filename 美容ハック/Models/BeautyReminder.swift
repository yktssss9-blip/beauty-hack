import SwiftData
import Foundation

@Model
class BeautyReminder {
    var id: UUID = UUID()
    var type: ReminderType = ReminderType.onDay
    var daysBefore: Int?
    var notifyTime: Date = Date()
    var isEnabled: Bool = true

    init(type: ReminderType, daysBefore: Int? = nil, notifyTime: Date) {
        self.type = type
        self.daysBefore = daysBefore
        self.notifyTime = notifyTime
    }
}

enum ReminderType: String, Codable {
    case beforeDays = "N日前"
    case onDay = "当日"
    case stockAlert = "在庫アラート"
    case progressPhoto = "経過写真"
    case nextCycleProposal = "次回提案"
    case aftercare = "アフターケア"
}
