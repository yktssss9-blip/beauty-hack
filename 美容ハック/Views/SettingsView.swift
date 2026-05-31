import SwiftUI
import SwiftData
import MessageUI
import StoreKit
import EventKit

// MARK: - Value type wrapper for EKEvent

struct CalendarEventItem: Identifiable {
    let id = UUID()
    let title: String
    let startDate: Date
    let notes: String?
    let detectedCategory: String?
}

// MARK: - Settings View

struct SettingsView: View {
    @Query(sort: \BeautyCategory.sortOrder) private var categories: [BeautyCategory]
    @AppStorage("notificationHour") private var notificationHour = 9
    @AppStorage("isPro") private var isPro = false

    @State private var showMailComposer = false
    @State private var showCalendarSheet = false
    @State private var showShareSheet = false
    @State private var importedEvents: [CalendarEventItem] = []
    @State private var isLoadingCalendar = false

    var body: some View {
        NavigationStack {
            List {
                notificationSection
                calendarSection
                shareSection
                proSection
                supportSection
                versionSection
            }
            .navigationTitle("設定")
        }
        .sheet(isPresented: $showMailComposer) {
            MailComposerView(
                recipients: ["sykt.feedback@gmail.com"],
                subject: "美容ハック フィードバック（自動入力）"
            )
        }
        .sheet(isPresented: $showCalendarSheet) {
            CalendarImportSheet(events: importedEvents)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheetView()
        }
    }

    // MARK: - Sections

    private var notificationSection: some View {
        Section("通知設定") {
            ForEach(categories) { category in
                Toggle(isOn: Binding(
                    get: { category.isNotificationEnabled },
                    set: { category.isNotificationEnabled = $0 }
                )) {
                    Label(category.name, systemImage: category.icon)
                        .foregroundStyle(Color(hex: category.color))
                }
            }

            Picker("通知時間帯", selection: $notificationHour) {
                ForEach(0..<24, id: \.self) { hour in
                    Text("\(hour)時").tag(hour)
                }
            }
        }
    }

    private var calendarSection: some View {
        Section("カレンダー連携") {
            Button {
                Task { await importCalendar() }
            } label: {
                HStack {
                    Label("カレンダーから取り込む", systemImage: "calendar.badge.plus")
                        .foregroundStyle(.black)
                    Spacer()
                    if isLoadingCalendar {
                        ProgressView()
                    }
                }
            }
            .disabled(isLoadingCalendar)
        }
    }

    private var shareSection: some View {
        Section("シェア") {
            Button {
                if isPro {
                    showShareSheet = true
                } else {
                    isPro = true // Pro購入フローに繋げる想定
                }
            } label: {
                HStack {
                    Label("シェアカードを作成", systemImage: "square.and.arrow.up")
                        .foregroundStyle(.black)
                    Spacer()
                    if !isPro {
                        Text("Pro")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.2))
                            .foregroundStyle(.yellow)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var proSection: some View {
        Section("Proプラン") {
            if isPro {
                Label("Proプラン利用中", systemImage: "crown.fill")
                    .foregroundStyle(.yellow)
            } else {
                Button {
                    isPro = true
                } label: {
                    Label("Proにアップグレード", systemImage: "crown")
                        .foregroundStyle(.black)
                }

                Button("購入を復元") {
                    isPro = true
                }
                .foregroundStyle(.black)
            }
        }
    }

    private var supportSection: some View {
        Section("サポート") {
            if MFMailComposeViewController.canSendMail() {
                Button {
                    showMailComposer = true
                } label: {
                    Label("フィードバックを送る", systemImage: "envelope")
                        .foregroundStyle(.black)
                }
            }

            Button {
                requestReview()
            } label: {
                Label("レビューを書く", systemImage: "star")
                    .foregroundStyle(.black)
            }
        }
    }

    private var versionSection: some View {
        Section {
            HStack {
                Text("バージョン")
                Spacer()
                Text(
                    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
                )
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func importCalendar() async {
        isLoadingCalendar = true
        defer { isLoadingCalendar = false }

        guard await CalendarImporter.shared.requestAccess() else { return }

        let events = CalendarImporter.shared.fetchBeautyEvents()
        importedEvents = events.map { event in
            CalendarEventItem(
                title: event.title ?? "（タイトルなし）",
                startDate: event.startDate,
                notes: event.notes,
                detectedCategory: CalendarImporter.shared.autoDetectCategory(
                    from: event.title ?? ""
                )
            )
        }
        showCalendarSheet = true
    }

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

// MARK: - Calendar Import Confirmation Sheet

private struct CalendarImportSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BeautyCategory.sortOrder) private var categories: [BeautyCategory]

    let events: [CalendarEventItem]
    @State private var selectedIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Group {
                if events.isEmpty {
                    ContentUnavailableView(
                        "美容イベントが見つかりません",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("今後3ヶ月のカレンダーに美容関連の予定がありませんでした")
                    )
                } else {
                    List(events) { event in
                        CalendarEventRow(
                            event: event,
                            isSelected: selectedIDs.contains(event.id)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedIDs.contains(event.id) {
                                selectedIDs.remove(event.id)
                            } else {
                                selectedIDs.insert(event.id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("美容予定を取り込む")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("取り込む(\(selectedIDs.count))") {
                        importSelected()
                        dismiss()
                    }
                    .disabled(selectedIDs.isEmpty)
                }
            }
            .onAppear {
                selectedIDs = Set(events.map(\.id))
            }
        }
    }

    private func importSelected() {
        let targets = events.filter { selectedIDs.contains($0.id) }
        for item in targets {
            let record = BeautyRecord()
            record.title = item.title
            record.date = item.startDate
            record.memo = item.notes
            if let catName = item.detectedCategory {
                record.category = categories.first { $0.name == catName }
            }
            modelContext.insert(record)
        }
        try? modelContext.save()
    }
}

private struct CalendarEventRow: View {
    let event: CalendarEventItem
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color.beautyRose : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.body)
                HStack(spacing: 8) {
                    Text(event.startDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let cat = event.detectedCategory {
                        Text(cat)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.beautyRose.opacity(0.15))
                            .foregroundStyle(Color.beautyRose)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Mail Composer

struct MailComposerView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients(recipients)
        vc.setSubject(subject)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            dismiss()
        }
    }
}
