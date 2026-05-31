import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var showAddSheet: Bool
    @Binding var toastMessage: String?
    @Query private var records: [BeautyRecord]

    @State private var sortOrder: SortOrder = .deadline
    @State private var selectedRecord: BeautyRecord?
    @State private var showHairDetail = false
    @State private var showPaymentHistory = false
    @State private var selectedCategoryName: String? = nil
    @State private var searchText = ""

    enum SortOrder: String, CaseIterable {
        case deadline = "直近順"
        case category = "カテゴリ別"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SummaryCardView(records: records, onTapTotal: { showPaymentHistory = true })

                    ProposalBannerView(allRecords: records)

                    if !hairRecords.isEmpty {
                        HairRemovalSummaryCard(records: hairRecords)
                            .onTapGesture { showHairDetail = true }
                    }

                    sortTabView

                    categoryFilterView

                    LazyVStack(spacing: 12) {
                        ForEach(sortedRecords) { record in
                            ItemCardView(record: record, toastMessage: $toastMessage)
                                .onTapGesture { selectedRecord = record }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 100)
            }
            .background(Color.beautyBG)
            .searchable(text: $searchText, prompt: "タイトルで検索")
            .navigationTitle("美容ハック")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedRecord) { record in
                DetailView(record: record, toastMessage: $toastMessage)
            }
            .sheet(isPresented: $showPaymentHistory) {
                PaymentHistoryView(records: records)
            }
            .sheet(isPresented: $showHairDetail) {
                NavigationStack {
                    List(hairRecords) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.title)
                                .font(.subheadline.bold())
                                .foregroundColor(.beautyText)
                            HStack {
                                Text(record.date, format: .dateTime.year().month(.defaultDigits).day())
                                Spacer()
                                if let amount = record.amount {
                                    Text("¥\(Int(amount).formatted())")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.beautySubText)
                        }
                        .padding(.vertical, 2)
                    }
                    .navigationTitle("脱毛記録")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("閉じる") { showHairDetail = false }
                        }
                    }
                }
            }
        }
    }

    private var sortTabView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Button(order.rawValue) {
                        sortOrder = order
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(sortOrder == order ? Color.beautyDark : Color.white)
                    .foregroundColor(sortOrder == order ? .white : .beautyText)
                    .clipShape(Capsule())
                    .font(.subheadline)
                    .animation(.easeInOut(duration: 0.15), value: sortOrder)
                }
            }
            .padding(.horizontal)
        }
    }

    private var hairRecords: [BeautyRecord] {
        records.filter { $0.hairRemovalArea != nil }
    }

    private var visibleRecords: [BeautyRecord] {
        let today = Calendar.current.startOfDay(for: Date())
        let base = records.filter { record in
            guard !record.isAftercare else { return false }
            return (record.nextDate ?? record.date) >= today
        }
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredRecords: [BeautyRecord] {
        guard let name = selectedCategoryName else { return visibleRecords }
        return visibleRecords.filter { $0.category?.name == name }
    }

    private var sortedRecords: [BeautyRecord] {
        switch sortOrder {
        case .deadline:
            return filteredRecords.sorted {
                ($0.nextDate ?? $0.date) < ($1.nextDate ?? $1.date)
            }
        case .category:
            return filteredRecords.sorted { ($0.category?.name ?? "") < ($1.category?.name ?? "") }
        }
    }

    private var availableCategories: [(name: String, icon: String, color: String)] {
        var seen = Set<String>()
        var result: [(name: String, icon: String, color: String)] = []
        for record in visibleRecords {
            if let cat = record.category, !seen.contains(cat.name) {
                seen.insert(cat.name)
                result.append((name: cat.name, icon: cat.icon ?? "sparkles", color: cat.color ?? ""))
            }
        }
        return result.sorted { $0.name < $1.name }
    }

    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    selectedCategoryName = nil
                } label: {
                    Text("すべて")
                        .font(.caption)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(selectedCategoryName == nil ? Color.beautyDark : Color.white)
                        .foregroundColor(selectedCategoryName == nil ? .white : .beautyText)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                ForEach(availableCategories, id: \.name) { cat in
                    let catColor: Color = cat.color.isEmpty ? .beautyRose : Color(hex: cat.color)
                    let isSelected = selectedCategoryName == cat.name
                    Button {
                        selectedCategoryName = isSelected ? nil : cat.name
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: cat.icon)
                                .font(.caption2)
                            Text(cat.name)
                                .font(.caption)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(isSelected ? catColor.opacity(0.15) : Color.white)
                        .foregroundColor(isSelected ? catColor : .beautyText)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(isSelected ? catColor.opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}
