import SwiftUI

struct CalendarDay {
    let date: Date
    let isCurrentMonth: Bool
}

struct CustomCalendarGrid: View {
    let month: Date
    let recordsByDate: [Date: [BeautyRecord]]
    @Binding var selectedDate: Date?
    @Binding var showDaySheet: Bool
    var onRecordTapped: ((BeautyRecord) -> Void)?

    private let cal = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    private var days: [CalendarDay?] {
        guard let monthInterval = cal.dateInterval(of: .month, for: month) else { return [] }
        let firstDay = monthInterval.start
        guard let lastDay = cal.date(byAdding: .day, value: -1, to: monthInterval.end) else { return [] }

        let firstWeekday = cal.component(.weekday, from: firstDay) - 1

        var result: [CalendarDay?] = Array(repeating: nil, count: firstWeekday)

        var current = firstDay
        while current <= lastDay {
            result.append(CalendarDay(date: current, isCurrentMonth: true))
            current = cal.date(byAdding: .day, value: 1, to: current) ?? current
        }

        let remainder = result.count % 7
        if remainder != 0 {
            result += Array(repeating: nil, count: 7 - remainder)
        }

        return result
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    DayCell(
                        day: day,
                        records: recordsByDate[cal.startOfDay(for: day.date)] ?? [],
                        isToday: cal.isDateInToday(day.date),
                        onRecordTapped: onRecordTapped
                    )
                    .onTapGesture {
                        selectedDate = day.date
                        showDaySheet = true
                    }
                } else {
                    Color.clear.frame(height: 72)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }
}

private struct DayCell: View {
    let day: CalendarDay
    let records: [BeautyRecord]
    let isToday: Bool
    var onRecordTapped: ((BeautyRecord) -> Void)?

    private let maxIcons = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            // 日付ナンバー（タップ → ボトムシート）
            ZStack {
                if isToday {
                    Circle()
                        .fill(Color.beautyRose)
                        .frame(width: 22, height: 22)
                }
                Text("\(Calendar.current.component(.day, from: day.date))")
                    .font(.system(size: 11, weight: isToday ? .bold : .regular))
                    .foregroundColor(isToday ? .white : (day.isCurrentMonth ? .beautyText : .beautySubText))
            }
            .frame(width: 22, height: 22)

            // 2×2 アイコングリッド（各アイコンタップ → 詳細へ遷移）
            iconGrid
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .padding(.horizontal, 2)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var iconGrid: some View {
        if !records.isEmpty {
            let visible = Array(records.prefix(maxIcons))
            VStack(spacing: 2) {
                iconGridRow(records: visible, from: 0)
                if visible.count > 2 {
                    iconGridRow(records: visible, from: 2)
                }
            }
        }
    }

    private func iconGridRow(records: [BeautyRecord], from start: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(start..<min(start + 2, records.count), id: \.self) { i in
                iconQuadrant(records[i])
            }
            if records.count - start == 1 {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }

    @ViewBuilder
    private func iconQuadrant(_ record: BeautyRecord) -> some View {
        if let cat = record.category {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: cat.color).opacity(0.15))
                Image(systemName: cat.icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: cat.color))
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .onTapGesture { onRecordTapped?(record) }
        } else {
            Color.clear
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
        }
    }
}
