import SwiftUI

struct FABButton: View {
    let onManualAdd: () -> Void
    let onScanAdd: () -> Void

    @State private var isExpanded = false

    var body: some View {
        ZStack {
            if isExpanded {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { isExpanded = false }
                    }
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 14) {
                        if isExpanded {
                            FABMenuItem(
                                icon: "doc.viewfinder",
                                label: "スキャンして追加",
                                color: Color.contactBlue
                            ) {
                                withAnimation { isExpanded = false }
                                onScanAdd()
                            }
                            FABMenuItem(
                                icon: "square.and.pencil",
                                label: "手動で追加",
                                color: Color.beautyRose
                            ) {
                                withAnimation { isExpanded = false }
                                onManualAdd()
                            }
                        }

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isExpanded.toggle()
                            }
                        } label: {
                            Image(systemName: isExpanded ? "xmark" : "plus")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(isExpanded ? 45 : 0))
                                .frame(width: 56, height: 56)
                                .background(isExpanded ? Color.beautySubText : Color.beautyRose)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                                .animation(.spring(response: 0.3), value: isExpanded)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 90)
                }
            }
            .ignoresSafeArea()
        }
    }
}

private struct FABMenuItem: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(label)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Capsule())

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(color)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
