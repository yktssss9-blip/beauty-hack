import SwiftUI
import SwiftData

private struct CategoryItem {
    let name: String
    let baseIcon: String
    let badgeIcon: String?
    let color: Color
}

struct CategorySelectView: View {
    @Binding var path: [AddNavigation]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<BeautyCategory> { !$0.isPreset }, sort: \BeautyCategory.sortOrder)
    private var customCategories: [BeautyCategory]

    @State private var showAddCategory = false
    @State private var showScanSheet = false
    @State private var editingCategory: BeautyCategory?
    @State private var deletingCategory: BeautyCategory?

    private let categories: [CategoryItem] = [
        CategoryItem(name: "カラコン",   baseIcon: "eye.circle.fill",         badgeIcon: nil,         color: .contactBlue),
        CategoryItem(name: "整形",       baseIcon: "face.smiling.fill",        badgeIcon: "star.fill", color: .surgeryPurple),
        CategoryItem(name: "エステ",     baseIcon: "figure.stand",             badgeIcon: "star.fill", color: .esteRose),
        CategoryItem(name: "マツエク",   baseIcon: "eye.fill",                 badgeIcon: nil,         color: .lashBrown),
        CategoryItem(name: "ヘア",       baseIcon: "scissors",                 badgeIcon: nil,         color: .permYellow),
        CategoryItem(name: "スキンケア", baseIcon: "sparkles",                 badgeIcon: nil,         color: .skinGreen),
        CategoryItem(name: "ネイル",     baseIcon: "paintbrush.pointed.fill",  badgeIcon: nil,         color: .nailPink),
    ]

    var body: some View {
        ScrollView {
            Button {
                showScanSheet = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "doc.viewfinder.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.beautyRose)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("予約・レシートをスキャン")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.beautyText)
                        Text("写真から日付・金額を自動入力")
                            .font(.caption)
                            .foregroundStyle(Color.beautySubText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.beautySubText)
                }
                .padding(16)
                .background(Color.beautyCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.bottom, 4)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 16
            ) {
                ForEach(categories, id: \.name) { cat in
                    Button {
                        if cat.name == "カラコン" {
                            path.append(.templateSchedule(
                                categoryName: cat.name,
                                templateName: "カラコン"
                            ))
                        } else {
                            path.append(.subCategory(categoryName: cat.name))
                        }
                    } label: {
                        categoryCard(cat)
                    }
                    .buttonStyle(.plain)
                }
                ForEach(customCategories) { category in
                    Button {
                        path.append(.subCategory(categoryName: category.name))
                    } label: {
                        customCategoryCard(category)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            editingCategory = category
                        } label: {
                            Label("編集", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            deletingCategory = category
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
                Button {
                    showAddCategory = true
                } label: {
                    addCard
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .background(Color.beautyBG)
        .navigationTitle("カテゴリを選択")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") { dismiss() }
                    .foregroundStyle(Color.beautySubText)
            }
        }
        .sheet(isPresented: $showAddCategory) {
            CustomCategorySheet()
        }
        .sheet(isPresented: $showScanSheet) {
            ReceiptScanSheet()
        }
        .sheet(item: $editingCategory) { category in
            CustomCategorySheet(editing: category)
        }
        .alert(
            "カテゴリを削除",
            isPresented: Binding(
                get: { deletingCategory != nil },
                set: { if !$0 { deletingCategory = nil } }
            ),
            presenting: deletingCategory
        ) { category in
            Button("削除", role: .destructive) {
                modelContext.delete(category)
                try? modelContext.save()
                deletingCategory = nil
            }
            Button("キャンセル", role: .cancel) {}
        } message: { category in
            Text("「\(category.name)」を削除しますか？この操作は元に戻せません。")
        }
    }

    @ViewBuilder
    private func iconView(base: String, badge: String?, color: Color) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: base)
                .font(.system(size: 42))
                .foregroundStyle(color)
            if let badge {
                Image(systemName: badge)
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: "#FFD700"))
                    .offset(x: 6, y: -2)
            }
        }
        .frame(width: 58, height: 58)
    }

    private func categoryCard(_ cat: CategoryItem) -> some View {
        VStack(spacing: 14) {
            iconView(base: cat.baseIcon, badge: cat.badgeIcon, color: cat.color)
            Text(cat.name)
                .font(.headline)
                .foregroundStyle(Color.beautyText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .background(Color.beautyCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 6, y: 3)
    }

    private func customCategoryCard(_ category: BeautyCategory) -> some View {
        VStack(spacing: 14) {
            Image(systemName: category.icon)
                .font(.system(size: 46))
                .foregroundStyle(Color(hex: category.color))
            Text(category.name)
                .font(.headline)
                .foregroundStyle(Color.beautyText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .background(Color.beautyCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 6, y: 3)
    }

    private var addCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "plus")
                .font(.system(size: 36))
                .foregroundStyle(Color.beautySubText)
            Text("カテゴリを追加")
                .font(.headline)
                .foregroundStyle(Color.beautySubText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .background(Color.beautyCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.beautySubText.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
        )
    }
}
