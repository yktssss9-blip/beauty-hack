import SwiftUI

struct DayBottomSheet: View {
    let date: Date
    let records: [BeautyRecord]
    @Binding var showAddSheet: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var toastMessage: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                header

                Divider()

                if records.isEmpty {
                    emptyState
                } else {
                    recordList
                }

                Spacer()

                addButton
            }
            .background(Color.beautyBG)
        }
    }

    private var header: some View {
        HStack {
            Text(formattedDate)
                .font(.headline)
                .foregroundColor(.beautyText)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.beautySubText)
                    .font(.title3)
            }
        }
        .padding()
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日（E）"
        return formatter.string(from: date)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.beautySubText.opacity(0.4))
            Text("予定なし")
                .foregroundColor(.beautySubText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }

    private var recordList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(records) { record in
                    NavigationLink(destination: DetailView(record: record, toastMessage: $toastMessage)) {
                        recordRow(record)
                    }
                    Divider().padding(.leading, 56)
                }
            }
            .background(Color.beautyCard)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    private func recordRow(_ record: BeautyRecord) -> some View {
        HStack(spacing: 12) {
            Group {
                if let cat = record.category {
                    Image(systemName: cat.icon)
                        .foregroundColor(Color(hex: cat.color))
                } else {
                    Image(systemName: "circle.fill")
                        .foregroundColor(.beautySubText)
                }
            }
            .font(.system(size: 15))
            .frame(width: 32, height: 32)
            .background(record.category.map { Color(hex: $0.color).opacity(0.12) } ?? Color.beautySubText.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(record.title)
                    .font(.body)
                    .foregroundColor(.beautyText)
                    .lineLimit(1)
                if let amount = record.amount {
                    Text("¥\(Int(amount))")
                        .font(.caption)
                        .foregroundColor(.beautySubText)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.beautySubText)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private var addButton: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    showAddSheet = true
                }
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("この日に追加する")
                }
                .foregroundColor(.beautyRose)
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
    }
}
