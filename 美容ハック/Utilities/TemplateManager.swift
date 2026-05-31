import Foundation

struct TemplateStep {
    let title: String
    let offsetDays: Int
    let reminderDaysBefore: Int
    let reminderType: ReminderType
}

struct BeautyTemplate {
    let name: String
    let categoryName: String
    let steps: [TemplateStep]
    let nextCycleDays: Int?
}

class TemplateManager {
    static let shared = TemplateManager()

    func applyTemplate(_ template: BeautyTemplate, startDate: Date) -> [(title: String, date: Date, reminderDaysBefore: Int)] {
        template.steps.map { step in
            let date = Calendar.current.date(
                byAdding: .day, value: step.offsetDays, to: startDate
            ) ?? startDate
            return (step.title, date, step.reminderDaysBefore)
        }
    }

    let allTemplates: [BeautyTemplate] = [
        BeautyTemplate(name: "脂肪溶解注射", categoryName: "整形・エステ", steps: [
            TemplateStep(title: "カウンセリング",    offsetDays: 0,   reminderDaysBefore: 1, reminderType: .beforeDays),
            TemplateStep(title: "施術当日",          offsetDays: 0,   reminderDaysBefore: 1, reminderType: .onDay),
            TemplateStep(title: "術後3日チェック",   offsetDays: 3,   reminderDaysBefore: 1, reminderType: .beforeDays),
            TemplateStep(title: "1週間検診",         offsetDays: 7,   reminderDaysBefore: 1, reminderType: .beforeDays),
            TemplateStep(title: "2ヶ月定期確認",     offsetDays: 60,  reminderDaysBefore: 3, reminderType: .beforeDays),
        ], nextCycleDays: nil),

        BeautyTemplate(name: "埋没法", categoryName: "整形・エステ", steps: [
            TemplateStep(title: "カウンセリング",    offsetDays: 0,   reminderDaysBefore: 1, reminderType: .beforeDays),
            TemplateStep(title: "施術当日",          offsetDays: 0,   reminderDaysBefore: 1, reminderType: .onDay),
            TemplateStep(title: "術後3日チェック",   offsetDays: 3,   reminderDaysBefore: 1, reminderType: .beforeDays),
            TemplateStep(title: "1週間検診（抜糸）", offsetDays: 7,   reminderDaysBefore: 1, reminderType: .beforeDays),
            TemplateStep(title: "3ヶ月経過確認",     offsetDays: 90,  reminderDaysBefore: 3, reminderType: .beforeDays),
            TemplateStep(title: "6ヶ月定期確認",     offsetDays: 180, reminderDaysBefore: 3, reminderType: .beforeDays),
        ], nextCycleDays: nil),

        BeautyTemplate(name: "鼻尖形成・鼻筋通し", categoryName: "整形・エステ", steps: [
            TemplateStep(title: "カウンセリング",      offsetDays: 0,  reminderDaysBefore: 1, reminderType: .beforeDays),
            TemplateStep(title: "施術当日",            offsetDays: 0,  reminderDaysBefore: 1, reminderType: .onDay),
            TemplateStep(title: "ギプス固定除去",      offsetDays: 5,  reminderDaysBefore: 1, reminderType: .beforeDays),
            TemplateStep(title: "1週間検診（抜糸）",   offsetDays: 7,  reminderDaysBefore: 1, reminderType: .beforeDays),
            TemplateStep(title: "1ヶ月検診",           offsetDays: 30, reminderDaysBefore: 3, reminderType: .beforeDays),
            TemplateStep(title: "3ヶ月定期確認",       offsetDays: 90, reminderDaysBefore: 3, reminderType: .beforeDays),
        ], nextCycleDays: nil),

        BeautyTemplate(name: "ボトックス", categoryName: "整形・エステ", steps: [
            TemplateStep(title: "カウンセリング・施術", offsetDays: 0, reminderDaysBefore: 1, reminderType: .onDay),
            TemplateStep(title: "効果確認",             offsetDays: 3, reminderDaysBefore: 0, reminderType: .aftercare),
        ], nextCycleDays: 120),

        BeautyTemplate(name: "ヒアルロン酸", categoryName: "整形・エステ", steps: [
            TemplateStep(title: "カウンセリング・施術", offsetDays: 0, reminderDaysBefore: 1, reminderType: .onDay),
            TemplateStep(title: "1週間経過確認",        offsetDays: 7, reminderDaysBefore: 1, reminderType: .beforeDays),
        ], nextCycleDays: 270),

        BeautyTemplate(name: "HIFU（ハイフ）", categoryName: "整形・エステ", steps: [
            TemplateStep(title: "カウンセリング・施術", offsetDays: 0,  reminderDaysBefore: 1, reminderType: .onDay),
            TemplateStep(title: "1ヶ月後効果確認",      offsetDays: 30, reminderDaysBefore: 3, reminderType: .beforeDays),
        ], nextCycleDays: 90),

        BeautyTemplate(name: "脱毛（クロ）", categoryName: "整形・エステ", steps: [
            TemplateStep(title: "カウンセリング",        offsetDays: 0, reminderDaysBefore: 1,  reminderType: .beforeDays),
            TemplateStep(title: "第1回施術",             offsetDays: 0, reminderDaysBefore: 1,  reminderType: .onDay),
            TemplateStep(title: "翌日・日焼け止め確認", offsetDays: 1, reminderDaysBefore: 0,  reminderType: .aftercare),
            TemplateStep(title: "1週間後・保湿ケア確認", offsetDays: 7, reminderDaysBefore: 0,  reminderType: .aftercare),
        ], nextCycleDays: 75),

        BeautyTemplate(name: "脱毛（VIO）", categoryName: "整形・エステ", steps: [
            TemplateStep(title: "カウンセリング",        offsetDays: 0, reminderDaysBefore: 1, reminderType: .beforeDays),
            TemplateStep(title: "第1回施術",             offsetDays: 0, reminderDaysBefore: 1, reminderType: .onDay),
            TemplateStep(title: "翌日・アフターケア確認", offsetDays: 1, reminderDaysBefore: 0, reminderType: .aftercare),
        ], nextCycleDays: 60),

        BeautyTemplate(name: "脱毛（顔）", categoryName: "整形・エステ", steps: [
            TemplateStep(title: "カウンセリング",        offsetDays: 0, reminderDaysBefore: 1, reminderType: .beforeDays),
            TemplateStep(title: "第1回施術",             offsetDays: 0, reminderDaysBefore: 1, reminderType: .onDay),
            TemplateStep(title: "翌日・日焼け止め注意", offsetDays: 1, reminderDaysBefore: 0, reminderType: .aftercare),
            TemplateStep(title: "1週間後・保湿確認",    offsetDays: 7, reminderDaysBefore: 0, reminderType: .aftercare),
        ], nextCycleDays: 45),

        BeautyTemplate(name: "全体カラー", categoryName: "パーマ・カラー", steps: [
            TemplateStep(title: "施術当日", offsetDays: 0, reminderDaysBefore: 1, reminderType: .onDay),
        ], nextCycleDays: 50),

        BeautyTemplate(name: "パーマ", categoryName: "パーマ・カラー", steps: [
            TemplateStep(title: "施術当日", offsetDays: 0, reminderDaysBefore: 1, reminderType: .onDay),
        ], nextCycleDays: 75),

        BeautyTemplate(name: "縮毛矯正", categoryName: "パーマ・カラー", steps: [
            TemplateStep(title: "施術当日", offsetDays: 0, reminderDaysBefore: 1, reminderType: .onDay),
        ], nextCycleDays: 90),

        BeautyTemplate(name: "カット", categoryName: "パーマ・カラー", steps: [
            TemplateStep(title: "施術当日", offsetDays: 0, reminderDaysBefore: 1, reminderType: .onDay),
        ], nextCycleDays: 45),

        BeautyTemplate(name: "ヘッドスパ", categoryName: "パーマ・カラー", steps: [
            TemplateStep(title: "施術当日", offsetDays: 0, reminderDaysBefore: 1, reminderType: .onDay),
        ], nextCycleDays: 14),

        BeautyTemplate(name: "まつ毛エクステ", categoryName: "整形・エステ", steps: [
            TemplateStep(title: "施術当日", offsetDays: 0, reminderDaysBefore: 1, reminderType: .onDay),
        ], nextCycleDays: 21),

        BeautyTemplate(name: "まつ毛パーマ", categoryName: "整形・エステ", steps: [
            TemplateStep(title: "施術当日", offsetDays: 0, reminderDaysBefore: 1, reminderType: .onDay),
        ], nextCycleDays: 42),

        BeautyTemplate(name: "眉毛サロン", categoryName: "整形・エステ", steps: [
            TemplateStep(title: "施術当日", offsetDays: 0, reminderDaysBefore: 1, reminderType: .onDay),
        ], nextCycleDays: 28),

        BeautyTemplate(name: "フェイシャルエステ", categoryName: "整形・エステ", steps: [
            TemplateStep(title: "施術当日", offsetDays: 0, reminderDaysBefore: 1, reminderType: .onDay),
        ], nextCycleDays: 14),

        BeautyTemplate(name: "痩身エステ", categoryName: "整形・エステ", steps: [
            TemplateStep(title: "施術当日", offsetDays: 0, reminderDaysBefore: 1, reminderType: .onDay),
        ], nextCycleDays: 7),

        BeautyTemplate(name: "ホワイトニング", categoryName: "整形・エステ", steps: [
            TemplateStep(title: "施術当日",     offsetDays: 0, reminderDaysBefore: 1, reminderType: .onDay),
            TemplateStep(title: "1週間後確認", offsetDays: 7, reminderDaysBefore: 1, reminderType: .onDay),
        ], nextCycleDays: 180),

        BeautyTemplate(name: "ジェルネイル", categoryName: "ネイル", steps: [
            TemplateStep(title: "施術当日", offsetDays: 0, reminderDaysBefore: 1, reminderType: .onDay),
        ], nextCycleDays: 21),

        BeautyTemplate(name: "スカルプ", categoryName: "ネイル", steps: [
            TemplateStep(title: "施術当日", offsetDays: 0, reminderDaysBefore: 1, reminderType: .onDay),
        ], nextCycleDays: 28),

        BeautyTemplate(name: "ネイルオフ", categoryName: "ネイル", steps: [
            TemplateStep(title: "施術当日", offsetDays: 0, reminderDaysBefore: 1, reminderType: .onDay),
        ], nextCycleDays: nil),
    ]

    func templates(for categoryName: String) -> [BeautyTemplate] {
        allTemplates.filter { $0.categoryName == categoryName }
    }
}
