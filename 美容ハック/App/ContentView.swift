import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @State private var showAddSheet = false
    @State private var showScanSheet = false
    @State private var toastMessage: String?

    var body: some View {
        if hasCompletedOnboarding {
            mainView
        } else {
            OnboardingView()
        }
    }

    var mainView: some View {
        ZStack {
            TabView {
                HomeView(showAddSheet: $showAddSheet, toastMessage: $toastMessage)
                    .tabItem { Label("ホーム", systemImage: "house.fill") }

                CalendarView(showAddSheet: $showAddSheet)
                    .tabItem { Label("カレンダー", systemImage: "calendar") }

                AnalysisView()
                    .tabItem { Label("分析", systemImage: "chart.bar.fill") }

                DiagnosisView()
                    .tabItem { Label("診断", systemImage: "sparkles") }
                    .badge(pendingDiagnosisCount)

                SettingsView()
                    .tabItem { Label("設定", systemImage: "gearshape.fill") }
            }
            .tint(Color.beautyRose)

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
        .sheet(isPresented: $showAddSheet) {
            AddView()
        }
        .sheet(isPresented: $showScanSheet) {
            ReceiptScanSheet()
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
