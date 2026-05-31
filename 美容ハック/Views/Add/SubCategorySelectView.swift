import SwiftUI

private struct SubItem: Identifiable {
    var id: String { name }
    let name: String
    let templateName: String
    let emoji: String
}

private struct SubGroup: Identifiable {
    var id: String { groupName.isEmpty ? "default" : groupName }
    let groupName: String
    let items: [SubItem]
}

struct SubCategorySelectView: View {
    let categoryName: String
    @Binding var path: [AddNavigation]
    @State private var showCustomItem = false

    private var groups: [SubGroup] {
        switch categoryName {
        case "整形":
            return [
                SubGroup(groupName: "目", items: [
                    SubItem(name: "埋没法", templateName: "埋没法", emoji: "👁"),
                    SubItem(name: "逆まつ毛法", templateName: "逆まつ毛法", emoji: "👁"),
                ]),
                SubGroup(groupName: "鼻", items: [
                    SubItem(name: "鼻尖形成・鼻筋通し", templateName: "鼻尖形成・鼻筋通し", emoji: "👃"),
                ]),
                SubGroup(groupName: "注射", items: [
                    SubItem(name: "ボトックス", templateName: "ボトックス", emoji: "💉"),
                    SubItem(name: "ヒアルロン酸", templateName: "ヒアルロン酸", emoji: "💉"),
                    SubItem(name: "脂肪溶解注射", templateName: "脂肪溶解注射", emoji: "💉"),
                ]),
                SubGroup(groupName: "歯科美容", items: [
                    SubItem(name: "ホワイトニング", templateName: "ホワイトニング", emoji: "🦷"),
                ]),
            ]
        case "エステ":
            return [
                SubGroup(groupName: "フェイス・ボディ", items: [
                    SubItem(name: "HIFU（ハイフ）", templateName: "HIFU（ハイフ）", emoji: "✨"),
                    SubItem(name: "フェイシャルエステ", templateName: "フェイシャルエステ", emoji: "💆"),
                    SubItem(name: "痩身エステ", templateName: "痩身エステ", emoji: "🧖"),
                ]),
                SubGroup(groupName: "脱毛", items: [
                    SubItem(name: "脱毛（全身）", templateName: "脱毛（クロ）", emoji: "🦵"),
                    SubItem(name: "脱毛（VIO）", templateName: "脱毛（VIO）", emoji: "🦵"),
                    SubItem(name: "脱毛（顔）", templateName: "脱毛（顔）", emoji: "😊"),
                ]),
            ]
        case "マツエク":
            return [
                SubGroup(groupName: "まつ毛", items: [
                    SubItem(name: "まつ毛エクステ", templateName: "まつ毛エクステ", emoji: "✨"),
                    SubItem(name: "まつ毛パーマ", templateName: "まつ毛パーマ", emoji: "👁"),
                ]),
                SubGroup(groupName: "眉毛", items: [
                    SubItem(name: "眉毛サロン", templateName: "眉毛サロン", emoji: "🪮"),
                ]),
            ]
        case "ヘア":
            return [
                SubGroup(groupName: "カット・スパ", items: [
                    SubItem(name: "カット", templateName: "カット", emoji: "✂️"),
                    SubItem(name: "ヘッドスパ", templateName: "ヘッドスパ", emoji: "💆"),
                ]),
                SubGroup(groupName: "カラー", items: [
                    SubItem(name: "全体カラー", templateName: "全体カラー", emoji: "🎨"),
                    SubItem(name: "リタッチ", templateName: "リタッチ", emoji: "🎨"),
                    SubItem(name: "白髪染め", templateName: "白髪染め", emoji: "🎨"),
                ]),
                SubGroup(groupName: "パーマ", items: [
                    SubItem(name: "パーマ", templateName: "パーマ", emoji: "💇"),
                    SubItem(name: "縮毛矯正", templateName: "縮毛矯正", emoji: "✂️"),
                ]),
            ]
        case "スキンケア":
            return [
                SubGroup(groupName: "保湿・化粧水", items: [
                    SubItem(name: "化粧水", templateName: "化粧水", emoji: "💧"),
                    SubItem(name: "美容液", templateName: "美容液", emoji: "✨"),
                    SubItem(name: "クリーム", templateName: "クリーム", emoji: "🧴"),
                ]),
                SubGroup(groupName: "UV・ベース", items: [
                    SubItem(name: "日焼け止め", templateName: "日焼け止め", emoji: "☀️"),
                    SubItem(name: "ファンデーション", templateName: "ファンデーション", emoji: "💄"),
                ]),
                SubGroup(groupName: "アイケア・その他", items: [
                    SubItem(name: "アイクリーム", templateName: "アイクリーム", emoji: "👁"),
                    SubItem(name: "その他スキンケア", templateName: "その他スキンケア", emoji: "🌿"),
                ]),
            ]
        case "ネイル":
            return [
                SubGroup(groupName: "ジェル・スカルプ", items: [
                    SubItem(name: "ジェルネイル", templateName: "ジェルネイル", emoji: "💅"),
                    SubItem(name: "スカルプ", templateName: "スカルプ", emoji: "💅"),
                    SubItem(name: "ネイルオフ", templateName: "ネイルオフ", emoji: "✨"),
                ]),
            ]
        default:
            return []
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if groups.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.beautySubText)
                        Text("まだ項目がありません")
                            .font(.subheadline)
                            .foregroundStyle(Color.beautySubText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(groups) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            if !group.groupName.isEmpty {
                                Text(group.groupName)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.beautySubText)
                                    .padding(.horizontal, 4)
                            }
                            VStack(spacing: 0) {
                                ForEach(Array(group.items.enumerated()), id: \.element.id) { idx, item in
                                    Button {
                                        path.append(.templateSchedule(
                                            categoryName: categoryName,
                                            templateName: item.templateName
                                        ))
                                    } label: {
                                        HStack(spacing: 12) {
                                            Text(item.emoji)
                                                .font(.title3)
                                            Text(item.name)
                                                .font(.body)
                                                .foregroundStyle(Color.beautyText)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(Color.beautySubText)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(Color.beautyCard)
                                    }
                                    if idx < group.items.count - 1 {
                                        Divider().padding(.leading, 56)
                                    }
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                        }
                    }
                }

                Button {
                    showCustomItem = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.beautyRose)
                        Text("カスタム追加")
                            .font(.body)
                            .foregroundStyle(Color.beautyText)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.beautySubText)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.beautyCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .background(Color.beautyBG)
        .navigationTitle(categoryName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCustomItem) {
            CustomItemSheet(categoryName: categoryName, path: $path)
        }
    }
}
