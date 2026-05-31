import SwiftUI

struct CustomItemSheet: View {
    let categoryName: String
    @Binding var path: [AddNavigation]
    @Environment(\.dismiss) private var dismiss

    @State private var itemName: String = ""
    @State private var enableCycle: Bool = false
    @State private var cycleDays: Int = 30
    @FocusState private var isItemNameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("項目名") {
                    TextField("例：まつ毛エクステ", text: $itemName)
                        .focused($isItemNameFocused)
                }
                Section("次回サイクル（任意）") {
                    Toggle("サイクルを設定する", isOn: $enableCycle)
                    if enableCycle {
                        Stepper("\(cycleDays)日ごと", value: $cycleDays, in: 1...365)
                    }
                }
            }
            .navigationTitle("カスタム項目を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(Color.beautySubText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加する") {
                        path.append(.templateSchedule(
                            categoryName: categoryName,
                            templateName: itemName
                        ))
                        dismiss()
                    }
                    .disabled(itemName.isEmpty)
                }
            }
            .onAppear { isItemNameFocused = true }
        }
    }
}
