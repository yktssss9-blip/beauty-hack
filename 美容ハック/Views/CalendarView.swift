import SwiftUI
import SwiftData

struct CalendarView: View {
    @Binding var showAddSheet: Bool
    @Query private var records: [BeautyRecord]

    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())
    @State private var selectedDate: Date?
    @State private var showDaySheet = false
    @State private var categoryFilter: UUID? = nil
    @State private var selectedRecord: BeautyRecord?
    @State private var slideForward = true

    private let cal = Calendar.current

    private var monthRecords: [BeautyRecord] {
        let all = records.filter {
            cal.isDate($0.date, equalTo: displayedMonth, toGranularity: .month) && !$0.isAftercare
        }
        if let filter = categoryFilter {
            return all.filter { $0.category?.id == filter }
        }
        return all
    }

    private var monthTotal: Double {
        monthRecords.compactMap(\.amount).reduce(0, +)
    }

    private var recordsByDate: [Date: [BeautyRecord]] {
        Dictionary(grouping: monthRecords) { cal.startOfDay(for: $0.date) }
    }

    private var uniqueCategories: [BeautyCategory] {
        var seen: Set<UUID> = []
        return records
            .compactMap(\.category)
            .filter { seen.insert($0.id).inserted }
            .sorted { $0.sortOrder < $1.sortOrder }
            .prefix(4)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    monthHeader
                    weekdayHeader

                    VStack(spacing: 0) {
                        CustomCalendarGrid(
                            month: displayedMonth,
                            recordsByDate: recordsByDate,
                            selectedDate: $selectedDate,
                            showDaySheet: $showDaySheet,
                            onRecordTapped: { record in selectedRecord = record }
                        )
                        if !uniqueCategories.isEmpty {
                            categoryShortcuts
                        }
                    }
                    .id(displayedMonth)
                    .transition(.asymmetric(
                        insertion: .move(edge: slideForward ? .trailing : .leading),
                        removal: .move(edge: slideForward ? .leading : .trailing)
                    ))
                    .clipped()

                    monthSummary
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            guard abs(value.translation.width) > abs(value.translation.height),
                                  abs(value.translation.width) > 50 else { return }
                            withAnimation(.easeInOut(duration: 0.55)) {
                                if value.translation.width < 0 {
                                    slideForward = true
                                    displayedMonth = cal.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                                } else {
                                    slideForward = false
                                    displayedMonth = cal.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                                }
                            }
                        }
                )
            }
            .background(Color.beautyBG)
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: Binding(
                get: { selectedRecord != nil },
                set: { if !$0 { selectedRecord = nil } }
            )) {
                if let record = selectedRecord {
                    DetailView(record: record, toastMessage: .constant(nil))
                }
            }
        }
        .sheet(isPresented: $showDaySheet) {
            if let date = selectedDate {
                DayBottomSheet(
                    date: date,
                    records: recordsByDate[cal.startOfDay(for: date)] ?? [],
                    showAddSheet: $showAddSheet
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Sub-views

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.55)) {
                    slideForward = false
                    displayedMonth = cal.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.beautyText)
                    .padding(10)
                    .contentShape(Rectangle())
            }
            Spacer()
            Text(monthTitle)
                .font(.headline)
                .foregroundColor(.beautyText)
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.55)) {
                    slideForward = true
                    displayedMonth = cal.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(.beautyText)
                    .padding(10)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: displayedMonth)
    }

    private var weekdayHeader: some View {
        let symbols = [("日", Color.red), ("月", Color.beautySubText), ("火", Color.beautySubText),
                       ("水", Color.beautySubText), ("木", Color.beautySubText), ("金", Color.beautySubText),
                       ("土", Color(hex: "#4A90D9"))]
        return HStack(spacing: 0) {
            ForEach(symbols, id: \.0) { symbol, color in
                Text(symbol)
                    .font(.caption)
                    .foregroundColor(color)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }

    private var categoryShortcuts: some View {
        HStack(spacing: 20) {
            ForEach(uniqueCategories) { cat in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        categoryFilter = categoryFilter == cat.id ? nil : cat.id
                    }
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(
                                    categoryFilter == cat.id
                                    ? Color(hex: cat.color)
                                    : Color(hex: cat.color).opacity(0.15)
                                )
                                .frame(width: 52, height: 52)
                            Image(systemName: cat.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(
                                    categoryFilter == cat.id ? .white : Color(hex: cat.color)
                                )
                        }
                        Text(cat.name)
                            .font(.caption2)
                            .foregroundColor(categoryFilter == cat.id ? Color(hex: cat.color) : .beautySubText)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var monthSummary: some View {
        let sorted = monthRecords.sorted { $0.date < $1.date }
        return VStack(alignment: .leading, spacing: 0) {
            Text("\(monthShortTitle)の支払い予定（\(monthRecords.count)件）")
                .font(.subheadline)
                .foregroundColor(.beautySubText)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 4)

            HStack {
                Text("\(monthShortTitle)の合計")
                    .font(.headline)
                    .foregroundColor(.beautyText)
                Spacer()
                Text("¥\(Int(monthTotal).formatted())")
                    .font(.headline)
                    .foregroundColor(.beautyRose)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider()

            ForEach(sorted) { record in
                NavigationLink(destination: DetailView(record: record, toastMessage: .constant(nil))) {
                    recordRow(record)
                }
                Divider().padding(.leading, 56)
            }
        }
        .background(Color.beautyCard)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 100)
    }

    private var monthShortTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月"
        return formatter.string(from: displayedMonth)
    }

    private func recordRow(_ record: BeautyRecord) -> some View {
        HStack(spacing: 12) {
            Text(shortDate(record.date))
                .font(.caption)
                .foregroundColor(.beautySubText)
                .frame(width: 32, alignment: .leading)

            if let cat = record.category {
                Image(systemName: cat.icon)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: cat.color))
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: "circle.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.beautySubText)
                    .frame(width: 24, height: 24)
            }

            Text(record.title)
                .font(.body)
                .foregroundColor(.beautyText)
                .lineLimit(1)

            Spacer()

            if let amount = record.amount {
                Text("¥\(Int(amount).formatted())")
                    .font(.body)
                    .foregroundColor(.beautySubText)
            }
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.beautySubText)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}
