import SwiftUI

struct SummaryCardView: View {
    let records: [BeautyRecord]
    var onTapTotal: (() -> Void)? = nil

    private var totalAmount: Double {
        records.compactMap { $0.amount }.reduce(0, +)
    }

    private var annualEstimate: Double {
        records.compactMap { record -> Double? in
            guard let amount = record.amount, let cycle = record.cycleDays, cycle > 0 else { return nil }
            return amount / Double(cycle) * 365
        }.reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("合計美容費")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Text("¥\(Int(totalAmount).formatted())")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("年間換算")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    Text("¥\(Int(annualEstimate).formatted())")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("登録件数")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(records.filter { $0.amount != nil }.count)件")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(20)
        .background(Color.beautyDark)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .onTapGesture { onTapTotal?() }
    }
}
