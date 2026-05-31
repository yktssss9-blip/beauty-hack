import SwiftUI
import SwiftData
import UserNotifications

struct CategorySelectView: View {
    @Binding var path: [AddNavigation]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \BeautyCategory.sortOrder)
    private var allCategories: [BeautyCategory]

    @State private var showAddCategory = false
    @State private var showScanSheet = false
    @State private var editingCategory: BeautyCategory?
    @State private var deletingCategory: BeautyCategory?
    @State private var isEditing = false

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
                ForEach(allCategories) { category in
                    categoryGridItem(category)
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
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "完了" : "編集") {
                    isEditing.toggle()
                }
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
                deleteCategory(category)
            }
            Button("キャンセル", role: .cancel) {}
        } message: { category in
            if category.isPreset {
                Text("「\(category.name)」を削除しますか？この操作は元に戻せません。関連する記録もすべて削除されます。")
            } else {
                Text("「\(category.name)」を削除しますか？この操作は元に戻せません。")
            }
        }
    }

    @ViewBuilder
    private func categoryGridItem(_ category: BeautyCategory) -> some View {
        ZStack(alignment: .topLeading) {
            Button {
                guard !isEditing else { return }
                navigateToCategory(category)
            } label: {
                categoryCardView(category)
            }
            .buttonStyle(.plain)
            .contextMenu {
                if !category.isPreset {
                    Button {
                        editingCategory = category
                    } label: {
                        Label("編集", systemImage: "pencil")
                    }
                }
                Button(role: .destructive) {
                    deletingCategory = category
                } label: {
                    Label("削除", systemImage: "trash")
                }
            }

            if isEditing {
                Button {
                    deletingCategory = category
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.red)
                        .background(Color.white, in: Circle())
                }
                .offset(x: -6, y: -6)
            }
        }
    }

    private func navigateToCategory(_ category: BeautyCategory) {
        if category.name == "カラコン" {
            path.append(.templateSchedule(
                categoryName: category.name,
                templateName: "カラコン"
            ))
        } else {
            path.append(.subCategory(categoryName: category.name))
        }
    }

    private func deleteCategory(_ category: BeautyCategory) {
        NotificationManager.shared.cancelNotifications(for: category)
        modelContext.delete(category)
        try? modelContext.save()
        deletingCategory = nil
    }

    private func categoryCardView(_ category: BeautyCategory) -> some View {
        let color = Color(hex: category.color)
        return VStack(spacing: 14) {
            Image(systemName: category.icon)
                .font(.system(size: 42))
                .foregroundStyle(color)
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
