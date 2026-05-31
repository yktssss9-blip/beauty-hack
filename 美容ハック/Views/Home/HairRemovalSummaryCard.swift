import SwiftUI

struct HairRemovalSummaryCard: View {
    let records: [BeautyRecord]

    private struct AreaProgress: Identifiable {
        let id = UUID()
        let area: String
        let current: Int
        let total: Int
        let totalCost: Double
    }

    private var areaProgressList: [AreaProgress] {
        let grouped = Dictionary(grouping: records) { $0.hairRemovalArea ?? "不明" }
        return grouped.map { area, recs in
            let current = recs.compactMap { $0.sessionNumber }.max() ?? recs.count
            let total = recs.compactMap { $0.totalSessionsGoal }.first ?? 0
            let cost = recs.compactMap { $0.amount }.reduce(0, +)
            return AreaProgress(area: area, current: current, total: total, totalCost: cost)
        }.sorted { $0.area < $1.area }
    }

    private var totalCost: Double {
        records.compactMap { $0.amount }.reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("脱毛の進捗")
                    .font(.subheadline.bold())
                    .foregroundColor(.beautyText)
                Spacer()
                Text("合計 ¥\(Int(totalCost).formatted())")
                    .font(.caption)
                    .foregroundColor(.beautySubText)
            }

            ForEach(areaProgressList) { progress in
                VStack(spacing: 6) {
                    HStack {
                        Text(progress.area)
                            .font(.subheadline)
                            .foregroundColor(.beautyText)
                        Spacer()
                        Text(progress.total > 0
                             ? "第\(progress.current)回 / 全\(progress.total)回予定"
                             : "第\(progress.current)回")
                            .font(.caption)
                            .foregroundColor(.beautySubText)
                    }
                    if progress.total > 0 {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.beautyRose.opacity(0.2))
                                    .frame(height: 6)
                                Capsule()
                                    .fill(Color.beautyRose)
                                    .frame(
                                        width: geo.size.width * min(Double(progress.current) / Double(progress.total), 1.0),
                                        height: 6
                                    )
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}
