import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @State private var showAddSheet = false
    @State private var showScanSheet = false
    @State private var toastMessage: String?

    @State private var selectedTab: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isHorizontalGesture: Bool? = nil

    var body: some View {
        if hasCompletedOnboarding {
            mainView
        } else {
            OnboardingView()
        }
    }

    var mainView: some View {
        ZStack {
            GeometryReader { geo in
                ZStack(alignment: .bottom) {

                    HStack(spacing: 0) {
                        HomeView(showAddSheet: $showAddSheet, toastMessage: $toastMessage)
                            .frame(width: geo.size.width)
                        CalendarView(showAddSheet: $showAddSheet)
                            .frame(width: geo.size.width)
                        AnalysisView()
                            .frame(width: geo.size.width)
                        DiagnosisView()
                            .frame(width: geo.size.width)
                        SettingsView()
                            .frame(width: geo.size.width)
                    }
                    .frame(width: geo.size.width, alignment: .leading)
                    .offset(x: pageOffset(screenWidth: geo.size.width))
                    .clipped()
                    .gesture(swipeGesture(screenWidth: geo.size.width))

                    CustomTabBar(
                        selectedTab: $selectedTab,
                        dragOffset: dragOffset,
                        screenWidth: geo.size.width,
                        pendingDiagnosisCount: pendingDiagnosisCount
                    )
                }
            }
            .ignoresSafeArea(edges: .bottom)

            FABButton(
                onManualAdd: { showAddSheet = true },
                onScanAdd:   { showScanSheet = true }
            )

            if let message = toastMessage {
                VStack {
                    ToastView(message: message)
                        .padding(.top, 60)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: toastMessage)
            }
        }
        .sheet(isPresented: $showAddSheet) { AddView() }
        .sheet(isPresented: $showScanSheet) { ReceiptScanSheet() }
    }

    private func pageOffset(screenWidth: CGFloat) -> CGFloat {
        let base = -CGFloat(selectedTab) * screenWidth
        let total = base + dragOffset

        let tabCount = 5
        if selectedTab == 0 && dragOffset > 0 {
            return base + dragOffset * 0.25
        } else if selectedTab == tabCount - 1 && dragOffset < 0 {
            return base + dragOffset * 0.25
        }
        return total
    }

    private func swipeGesture(screenWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { value in
                if isHorizontalGesture == nil {
                    let isH = abs(value.translation.width) > abs(value.translation.height) * 1.3
                    let isV = abs(value.translation.height) > abs(value.translation.width) * 1.3
                    if isH      { isHorizontalGesture = true }
                    else if isV { isHorizontalGesture = false }
                }
                guard isHorizontalGesture == true else { return }
                dragOffset = value.translation.width
            }
            .onEnded { value in
                defer {
                    isHorizontalGesture = nil
                }
                guard isHorizontalGesture == true else {
                    dragOffset = 0
                    return
                }
                let velocity  = value.velocity.width
                let threshold = screenWidth * 0.3
                let tabCount  = 5

                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                    if value.translation.width < -threshold || velocity < -600 {
                        selectedTab = min(selectedTab + 1, tabCount - 1)
                    } else if value.translation.width > threshold || velocity > 600 {
                        selectedTab = max(selectedTab - 1, 0)
                    }
                    dragOffset = 0
                }
            }
    }

    @Query private var records: [BeautyRecord]
    var pendingDiagnosisCount: Int {
        records.filter { record in
            guard let lastDiagnosed = record.lastDiagnosedAt else { return true }
            return Calendar.current.dateComponents(
                [.day], from: lastDiagnosed, to: Date()
            ).day ?? 0 >= 30
        }.count
    }
}
