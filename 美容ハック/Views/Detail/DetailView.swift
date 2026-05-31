import SwiftUI
import SwiftData

struct DetailView: View {
    let record: BeautyRecord
    @Binding var toastMessage: String?

    @Environment(\.modelContext) private var context

    @State private var showEditSheet = false
    @State private var showStepList = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                categorySection

                if let memo = record.memo, !memo.isEmpty {
                    infoSection(title: "メモ") {
                        Text(memo)
                            .font(.body)
                            .foregroundColor(.beautyText)
                    }
                }

                if let urlString = record.url, !urlString.isEmpty {
                    urlSection(urlString)
                }

                if !record.photos.isEmpty {
                    photoSection
                }
            }
            .padding()
            .padding(.bottom, 40)
        }
        .background(Color.beautyBG)
        .navigationTitle(record.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("編集") { showEditSheet = true }
                    .foregroundStyle(Color.beautyRose)
            }
        }
        .sheet(isPresented: $showEditSheet) {
            RecordEditView(record: record)
        }
        .sheet(isPresented: $showStepList) {
            StepListView(record: record)
        }
    }

    // MARK: - Category Sections

    @ViewBuilder
    private var categorySection: some View {
        switch record.category?.name {
        case "カラコン":
            kalaconSection
        case "整形・エステ":
            surgerySection
        case "脱毛":
            hairRemovalSection
        default:
            generalSection
        }
    }

    private var kalaconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            infoSection(title: "カラコン情報") {
                VStack(spacing: 0) {
                    if let startDate = record.contactStartDate {
                        labeledRow("交換日", value: shortDate(startDate))
                        Divider()
                    }
                    if let remaining = record.remainingCount {
                        labeledRow("残り枚数", value: "\(remaining)枚")
                        Divider()
                    }
                    if let nextDate = record.nextDate {
                        labeledRow("次回交換日", value: shortDate(nextDate))
                    } else {
                        labeledRow("記録日", value: shortDate(record.date))
                    }
                }
            }

            Button { recordExchange() } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("交換する")
                }
                .foregroundColor(.white)
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.beautyRose)
                .cornerRadius(12)
            }
        }
    }

    private var siblingSteps: [BeautyRecord] {
        let descriptor = FetchDescriptor<BeautyRecord>()
        let all = (try? context.fetch(descriptor)) ?? []
        let siblings: [BeautyRecord]
        if record.parentRecordId == nil {
            siblings = all.filter { $0.id == record.id || $0.parentRecordId == record.id }
        } else {
            siblings = all.filter { $0.parentRecordId == record.parentRecordId }
        }
        return siblings.sorted { ($0.stepIndex ?? 0) < ($1.stepIndex ?? 0) }
    }

    private var surgerySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            infoSection(title: "施術情報") {
                VStack(spacing: 0) {
                    labeledRow("施術日", value: shortDate(record.date))
                    if let clinic = record.clinicName, !clinic.isEmpty {
                        Divider()
                        labeledRow("クリニック", value: clinic)
                    }
                    if let staff = record.staffName, !staff.isEmpty {
                        Divider()
                        labeledRow("担当", value: staff)
                    }
                    if let amount = record.amount {
                        Divider()
                        labeledRow("費用", value: "¥\(Int(amount))")
                    }
                    if let nextDate = record.nextDate {
                        Divider()
                        labeledRow("次回予約日", value: shortDate(nextDate))
                    }
                }
            }

            if let total = record.totalSteps, total > 0 {
                let completed = siblingSteps.filter { $0.isCompleted }.count
                infoSection(title: "工程進捗 (\(completed)/\(total))") {
                    StepProgressView(currentStep: completed, totalSteps: total)
                        .padding(.vertical, 4)
                }
                .onTapGesture { showStepList = true }
            }
        }
    }

    private var hairRemovalSection: some View {
        infoSection(title: "脱毛情報") {
            VStack(spacing: 0) {
                if let area = record.hairRemovalArea, !area.isEmpty {
                    labeledRow("部位", value: area)
                    Divider()
                }
                if let session = record.sessionNumber, let total = record.totalSessionsGoal {
                    labeledRow("回数", value: "第\(session)回 / 全\(total)回")
                    Divider()
                    ProgressView(value: Double(session), total: Double(total))
                        .tint(Color.beautyRose)
                        .padding(.vertical, 8)
                    Divider()
                }
                if let aftercare = record.aftercareDays {
                    labeledRow("アフターケア期間", value: "\(aftercare)日間")
                }
                if let amount = record.amount {
                    Divider()
                    labeledRow("費用", value: "¥\(Int(amount))")
                }
            }
        }
    }

    private var generalSection: some View {
        infoSection(title: record.category?.name ?? "記録") {
            VStack(spacing: 0) {
                labeledRow("日付", value: shortDate(record.date))
                if let amount = record.amount {
                    Divider()
                    labeledRow("金額", value: "¥\(Int(amount))")
                }
                if let nextDate = record.nextDate {
                    Divider()
                    labeledRow("次回日", value: shortDate(nextDate))
                }
            }
        }
    }

    // MARK: - Common Sections

    private var photoSection: some View {
        infoSection(title: "写真") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(record.photos) { photo in
                        if let uiImage = UIImage(data: photo.imageData) {
                            VStack(spacing: 4) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                Text(photo.label.rawValue)
                                    .font(.system(size: 10))
                                    .foregroundColor(.beautySubText)
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func urlSection(_ urlString: String) -> some View {
        infoSection(title: "URL") {
            if let url = URL(string: urlString) {
                Link(destination: url) {
                    Text(urlString)
                        .font(.body)
                        .foregroundColor(Color.contactBlue)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            } else {
                Text(urlString)
                    .font(.body)
                    .foregroundColor(.beautySubText)
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func infoSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.beautyText)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.beautyCard)
        .cornerRadius(12)
    }

    private func labeledRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.beautySubText)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.beautyText)
        }
        .padding(.vertical, 8)
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/M/d"
        return formatter.string(from: date)
    }

    // MARK: - Actions

    private func recordExchange() {
        record.contactStartDate = Date()
        record.remainingCount = (record.remainingCount ?? 1) - 1
        record.nextDate = Calendar.current.date(
            byAdding: .day, value: record.contactCycleDays ?? 14, to: Date()
        )
        NotificationManager.shared.scheduleNotifications(for: record)
        try? context.save()

        let dateStr = record.nextDate.map { shortDate($0) } ?? ""
        toastMessage = "✨ 次回交換日を\(dateStr)にセットしました"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            toastMessage = nil
        }
    }
}
