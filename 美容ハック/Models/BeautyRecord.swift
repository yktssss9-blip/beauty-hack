import SwiftData
import Foundation

@Model
class BeautyRecord {
    var id: UUID = UUID()
    var title: String = ""
    var date: Date = Date()
    var amount: Double?
    var memo: String?
    var url: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var cycleDays: Int?
    var nextDate: Date?

    var templateName: String?
    var stepIndex: Int?
    var totalSteps: Int?
    var parentRecordId: UUID?

    var contactCycleDays: Int?
    var contactStartDate: Date?
    var contactIsApproximate: Bool = false
    var purchaseCount: Int?
    var remainingCount: Int?

    var clinicName: String?
    var staffName: String?
    var aftercareDays: Int?
    var isAftercare: Bool = false

    var salonName: String?
    var recommendedCycleWeeks: Int?

    var openedDate: Date?
    var expiryDays: Int?
    var stockLevel: StockLevel?

    var hairRemovalArea: String?
    var sessionNumber: Int?
    var totalSessionsGoal: Int?

    var isCompleted: Bool = false

    var diagnosisResult: DiagnosisResult?
    var engagementLevel: EngagementLevel?
    var usageFrequency: UsageFrequency?
    var lastDiagnosedAt: Date?

    var category: BeautyCategory?
    @Relationship(deleteRule: .cascade)
    var photos: [BeautyPhoto] = []
    @Relationship(deleteRule: .cascade)
    var reminders: [BeautyReminder] = []

    init(
        title: String = "",
        date: Date = Date(),
        amount: Double? = nil,
        memo: String? = nil,
        url: String? = nil,
        category: BeautyCategory? = nil
    ) {
        self.title = title
        self.date = date
        self.amount = amount
        self.memo = memo
        self.url = url
        self.category = category
    }

    var daysUntilNext: Int? {
        guard let nextDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day
    }

    var alertColor: AlertLevel {
        guard let days = daysUntilNext else { return .none }
        if days <= 0 { return .expired }
        if days <= 3 { return .red }
        if days <= 7 { return .orange }
        return .none
    }
}

enum StockLevel: String, Codable {
    case full, medium, low, empty
}

enum DiagnosisResult: String, Codable {
    case unused, maybe, active
}

enum AlertLevel {
    case none, orange, red, expired
}

enum EngagementLevel: Int, Codable {
    case dissatisfied = 1  // 不満
    case neutral = 2       // まあまあ
    case satisfied = 3     // 大満足
}

enum UsageFrequency: String, Codable {
    case rarely    = "ほぼ使っていない"
    case sometimes = "たまに使う"
    case often     = "よく使う"
}
