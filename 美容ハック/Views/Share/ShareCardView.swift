import SwiftUI
import SwiftData

// MARK: - Types

enum ShareCardType: CaseIterable, Identifiable {
    case monthly, contactStreak, annual

    var id: Self { self }

    var label: String {
        switch self {
        case .monthly: return "今月の美容費用"
        case .contactStreak: return "カラコン連続日数"
        case .annual: return "年間美容費用レポート"
        }
    }

    var icon: String {
        switch self {
        case .monthly: return "yensign.circle.fill"
        case .contactStreak: return "eye.circle.fill"
        case .annual: return "chart.bar.fill"
        }
    }
}

fileprivate struct CategoryAmount: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let amount: Double
    let icon: String
}

private func formatAmount(_ amount: Double, masked: Bool) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "JPY"
    formatter.currencySymbol = "¥"
    let formatted = formatter.string(from: NSNumber(value: amount)) ?? "¥0"
    guard masked else { return formatted }
    return formatted.map { $0.isNumber ? "*" : $0 }.map(String.init).joined()
}

// MARK: - Share Sheet (entry point)

struct ShareSheetView: View {
    @Query private var records: [BeautyRecord]
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: ShareCardType = .monthly
    @State private var isStories = false
    @State private var maskAmount = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                cardPreview
                    .padding()

                Divider()

                controlsPanel
                    .padding()

                Spacer()

