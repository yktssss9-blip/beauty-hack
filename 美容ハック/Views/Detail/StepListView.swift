import SwiftUI
import SwiftData

struct StepListView: View {
    let record: BeautyRecord
    @Environment(\.modelContext) private var modelContext

    private var steps: [BeautyRecord] {
        let descriptor = FetchDescriptor<BeautyRecord>()
        let all = (try? modelContext.fetch(descriptor)) ?? []

        let siblings: [BeautyRecord]
        if record.parentRecordId == nil {
            siblings = all.filter { $0.id == record.id || $0.parentRecordId == record.id }
        } else {
            siblings = all.filter { $0.parentRecordId == record.parentRecordId }
        }

        return siblings.sorted { ($0.stepIndex ?? 0) < ($1.stepIndex ?? 0) }
    }

    var body: some View {
        NavigationStack {
            List(steps, id: \.id) { step in
                StepRowView(step: step) {
                    step.isCompleted.toggle()
                    try? modelContext.save()
                }
            }
            .navigationTitle("工程一覧")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct StepRowView: View {
    let step: BeautyRecord
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(step.isCompleted ? Color.beautyRose : Color.beautySubText.opacity(0.4))
                    .animation(.easeInOut(duration: 0.2), value: step.isCompleted)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Step \(step.stepIndex ?? 0)")
                        .font(.caption)
                        .foregroundColor(.beautySubText)
                    Text(step.title)
                        .font(.body.weight(.semibold))
                        .foregroundColor(step.isCompleted ? .beautySubText : .beautyText)
                        .strikethrough(step.isCompleted, color: .beautySubText)
                    Text(shortDate(step.date))
                        .font(.caption)
                        .foregroundColor(.beautySubText)
                }
                Spacer()
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/M/d"
        return formatter.string(from: date)
    }
}
