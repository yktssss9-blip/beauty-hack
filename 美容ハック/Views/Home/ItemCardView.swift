import SwiftUI

struct ItemCardView: View {
    let record: BeautyRecord
    @Binding var toastMessage: String?

    private var categoryColor: Color {
        guard let hex = record.category?.color, !hex.isEmpty else { return .beautyRose }
        return Color(hex: hex)
    }

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(categoryColor.opacity(0.7))
                .frame(width: 4)
                .padding(.vertical, 10)

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: record.category?.icon ?? "sparkles")
                        .font(.system(size: 18))
                        .foregroundColor(categoryColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(record.title)
                        .font(.subheadline.bold())
                        .foregroundColor(record.isCompleted ? .beautySubText : .beautyText)
                        .strikethrough(record.isCompleted, color: .beautySubText)
                        .lineLimit(1)
                    if let category = record.category {
                        Text(category.name)
                            .font(.caption)
                            .foregroundColor(.beautySubText)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    if let amount = record.amount {
                        Text("¥\(Int(amount).formatted())")
                            .font(.subheadline.bold())
                            .foregroundColor(record.isCompleted ? .beautySubText : .beautyText)
                            .strikethrough(record.isCompleted, color: .beautySubText)
                    }
                    Text(shortDate(record.date))
                        .font(.caption)
                        .foregroundColor(.beautySubText)
                        .strikethrough(record.isCompleted, color: .beautySubText)
                }

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.beautySubText)
                    .padding(.leading, 4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .opacity(record.isCompleted ? 0.6 : 1.0)
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M/d"
        return f.string(from: date)
    }
}
