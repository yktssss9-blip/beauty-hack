import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let dragOffset: CGFloat
    let screenWidth: CGFloat
    let pendingDiagnosisCount: Int

    private let items: [(icon: String, label: String)] = [
        ("house.fill",       "ホーム"),
        ("calendar",         "カレンダー"),
        ("chart.bar.fill",   "分析"),
        ("sparkles",         "診断"),
        ("gearshape.fill",   "設定"),
    ]

    private var continuousTab: CGFloat {
        let raw = CGFloat(selectedTab) - dragOffset / screenWidth
        return max(0, min(CGFloat(items.count - 1), raw))
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let tabWidth = geo.size.width / CGFloat(items.count)
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.beautyRose)
                    .frame(width: tabWidth * 0.45, height: 3)
                    .offset(x: tabWidth * continuousTab + tabWidth * 0.275)
            }
            .frame(height: 3)

            HStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                            selectedTab = index
                        }
                    } label: {
                        VStack(spacing: 3) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 22))
                                    .foregroundColor(
                                        selectedTab == index ? .beautyRose : .beautySubText
                                    )
                                if index == 3 && pendingDiagnosisCount > 0 {
                                    Text("\(min(pendingDiagnosisCount, 99))")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 3).padding(.vertical, 2)
                                        .background(Color.beautyAlertRed)
                                        .clipShape(Capsule())
                                        .offset(x: 8, y: -6)
                                }
                            }
                            Text(item.label)
                                .font(.system(size: 10))
                                .foregroundColor(
                                    selectedTab == index ? .beautyRose : .beautySubText
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }

            Color.clear.frame(height: 0)
                .padding(.bottom, UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.windows.first?.safeAreaInsets.bottom ?? 0
                )
        }
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .top)
    }
}
