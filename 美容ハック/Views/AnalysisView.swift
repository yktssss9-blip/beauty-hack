import SwiftUI
import SwiftData
import Charts

struct MonthEntry: Identifiable {
    let id = UUID()
    let month: String
    let total: Double
}

struct CategoryEntry: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let colorHex: String
    let total: Double
}

struct EngagementEntry: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let colorHex: String
    let averageScore: Double
    let count: Int
}

struct AnalysisView: View {
    @Query private var records: [BeautyRecord]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    totalsSection
                    topCostSection
                    monthlyChartSection
                    categoryChartSection
                    if !reviewItems.isEmpty {
                        reviewSuggestionSection
                    }
                    if !engagementData.isEmpty {
                        engagementSection
                    }
                }
                .padding()
            }
            .navigationTitle("分析")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("今月") { }
                        Button("3ヶ月") { }
                        Button("今年") { }
                        Button("全期間") { }
                    } label: {
                        HStack(spacing: 4) {
                            Text("今月")
                                .font(.subheadline)
                            Image(systemName: "chevron.down")
                                .font(.caption2.weight(.semibold))
                        }
                        .foregroundColor(.beautyText)
                    }
                }
            }
            .background(Color.beautyBG)
        }
    }

    // MARK: - Computed Properties

    var thisMonthTotal: Double {
        let calendar = Calendar.current
        let now = Date()
        return records
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .compactMap { $0.amount }
            .reduce(0, +)
    }

    var topCostRecords: [BeautyRecord] {
        records
            .filter { $0.amount != nil }
            .sorted { ($0.amount ?? 0) > ($1.amount ?? 0) }
            .prefix(3)
            .map { $0 }
    }

    var monthlyData: [MonthEntry] {
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "M月"
        return (0..<6).reversed().compactMap { offset -> MonthEntry? in
            guard let targetDate = calendar.date(byAdding: .month, value: -offset, to: now),
                  let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: targetDate)),
                  let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)
            else { return nil }
            let total = records
                .filter { $0.date >= startOfMonth && $0.date < nextMonth }
                .compactMap { $0.amount }
                .reduce(0, +)
            return MonthEntry(month: formatter.string(from: targetDate), total: total)
        }
    }

    var categoryData: [CategoryEntry] {
        let grouped = Dictionary(grouping: records.filter { $0.amount != nil }) { $0.category?.id }
        return grouped.compactMap { (_, recs) -> CategoryEntry? in
            let total = recs.compactMap { $0.amount }.reduce(0, +)
            guard total > 0 else { return nil }
            let cat = recs.first?.category
            return CategoryEntry(
                name: cat?.name ?? "その他",
                icon: cat?.icon ?? "tag",
                colorHex: cat?.color ?? "#888888",
                total: total
            )
        }
        .sorted { $0.total > $1.total }
    }

    var annualTotal: Double {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        return records
            .filter { calendar.component(.year, from: $0.date) == year }
            .compactMap { $0.amount }
            .reduce(0, +)
    }

    var allTimeTotal: Double {
        records.compactMap { $0.amount }.reduce(0, +)
    }

    var reviewItems: [BeautyRecord] {
        records.filter { $0.diagnosisResult == .unused }
    }

    var engagementData: [EngagementEntry] {
        let withEngagement = records.filter { $0.engagementLevel != nil }
        let grouped = Dictionary(grouping: withEngagement) { $0.category?.id }
        return grouped.compactMap { (_, recs) -> EngagementEntry? in
            let scores = recs.compactMap { $0.engagementLevel?.rawValue }
            guard !scores.isEmpty else { return nil }
            let avg = Double(scores.reduce(0, +)) / Double(scores.count)
            let cat = recs.first?.category
            return EngagementEntry(
                name: cat?.name ?? "その他",
                icon: cat?.icon ?? "tag",
                colorHex: cat?.color ?? "#888888",
                averageScore: avg,
                count: scores.count
            )
        }
        .sorted { $0.averageScore > $1.averageScore }
    }

    // MARK: - Sections

    var totalsSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("今月の美容費合計")
                    .font(.subheadline)
                    .foregroundColor(.beautySubText)
                Text("¥\(Int(thisMonthTotal).formatted())")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.beautyText)
            }

            Divider()

            HStack {
                VStack(spacing: 4) {
                    Text("今年合計")
                        .font(.caption)
                        .foregroundColor(.beautySubText)
                    Text("¥\(Int(annualTotal).formatted())")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.beautyText)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 36)

                VStack(spacing: 4) {
                    Text("累計")
                        .font(.caption)
                        .foregroundColor(.beautySubText)
                    Text("¥\(Int(allTimeTotal).formatted())")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.beautyText)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.beautyCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    var topCostSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("コストが高いTop3")
                .font(.headline)
                .foregroundColor(.beautyText)
            if topCostRecords.isEmpty {
                emptyLabel
            } else {
                ForEach(Array(topCostRecords.enumerated()), id: \.offset) { index, record in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(index == 0 ? Color.beautyRose : Color.beautySubText.opacity(0.4))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.beautyText)
                                .lineLimit(1)
                            if let cat = record.category {
                                Text(cat.name)
                                    .font(.caption)
                                    .foregroundColor(.beautySubText)
                            }
                        }
                        Spacer()
                        Text("¥\(Int(record.amount ?? 0).formatted())")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(index == 0 ? .beautyRose : .beautyText)
                    }
                    .padding(12)
                    .background(Color.beautyBG)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(Color.beautyCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    var monthlyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("支出の推移")
                .font(.headline)
                .foregroundColor(.beautyText)
            Chart(monthlyData) { entry in
                LineMark(
                    x: .value("月", entry.month),
                    y: .value("金額", entry.total)
                )
                .foregroundStyle(Color.beautyRose)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("月", entry.month),
                    y: .value("金額", entry.total)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.beautyRose.opacity(0.25), Color.beautyRose.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("月", entry.month),
                    y: .value("金額", entry.total)
                )
                .foregroundStyle(Color.beautyRose)
                .symbolSize(entry.total > 0 ? 36 : 0)
            }
            .frame(height: 160)
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(v == 0 ? "¥0" : "¥\(Int(v / 1000))k")
                                .font(.caption2)
                                .foregroundColor(.beautySubText)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.beautyCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    var categoryChartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("カテゴリ別の内訳")
                .font(.headline)
                .foregroundColor(.beautyText)
            if categoryData.isEmpty {
                emptyLabel
            } else {
                let maxTotal = categoryData.map { $0.total }.max() ?? 1
                ForEach(categoryData) { entry in
                    VStack(spacing: 6) {
                        HStack {
                            Label(entry.name, systemImage: entry.icon)
                                .font(.subheadline)
                                .foregroundColor(.beautyText)
                            Spacer()
                            Text("¥\(Int(entry.total).formatted())")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.beautyText)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.beautySubText.opacity(0.12))
                                    .frame(height: 8)
                                Capsule()
                                    .fill(Color(hex: entry.colorHex))
                                    .frame(width: geo.size.width * (entry.total / maxTotal), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.beautyCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    var reviewSuggestionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("見直しの提案", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundColor(.beautyText)
            Text("診断で「使ってない」と回答したアイテムです")
                .font(.caption)
                .foregroundColor(.beautySubText)
            ForEach(reviewItems) { record in
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.beautyRose)
                    Text(record.title)
                        .font(.subheadline)
                        .foregroundColor(.beautyText)
                        .lineLimit(1)
                    Spacer()
                    if let amount = record.amount {
                        Text("¥\(Int(amount).formatted())")
                            .font(.subheadline)
                            .foregroundColor(.beautySubText)
                    }
                }
                .padding(12)
                .background(Color.beautyRose.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            let total = reviewItems.compactMap { $0.amount }.reduce(0, +)
            if total > 0 {
                Divider()
                HStack {
                    Text("削減できる可能性のある費用")
                        .font(.subheadline)
                        .foregroundColor(.beautySubText)
                    Spacer()
                    Text("¥\(Int(total).formatted())")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.beautyRose)
                }
            }
        }
        .padding(16)
        .background(Color.beautyCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    var engagementSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("カテゴリ別 満足度", systemImage: "star.fill")
                .font(.headline)
                .foregroundColor(.beautyText)
            ForEach(engagementData) { entry in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: entry.colorHex).opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: entry.icon)
                            .font(.caption)
                            .foregroundColor(Color(hex: entry.colorHex))
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.name)
                            .font(.subheadline)
                            .foregroundColor(.beautyText)
                        Text("\(entry.count)件の回答")
                            .font(.caption2)
                            .foregroundColor(.beautySubText)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        starView(score: entry.averageScore)
                        Text(String(format: "%.1f / 3.0", entry.averageScore))
                            .font(.caption2)
                            .foregroundColor(.beautySubText)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.beautyCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    func starView(score: Double) -> some View {
        let filled = Int(round(score))
        return HStack(spacing: 2) {
            ForEach(1...3, id: \.self) { i in
                Image(systemName: i <= filled ? "star.fill" : "star")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(i <= filled ? starColor(for: score) : Color.beautySubText.opacity(0.25))
            }
        }
    }

    func starColor(for score: Double) -> Color {
        if score >= 2.5 { return Color(hex: "#7BC67E") }
        if score >= 1.5 { return Color(hex: "#FFB347") }
        return Color(hex: "#FF6B6B")
    }

    var emptyLabel: some View {
        Text("データがありません")
            .font(.subheadline)
            .foregroundColor(.beautySubText)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
    }
}
