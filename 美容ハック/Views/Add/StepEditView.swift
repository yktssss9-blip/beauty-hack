import SwiftUI

struct StepEditView: View {
    @Binding var step: ScheduleStep
    @Environment(\.dismiss) private var dismiss
    @State private var reminderEnabled: Bool

    init(step: Binding<ScheduleStep>) {
        self._step = step
        self._reminderEnabled = State(initialValue: step.wrappedValue.reminderDaysBefore >= 0)
    }

    private let reminderChoices: [(label: String, days: Int)] = [
        ("なし", -1),
        ("当日", 0),
        ("1日前", 1),
        ("2日前", 2),
        ("3日前", 3),
        ("1週間前", 7),
    ]

    var body: some View {
        NavigationStack {
            Form(content: {
                Section("工程名") {
                    TextField("タイトル", text: $step.title)
                }

                Section("日付・時間") {
                    DatePicker(
                        "日付・時間",
                        selection: $step.date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .tint(Color.beautyRose)
                }

                Section("リマインド") {
                    Toggle("リマインドを設定する", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, newValue in
                            if newValue {
                                step.reminderDaysBefore = 1
                            } else {
                                step.reminderDaysBefore = -1
                            }
                        }
                    if reminderEnabled {
                        Picker("通知タイミング", selection: $step.reminderDaysBefore) {
                            ForEach(reminderChoices, id: \.days) { choice in
                                Text(choice.label).tag(choice.days)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                }

                Section("メモ（任意）") {
                    TextField(
                        "メモ",
                        text: Binding(
                            get: { step.memo ?? "" },
                            set: { step.memo = $0.isEmpty ? nil : $0 }
                        ),
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }
            })
            .navigationTitle("工程を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                        .foregroundStyle(Color.beautyRose)
                }
            }
        }
    }
}
