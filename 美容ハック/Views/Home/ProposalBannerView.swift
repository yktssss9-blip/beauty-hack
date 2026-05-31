import SwiftUI

struct ProposalBannerView: View {
    let allRecords: [BeautyRecord]
    @State private var isExpanded = false

    private var aftercareItems: [BeautyRecord] {
        let today = Calendar.current.startOfDay(for: Date())
        return allRecords
            .filter { $0.isAftercare && $0.date >= today }
            .sorted { $0.date < $1.date }
            .prefix(2)
            .map { $0 }
    }

    private var upcomingItems: [BeautyRecord] {
        let today = Calendar.current.startOfDay(for: Date())
        let soon = Calendar.current.date(byAdding: .day, value: 4, to: today)!
        return allRecords
            .filter { !$0.isAftercare && $0.date >= today && $0.date < soon }
            .sorted { $0.date < $1.date }
            .prefix(3)
            .map { $0 }
    }

    private var totalCount: Int {
        aftercareItems.count + upcomingItems.count
    }

    private var hasItems: Bool {
        totalCount > 0
    }

    var body: some View {
        if hasItems {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("🚨")
                        (Text("美容ハックからの").foregroundColor(.beautyText)
                         + Text("ご提案").foregroundColor(.beautyRose))
                            .font(.subheadline.bold())
                        Spacer()
                        Text("\(totalCount)件")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.beautyAlertRed)
                            .clipShape(Capsule())
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.beautyRose)
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    VStack(spacing: 6) {
                        ForEach(aftercareItems) { item in
                            aftercareRow(item: item)
                        }
                        ForEach(upcomingItems) { item in
                            upcomingRow(item: item)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(16)
            .background(Color.beautyRose.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.beautyRose.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }

    private func aftercareRow(item: BeautyRecord) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.caption.weight(.semibold))
                .foregroundColor(Color(hex: "#FFB347"))
                .frame(width: 20)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .foregroundColor(.beautyText)
                    .lineLimit(1)
                Text(aftercareReason(for: item.title))
                    .font(.caption2)
                    .foregroundColor(.beautyRose)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
    }

    private func upcomingRow(item: BeautyRecord) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.caption.weight(.semibold))
                .foregroundColor(.beautyRose)
                .frame(width: 20)
            Text("\(shortDate(item.date))  \(item.title)")
                .font(.subheadline)
                .foregroundColor(.beautyText)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
    }

    private func aftercareReason(for title: String) -> String {
        if title.contains("日焼け") {
            return "レーザー照射後の肌はメラニンを産生しやすく、紫外線を浴びると炎症・色素沈着の原因になります"
        } else if title.contains("保湿") {
            return "施術後は肌バリアが低下しており、保湿不足が回復を遅らせます"
        } else if title.contains("アフターケア") {
            return "施術直後の肌は敏感な状態です。丁寧なケアが仕上がりを左右します"
        } else if title.contains("検診") || title.contains("確認") {
            return "経過を確認することで、問題の早期発見につながります"
        } else {
            return "施術後のケアが効果と肌回復のカギです"
        }
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M/d"
        return f.string(from: date)
    }
}
