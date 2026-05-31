import SwiftUI
import SwiftData

struct RecordEditView: View {
    let record: BeautyRecord

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var date: Date
    @State private var amountText: String
    @State private var clinicName: String
    @State private var memo: String
    @State private var urlText: String

    init(record: BeautyRecord) {
        self.record = record
        _title      = State(initialValue: record.title)
        _date       = State(initialValue: record.date)
        _amountText = State(initialValue: record.amount.map { "\(Int($0))" } ?? "")
        _clinicName = State(initialValue: record.clinicName ?? "")
        _memo       = State(initialValue: record.memo ?? "")
        _urlText    = State(initialValue: record.url ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("タイトル") {
                    TextField("タイトル", text: $title)
                }

                Section("日付・時間") {
                    DatePicker("日付・時間", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }

                Section("金額") {
                    TextField("金額（円）", text: $amountText)
                        .keyboardType(.numberPad)
                }

                Section("クリニック / サロン名") {
                    TextField("クリニック / サロン名", text: $clinicName)
                }

                Section("メモ") {
                    TextField("メモ（任意）", text: $memo, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("URL") {
                    TextField("URL（任意）", text: $urlText)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle("記録を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        record.title      = title.trimmingCharacters(in: .whitespaces)
        record.date       = date
        record.amount     = Double(amountText)
        record.clinicName = clinicName.isEmpty ? nil : clinicName
        record.memo       = memo.isEmpty ? nil : memo
        record.url        = urlText.isEmpty ? nil : urlText
        record.updatedAt  = Date()
        try? modelContext.save()
        dismiss()
    }
}