                shareButton
                    .padding(.horizontal)
                    .padding(.bottom, 32)
            }
            .navigationTitle("シェアカードを作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    // MARK: - Preview

    private var cardPreview: some View {
        GeometryReader { geo in
            let width = geo.size.width - 32
            let height = isStories ? width * (693.0 / 390.0) : width
            ShareCardContent(
                type: selectedType,
                monthlyData: computedMonthlyData,
                contactStreak: computedContactStreak,
                annualData: computedAnnualData,
                annualTotal: computedAnnualTotal,
                currentYear: currentYear,
                maskAmount: maskAmount
            )
            .frame(width: width, height: min(height, isStories ? 420 : 260))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
            .frame(width: geo.size.width)
        }
        .frame(height: isStories ? 440 : 280)
    }

    // MARK: - Controls

    private var controlsPanel: some View {
        VStack(spacing: 16) {
            Picker("カード種類", selection: $selectedType) {
                ForEach(ShareCardType.allCases) { type in
                    Label(type.label, systemImage: type.icon).tag(type)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            Picker("フォーマット", selection: $isStories) {
                Text("正方形 1:1").tag(false)
                Text("縦長 9:16").tag(true)
            }
            .pickerStyle(.segmented)

            if selectedType != .contactStreak {
                Toggle("金額をマスキング（¥**,***）", isOn: $maskAmount)
            }
        }
    }

    // MARK: - Share Button

    private var shareButton: some View {
        Button {
            renderAndShare()
        } label: {
            Label("シェアする", systemImage: "square.and.arrow.up")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.beautyRose)
                .foregroundStyle(.white)
                .font(.headline)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Render & Share

    @MainActor
    private func renderAndShare() {
        let cardWidth: CGFloat = 390
        let cardHeight: CGFloat = isStories ? 693 : 390

        let view = ShareCardContent(
            type: selectedType,
            monthlyData: computedMonthlyData,
            contactStreak: computedContactStreak,
            annualData: computedAnnualData,
            annualTotal: computedAnnualTotal,
            currentYear: currentYear,
            maskAmount: maskAmount
        )
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        renderer.proposedSize = ProposedViewSize(width: cardWidth, height: cardHeight)

        guard let image = renderer.uiImage else { return }

        let items: [Any] = [image, "#美容費用公開 #美容ハック"]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        var presenter = root
        while let presented = presenter.presentedViewController { presenter = presented }
        presenter.present(activityVC, animated: true)
    }

    // MARK: - Computed Data

    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }

    private var computedMonthlyData: [CategoryAmount] {
        let now = Date()
        let cal = Calendar.current
        let month = records.filter {
            cal.isDate($0.date, equalTo: now, toGranularity: .month) && $0.amount != nil
        }
        var totals: [String: (Double, Color, String)] = [:]
        for r in month {
            let name = r.category?.name ?? "その他"
            let color = Color(hex: r.category?.color ?? "#888888")
            let icon = r.category?.icon ?? "tag"
            totals[name, default: (0, color, icon)].0 += r.amount ?? 0
        }
        return totals.map { CategoryAmount(name: $0.key, color: $0.value.1, amount: $0.value.0, icon: $0.value.2) }
            .sorted { $0.amount > $1.amount }
    }

    private var computedContactStreak: Int {
        let contactRecords = records.filter {
            $0.category?.name.contains("カラコン") == true && $0.contactStartDate != nil
        }
        guard let latest = contactRecords.sorted(by: { $0.date > $1.date }).first,
              let start = latest.contactStartDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
    }

    private var computedAnnualData: [CategoryAmount] {
        let year = currentYear
        let cal = Calendar.current
        let yearRecords = records.filter {
            cal.component(.year, from: $0.date) == year && $0.amount != nil
        }
        var totals: [String: (Double, Color, String)] = [:]
        for r in yearRecords {
            let name = r.category?.name ?? "その他"
            let color = Color(hex: r.category?.color ?? "#888888")
            let icon = r.category?.icon ?? "tag"
            totals[name, default: (0, color, icon)].0 += r.amount ?? 0
        }
        return totals.map { CategoryAmount(name: $0.key, color: $0.value.1, amount: $0.value.0, icon: $0.value.2) }
            .sorted { $0.amount > $1.amount }
    }

    private var computedAnnualTotal: Double { computedAnnualData.reduce(0) { $0 + $1.amount } }
}

// MARK: - Card Content (renderable, data-in-params for ImageRenderer)

fileprivate struct ShareCardContent: View {
    let type: ShareCardType
    let monthlyData: [CategoryAmount]
    let contactStreak: Int
    let annualData: [CategoryAmount]
    let annualTotal: Double
    let currentYear: Int
    let maskAmount: Bool

    private var monthlyTotal: Double { monthlyData.reduce(0) { $0 + $1.amount } }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#1A1A2E"), Color(hex: "#16213E"), Color(hex: "#0F3460")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                cardHeader
                Spacer()
                switch type {
                case .monthly: monthlyContent
                case .contactStreak: streakContent
                case .annual: annualContent
                }
                Spacer()
                cardFooter
            }
            .padding(24)
        }
    }

    // MARK: - Header / Footer

    private var cardHeader: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(Color.beautyRose)
                Text("美容ハック")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            Spacer()
            Text(periodLabel)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var periodLabel: String {
        let now = Date()
        let cal = Calendar.current
        let month = cal.component(.month, from: now)
        let year = cal.component(.year, from: now)
        switch type {
        case .monthly: return "\(year)年\(month)月"
        case .contactStreak, .annual: return "\(currentYear)年"
        }
    }

    private var cardFooter: some View {
        Text("#美容費用公開 #美容ハック")
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.4))
            .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Monthly

    private var monthlyContent: some View {
        VStack(spacing: 16) {
            Text("今月の美容費用")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))

            Text(formatAmount(monthlyTotal, masked: maskAmount))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            if !monthlyData.isEmpty {
                VStack(spacing: 6) {
                    ForEach(monthlyData.prefix(4)) { item in
                        HStack {
                            Image(systemName: item.icon)
                                .font(.caption2)
                                .foregroundStyle(item.color)
                                .frame(width: 16)
                            Text(item.name)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                            Spacer()
                            Text(formatAmount(item.amount, masked: maskAmount))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Contact Streak

    private var streakContent: some View {
        VStack(spacing: 12) {
            Text("カラコン")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))

            Image(systemName: "eye.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "#4A90D9"))

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(contactStreak)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("日連続")
                    .font(.title3.bold())
                    .foregroundStyle(.white.opacity(0.8))
            }

            Text("使用中")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Annual

    private var annualContent: some View {
        VStack(spacing: 14) {
            Text("\(currentYear)年 美容費用レポート")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))

            Text(formatAmount(annualTotal, masked: maskAmount))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            if annualTotal > 0 {
                VStack(spacing: 8) {
                    ForEach(annualData.prefix(4)) { item in
                        let ratio = item.amount / annualTotal
                        VStack(spacing: 3) {
                            HStack {
                                Text(item.name)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.8))
                                Spacer()
                                Text("\(Int(ratio * 100))%")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(.white.opacity(0.1)).frame(height: 6)
                                    Capsule().fill(item.color)
                                        .frame(width: geo.size.width * ratio, height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}
