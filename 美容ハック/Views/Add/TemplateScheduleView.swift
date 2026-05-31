import SwiftUI
import SwiftData

struct ScheduleStep: Identifiable {
    var id = UUID()
    var title: String
    var date: Date
    var reminderDaysBefore: Int  // -1: なし, 0: 当日, N>0: N日前
    var memo: String? = nil
    var reminderType: ReminderType = .onDay
}

struct TemplateScheduleView: View {
    let categoryName: String
    let templateName: String

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var startDate: Date = Date()
    @State private var steps: [ScheduleStep] = []
    @State private var editingStepId: UUID?
    @State private var clinicName: String = ""
    @State private var amountText: String = ""

    private var template: BeautyTemplate? {
        TemplateManager.shared.allTemplates.first { $0.name == templateName }
    }

    private var editingStepBinding: Binding<ScheduleStep>? {
        guard let id = editingStepId,
              let idx = steps.firstIndex(where: { $0.id == id }) else { return nil }
        return $steps[idx]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                startDateCard
                stepsCard
                optionalFieldsCard
                saveButton
                    .padding(.bottom, 8)
            }
            .padding()
        }
        .background(Color.beautyBG)
        .navigationTitle(templateName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadSteps() }
        .onChange(of: startDate) { _, newDate in
            recalculateDates(from: newDate)
        }
        .sheet(isPresented: Binding(
            get: { editingStepId != nil },
            set: { if !$0 { editingStepId = nil } }
        )) {
            if let binding = editingStepBinding {
                StepEditView(step: binding)
            }
        }
    }

    // MARK: - Sub-views

    private var startDateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("開始日時")
                .font(.headline)
            DatePicker("", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .tint(Color.beautyRose)
                .labelsHidden()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.beautyCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("工程")
                    .font(.headline)
                Spacer()
                Button {
                    let newStep = ScheduleStep(
                        title: "追加の工程",
                        date: steps.last?.date ?? startDate,
                        reminderDaysBefore: 1
                    )
                    steps.append(newStep)
                } label: {
                    Label("追加", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.beautyRose)
                }
            }

            if steps.isEmpty {
                Text("工程がありません")
                    .font(.caption)
                    .foregroundStyle(Color.beautySubText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    stepRow(step: step, index: index)
                    if index < steps.count - 1 {
                        Divider().padding(.leading, 8)
                    }
                }
            }
        }
        .padding()
        .background(Color.beautyCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func stepRow(step: ScheduleStep, index: Int) -> some View {
        HStack(spacing: 10) {
            Button {
                editingStepId = step.id
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.beautyRose.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(Color.beautyRose)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(step.title)
                        .font(.body.bold())
                        .foregroundStyle(Color.beautyText)
                    Text(step.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(Color.beautySubText)
                    if step.reminderDaysBefore >= 0 {
                        Text(reminderLabel(step.reminderDaysBefore))
                            .font(.caption2)
                            .foregroundStyle(Color.beautyRose)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                withAnimation { steps = steps.filter { $0.id != step.id } }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(Color.beautyAlertRed.opacity(0.75))
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private var optionalFieldsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("詳細（任意）")
                .font(.headline)

            HStack {
                Image(systemName: "building.2")
                    .foregroundStyle(Color.beautySubText)
                    .frame(width: 20)
                TextField("クリニック名 / サロン名", text: $clinicName)
            }
            .padding(10)
            .background(Color.beautyBG)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack {
                Image(systemName: "yensign.circle")
                    .foregroundStyle(Color.beautySubText)
                    .frame(width: 20)
                TextField("金額（円）", text: $amountText)
                    .keyboardType(.numberPad)
            }
            .padding(10)
            .background(Color.beautyBG)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(Color.beautyCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var saveButton: some View {
        Button { saveRecords() } label: {
            Text("このスケジュールで登録する")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(steps.isEmpty ? Color.gray.opacity(0.4) : Color.beautyRose)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(steps.isEmpty)
    }

    // MARK: - Helpers

    private func reminderLabel(_ days: Int) -> String {
        switch days {
        case 0: return "当日通知"
        case 1: return "1日前に通知"
        case 7: return "1週間前に通知"
        default: return "\(days)日前に通知"
        }
    }

    private func loadSteps() {
        if let tmpl = template {
            steps = tmpl.steps.map { step in
                let date = Calendar.current.date(byAdding: .day, value: step.offsetDays, to: startDate) ?? startDate
                return ScheduleStep(
                    title: step.title,
                    date: date,
                    reminderDaysBefore: step.reminderDaysBefore,
                    reminderType: step.reminderType
                )
            }
        } else {
            steps = [ScheduleStep(title: templateName.isEmpty ? "記録" : templateName, date: startDate, reminderDaysBefore: 1)]
        }
    }

    private func recalculateDates(from newDate: Date) {
        if let tmpl = template {
            for (i, templateStep) in tmpl.steps.enumerated() where i < steps.count {
                steps[i].date = Calendar.current.date(byAdding: .day, value: templateStep.offsetDays, to: newDate) ?? newDate
            }
        } else if !steps.isEmpty {
            steps[0].date = newDate
        }
    }

    private func saveRecords() {
        let descriptor = FetchDescriptor<BeautyCategory>(
            predicate: #Predicate { $0.name == categoryName }
        )
        let category = (try? modelContext.fetch(descriptor))?.first
        let parsedAmount = Double(amountText)

        var parentRecord: BeautyRecord?

        for (index, step) in steps.enumerated() {
            let record = BeautyRecord()
            record.title = step.title
            record.date = step.date
            record.nextDate = step.date
            record.templateName = template?.name
            record.stepIndex = index
            record.totalSteps = steps.count
            record.category = category

            record.isAftercare = step.reminderType == .aftercare

            if index == 0 {
                parentRecord = record
                record.amount = parsedAmount
                record.clinicName = clinicName.isEmpty ? nil : clinicName
            } else {
                record.parentRecordId = parentRecord?.id
            }

            if step.reminderDaysBefore >= 0 {
                let offsetDays = -step.reminderDaysBefore
                let notifyBase = Calendar.current.date(
                    byAdding: .day, value: offsetDays, to: step.date
                ) ?? step.date
                let notifyTime = Calendar.current.date(
                    bySettingHour: 9, minute: 0, second: 0, of: notifyBase
                ) ?? notifyBase
                let reminder = BeautyReminder(
                    type: step.reminderDaysBefore == 0 ? .onDay : .beforeDays,
                    daysBefore: step.reminderDaysBefore,
                    notifyTime: notifyTime
                )
                record.reminders.append(reminder)
            }

            modelContext.insert(record)
            NotificationManager.shared.scheduleNotifications(for: record)
        }

        // Set nextDate / cycleDays on parent for recurring templates
        if let tmpl = template, let cycleDays = tmpl.nextCycleDays, let lastStep = steps.last {
            parentRecord?.nextDate = Calendar.current.date(
                byAdding: .day, value: cycleDays, to: lastStep.date
            )
            parentRecord?.cycleDays = cycleDays
        }

        try? modelContext.save()
        dismiss()
    }
}
