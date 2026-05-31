import SwiftData
import Foundation

@Model
class BeautyCategory {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = ""
    var color: String = ""
    var isPreset: Bool = true
    var sortOrder: Int = 0
    var isNotificationEnabled: Bool = true
    @Relationship(deleteRule: .cascade)
    var records: [BeautyRecord] = []

    init(name: String, icon: String, color: String, isPreset: Bool, sortOrder: Int) {
        self.name = name
        self.icon = icon
        self.color = color
        self.isPreset = isPreset
        self.sortOrder = sortOrder
    }

    static func presets() -> [BeautyCategory] {
        [
            BeautyCategory(name: "カラコン",   icon: "eye.circle",              color: "#4A90D9", isPreset: true, sortOrder: 0),
            BeautyCategory(name: "整形",       icon: "face.smiling.fill",        color: "#9B72CF", isPreset: true, sortOrder: 1),
            BeautyCategory(name: "エステ",     icon: "figure.stand",             color: "#E88FA0", isPreset: true, sortOrder: 2),
            BeautyCategory(name: "マツエク",   icon: "eye.fill",                 color: "#C4956A", isPreset: true, sortOrder: 3),
            BeautyCategory(name: "ヘア",       icon: "scissors",                 color: "#F5C842", isPreset: true, sortOrder: 4),
            BeautyCategory(name: "スキンケア", icon: "sparkles",                 color: "#7BC67E", isPreset: true, sortOrder: 5),
            BeautyCategory(name: "ネイル",     icon: "paintbrush.pointed.fill",  color: "#F4A7B9", isPreset: true, sortOrder: 6),
        ]
    }
}
