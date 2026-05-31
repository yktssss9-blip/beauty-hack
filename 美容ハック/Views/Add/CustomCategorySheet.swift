import SwiftUI
import SwiftData

struct CustomCategorySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let editingCategory: BeautyCategory?

    @State private var name: String
    @State private var selectedColorHex: String
    @State private var selectedIcon: String
    @FocusState private var isNameFocused: Bool

    init(editing category: BeautyCategory? = nil) {
        editingCategory = category
        _name = State(initialValue: category?.name ?? "")
        _selectedColorHex = State(initialValue: category?.color ?? "#E8A4A4")
        _selectedIcon = State(initialValue: category?.icon ?? "sparkles")
    }

    private let colors: [(hex: String, label: String)] = [
        ("#E8A4A4", "beautyRose"),
        ("#4A90D9", "contactBlue"),
        ("#9B72CF", "surgeryPurple"),
        ("#F5C842", "permYellow"),
        ("#7BC67E", "skinGreen"),
        ("#F4A7B9", "nailPink"),
        ("#FF8A65", "coral"),
        ("#80CBC4", "mint"),
        ("#CE93D8", "lavender"),
        ("#FFAB91", "peach"),
    ]

    private let icons: [String] = [
        "sparkles", "face.smiling.fill", "eye.fill", "scissors",
        "paintbrush.pointed.fill", "drop.fill", "leaf.fill", "bag.fill",
        "star.fill", "heart.fill", "moon.stars.fill", "cross.case.fill",
        "bolt.heart.fill", "hand.sparkles.fill", "wand.and.stars", "figure.stand",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    previewArea
                    nameField
                    colorPalette
                    iconGrid
                }
                .padding()
            }
            .background(Color.beautyBG)
            .navigationTitle(editingCategory == nil ? "カスタムカテゴリ" : "カテゴリを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(Color.beautySubText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingCategory == nil ? "追加" : "保存") { saveCategory() }
                        .disabled(name.isEmpty)
                }
            }
            .onAppear { isNameFocused = true }
        }
    }

    private var previewArea: some View {
        ZStack {
            Circle()
                .fill(Color(hex: selectedColorHex).opacity(0.15))
                .frame(width: 100, height: 100)
            Image(systemName: selectedIcon)
                .font(.system(size: 60))
                .foregroundStyle(Color(hex: selectedColorHex))
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("カテゴリ名")
                .font(.subheadline.bold())
                .foregroundStyle(Color.beautySubText)
            TextField("カテゴリ名", text: $name)
                .focused($isNameFocused)
                .padding(14)
                .background(Color.beautyCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }

    private var colorPalette: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("カラー")
                .font(.subheadline.bold())
                .foregroundStyle(Color.beautySubText)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(colors, id: \.hex) { item in
                        Button {
                            selectedColorHex = item.hex
                        } label: {
                            Circle()
                                .fill(Color(hex: item.hex))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            selectedColorHex == item.hex ? Color.white : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var iconGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("アイコン")
                .font(.subheadline.bold())
                .foregroundStyle(Color.beautySubText)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(icons, id: \.self) { icon in
                    Button {
                        selectedIcon = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundStyle(Color(hex: selectedColorHex))
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .background(
                                selectedIcon == icon
                                    ? Color(hex: selectedColorHex).opacity(0.2)
                                    : Color.beautyCard
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    }
                }
            }
        }
    }

    private func saveCategory() {
        if let editing = editingCategory {
            editing.name = name
            editing.icon = selectedIcon
            editing.color = selectedColorHex
        } else {
            let timestamp = Int(Date().timeIntervalSince1970)
            let category = BeautyCategory(
                name: name,
                icon: selectedIcon,
                color: selectedColorHex,
                isPreset: false,
                sortOrder: 100 + timestamp
            )
            modelContext.insert(category)
        }
        try? modelContext.save()
        dismiss()
    }
}
