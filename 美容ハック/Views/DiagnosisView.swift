import SwiftUI
import SwiftData

private enum DiagnosisSubStep {
    case engagement, usageFrequency
}

struct DiagnosisView: View {
    @Query private var allRecords: [BeautyRecord]
    @Environment(\.modelContext) private var modelContext

    @State private var queue: [BeautyRecord] = []
    @State private var currentIndex = 0
    @State private var showResult = false
    @State private var currentSubStep: DiagnosisSubStep = .engagement

    var pendingRecords: [BeautyRecord] {
        allRecords.filter { record in
            guard !record.isAftercare else { return false }
            guard let lastDiagnosed = record.lastDiagnosedAt else { return true }
            return Calendar.current.dateComponents([.day], from: lastDiagnosed, to: Date()).day ?? 0 >= 30
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if showResult {
                    resultView
                } else if queue.isEmpty {
                    if pendingRecords.isEmpty {
                        allDoneView
                    } else {
                        Color.clear
                    }
                } else {
                    cardView
                }
            }
        }
        .onAppear {
            if queue.isEmpty && !showResult {
                queue = pendingRecords
            }
        }
    }

    // MARK: - Card View

    var cardView: some View {
        VStack(spacing: 0) {
            progressHeader

            Spacer()

            if currentIndex < queue.count {
                diagnosisCard(record: queue[currentIndex])
            }

            Spacer()

            if currentSubStep == .engagement {
                ratingSection
            } else {
                frequencySection
            }
        }
        .background(Color.beautyBG.ignoresSafeArea())
        .navigationTitle("美容診断")
        .navigationBarTitleDisplayMode(.inline)
    }

    var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    if currentSubStep == .usageFrequency {
                        withAnimation { currentSubStep = .engagement }
                    } else if currentIndex > 0 {
                        currentIndex -= 1
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.caption.weight(.semibold))
                        Text("戻る")
                            .font(.subheadline)
                    }
                    .foregroundColor(.beautySubText)
                }
                .opacity(currentIndex > 0 || currentSubStep == .usageFrequency ? 1 : 0)
                .disabled(currentIndex == 0 && currentSubStep == .engagement)

                Spacer()

                Text("\(currentIndex + 1) / \(queue.count)")
                    .font(.subheadline)
                    .foregroundColor(.beautySubText)
            }
            .padding(.horizontal)

            ProgressView(value: Double(currentIndex + 1), total: Double(queue.count))
                .tint(.beautyRose)
                .padding(.horizontal)
        }
        .padding(.top)
    }

    func diagnosisCard(record: BeautyRecord) -> some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.beautyRose.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: record.category?.icon ?? "sparkles")
                    .font(.system(size: 30))
                    .foregroundColor(.beautyRose)
            }

            Text(record.title)
                .font(.title2.weight(.bold))
                .foregroundColor(.beautyText)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text(record.date.formatted(.dateTime.year().month().day()))
                }
                .font(.caption)
                .foregroundColor(.beautySubText)

                if let cat = record.category {
                    HStack(spacing: 6) {
                        Image(systemName: cat.icon)
                        Text(cat.name)
                    }
                    .font(.caption)
                    .foregroundColor(.beautySubText)
                }

                if let amount = record.amount {
                    Text("¥\(Int(amount).formatted())")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color.beautyRose.opacity(0.85))
                        .clipShape(Capsule())
                }

                if let memo = record.memo, !memo.isEmpty {
                    Text(memo)
                        .font(.caption)
                        .foregroundColor(.beautySubText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }

            Text(currentSubStep == .engagement
                ? "満足度を評価してください"
                : "どのくらいの頻度で使いましたか？")
                .font(.subheadline)
                .foregroundColor(.beautySubText)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(Color.beautyCard)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        .padding(.horizontal, 24)
    }

    var ratingSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        guard currentIndex < queue.count else { return }
                        submitRating(stars: star, for: queue[currentIndex])
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color(hex: "#FFD700"))
                            Text("\(star)")
                                .font(.caption2)
                                .foregroundColor(.beautySubText)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                advanceToNext()
            } label: {
                Text("スキップ")
                    .font(.subheadline)
                    .foregroundColor(.beautySubText)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 24)
                    .background(Color.beautySubText.opacity(0.08))
                    .clipShape(Capsule())
            }
        }
        .padding(.bottom, 40)
    }

    var frequencySection: some View {
        VStack(spacing: 12) {
            VStack(spacing: 10) {
                ForEach([
                    (label: "よく使う",         emoji: "👍", freq: UsageFrequency.often,     color: Color(hex: "#7BC67E")),
                    (label: "たまに使う",        emoji: "🤔", freq: UsageFrequency.sometimes, color: Color(hex: "#FFB347")),
                    (label: "ほぼ使っていない",  emoji: "👎", freq: UsageFrequency.rarely,    color: Color(hex: "#FF6B6B")),
                ], id: \.label) { item in
                    Button {
                        guard currentIndex < queue.count else { return }
                        submitFrequency(item.freq, for: queue[currentIndex])
                    } label: {
                        HStack {
                            Text(item.emoji).font(.title3)
                            Text(item.label)
                                .font(.subheadline.bold())
                                .foregroundColor(item.color)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(item.color.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            Button {
                guard currentIndex < queue.count else { return }
                submitFrequency(nil, for: queue[currentIndex])
            } label: {
                Text("スキップ")
                    .font(.subheadline)
                    .foregroundColor(.beautySubText)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 24)
                    .background(Color.beautySubText.opacity(0.08))
                    .clipShape(Capsule())
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: - Result View

    var resultView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text("✨")
                        .font(.system(size: 56))
                    Text("診断完了！")
                        .font(.title.weight(.bold))
                        .foregroundColor(.beautyText)
                    Text("お疲れさまでした")
                        .font(.subheadline)
                        .foregroundColor(.beautySubText)
                }
                .padding(.top, 20)

                let unusedItems  = queue.filter { $0.diagnosisResult == .unused }
                let maybeItems   = queue.filter { $0.diagnosisResult == .maybe  }
                let skippedItems = queue.filter { $0.diagnosisResult == nil && $0.lastDiagnosedAt == nil }
                let savingsTotal = unusedItems.compactMap { $0.amount }.reduce(0, +)

                if savingsTotal > 0 {
                    VStack(spacing: 8) {
                        Text("削減できる費用")
                            .font(.subheadline)
                            .foregroundColor(.beautySubText)
                        Text("¥\(Int(savingsTotal).formatted())")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.beautyRose)
                        Text("年間 ¥\(Int(savingsTotal * 12).formatted()) の節約に")
                            .font(.caption)
                            .foregroundColor(.beautySubText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color.beautyRose.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                if !unusedItems.isEmpty {
                    resultListSection(
                        title: "見直しを検討してみて",
                        icon: "xmark.circle.fill",
                        color: Color(hex: "#FF6B6B"),
                        items: unusedItems
                    )
                }

                if !maybeItems.isEmpty {
                    resultListSection(
                        title: "様子を見てみて",
                        icon: "questionmark.circle.fill",
                        color: Color(hex: "#FFB347"),
                        items: maybeItems
                    )
                }

                if unusedItems.isEmpty && maybeItems.isEmpty && skippedItems.count < queue.count {
                    VStack(spacing: 8) {
                        Text("👏")
                            .font(.system(size: 40))
                        Text("すべてのアイテムを上手に使えています！")
                            .font(.subheadline)
                            .foregroundColor(.beautySubText)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }

                Button {
                    withAnimation {
                        showResult = false
                        currentIndex = 0
                    }
                } label: {
                    Text("もう一度診断する")
                        .font(.subheadline)
                        .foregroundColor(.beautySubText)
                        .padding(.vertical, 12)
                }
                .padding(.bottom, 20)
            }
            .padding()
        }
        .background(Color.beautyBG.ignoresSafeArea())
        .navigationTitle("診断結果")
        .navigationBarTitleDisplayMode(.inline)
    }

    func resultListSection(title: String, icon: String, color: Color, items: [BeautyRecord]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(color)
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.title)
                            .font(.subheadline)
                            .foregroundColor(.beautyText)
                            .lineLimit(1)
                        Spacer()
                        if let amount = item.amount {
                            Text("¥\(Int(amount).formatted())")
                                .font(.caption)
                                .foregroundColor(.beautySubText)
                        }
                    }
                    HStack(spacing: 8) {
                        Text(item.date.formatted(.dateTime.year().month().day()))
                            .font(.caption2)
                            .foregroundColor(.beautySubText)
                        if let cat = item.category {
                            Text(cat.name)
                                .font(.caption2)
                                .foregroundColor(.beautySubText)
                        }
                    }
                }
                .padding(12)
                .background(color.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(Color.beautyCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - All Done View

    var allDoneView: some View {
        VStack(spacing: 16) {
            Text("✅")
                .font(.system(size: 60))
            Text("すべて診断済みです")
                .font(.title2.weight(.bold))
                .foregroundColor(.beautyText)
            Text("30日後に再診断できます")
                .font(.subheadline)
                .foregroundColor(.beautySubText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.beautyBG.ignoresSafeArea())
        .navigationTitle("診断")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Actions

    func submitRating(stars: Int, for record: BeautyRecord) {
        switch stars {
        case 1, 2: record.engagementLevel = .dissatisfied
        case 3:    record.engagementLevel = .neutral
        default:   record.engagementLevel = .satisfied
        }

        if record.category?.name == "スキンケア" {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentSubStep = .usageFrequency
            }
        } else {
            record.diagnosisResult = record.engagementLevel == .dissatisfied ? .unused
                                   : record.engagementLevel == .neutral      ? .maybe : .active
            record.lastDiagnosedAt = Date()
            advanceToNext()
        }
    }

    func submitFrequency(_ frequency: UsageFrequency?, for record: BeautyRecord) {
        record.usageFrequency = frequency
        switch frequency {
        case .rarely:         record.diagnosisResult = .unused
        case .sometimes:      record.diagnosisResult = .maybe
        case .often, nil:     record.diagnosisResult = .active
        }
        record.lastDiagnosedAt = Date()
        withAnimation { currentSubStep = .engagement }
        advanceToNext()
    }

    func advanceToNext() {
        withAnimation(.easeInOut(duration: 0.25)) {
            if currentIndex + 1 < queue.count {
                currentIndex += 1
            } else {
                showResult = true
            }
        }
    }
}
