import SwiftUI

struct PaymentHistoryView: View {
    let records: [BeautyRecord]

    @Environment(\.dismiss) private var dismiss

    private var paidRecords: [BeautyRecord] {
        records
            .filter { $0.amount != nil }
            .sorted { $0.date > $1.date }
    }

    private var total: Double {
        paidRecords.compactMap { $0.amount }.reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("合計")
                            .font(.subheadline)
                            .foregroundColor(.beautySubText)
                        Spacer()
                        Text("¥\(Int(total).formatted())")
                            .font(.title3.bold())
                            .foregroundColor(.beautyText)
                    }
                    .padding(.vertical, 4)
                }

                Section("内訳") {
                    ForEach(paidRecords) { record in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(record.title)
                                    .font(.subheadline)
                                    .foregroundColor(.beautyText)
                                Text(record.date, format: .dateTime.year().month(.defaultDigits).day())
                                    .font(.caption)
                                    .foregroundColor(.beautySubText)
                            }
                            Spacer()
                            if let amount = record.amount {
                                Text("¥\(Int(amount).formatted())")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.beautyText)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("支払い履歴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}
