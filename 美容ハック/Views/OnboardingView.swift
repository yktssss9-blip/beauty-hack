import SwiftUI
import SwiftData

private enum CycleOption: String, CaseIterable, Identifiable {
    case oneDay    = "1日使い捨て"
    case twoWeeks  = "2週間"
    case oneMonth  = "1ヶ月"
    case custom    = "カスタム"

    var id: String { rawValue }

    var days: Int? {
        switch self {
        case .oneDay:   return 1
        case .twoWeeks: return 14
        case .oneMonth: return 30
        case .custom:   return nil
        }
    }
}

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @Environment(\.modelContext) private var modelContext

    @State private var page = 0

    // Page 2
    @State private var selectedCycle: CycleOption = .oneMonth
    @State private var customDays: Int = 30

    // Page 2 (amount)
    @State private var contactAmountText: String = ""

    // Page 3
    @State private var amountText: String = ""
    @State private var isApproximate = false
    @State private var lastExchangeDate: Date = Date()
    @State private var daysAgoSlider: Double = 0

    private var effectiveCycleDays: Int {
        selectedCycle.days ?? customDays
    }

    private var nextExchangeDate: Date {
        Calendar.current.date(
            byAdding: .day, value: effectiveCycleDays, to: lastExchangeDate
        ) ?? lastExchangeDate
    }

    private var sliderRange: ClosedRange<Double> {
        0...Double(max(effectiveCycleDays, 1))
    }

    var body: some View {
        ZStack {
            Color.beautyBG.ignoresSafeArea()
            pageContent
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal:   .move(edge: .leading)
                ))
                .id(page)
        }
        .animation(.easeInOut(duration: 0.3), value: page)
    }

    @ViewBuilder
    private var pageContent: some View {
        switch page {
        case 0: welcomePage
        case 1: cyclePage
        case 2: datePage
        case 3: resultPage
        default: completePage
        }
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "eye.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.contactBlue)
                .padding(.bottom, 28)
            Text("美容ハックへようこそ")
                .font(.largeTitle.bold())
                .padding(.bottom, 12)
            Text("カラコン・美容施術のスケジュールを\nかんたんに管理しましょう")
                .font(.body)
                .foregroundStyle(Color.beautySubText)
                .multilineTextAlignment(.center)
            Spacer()
            primaryButton("はじめる") { page = 1 }
                .padding(.bottom, 48)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Page 2: Cycle

    private var cyclePage: some View {
        VStack(spacing: 0) {
            pageIndicator(current: 1, total: 4)
            Spacer()
            Text("交換サイクルを選んでください")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.bottom, 6)
            Text("カラコンの交換頻度を教えてください")
                .font(.subheadline)
                .foregroundStyle(Color.beautySubText)
                .padding(.bottom, 28)

            VStack(spacing: 10) {
                ForEach(CycleOption.allCases) { option in
                    cycleOptionRow(option)
                }
                if selectedCycle == .custom {
                    customDaysStepper
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedCycle)

            amountField
                .padding(.top, 8)

            Spacer()
            primaryButton("次へ") { page = 2 }
                .padding(.bottom, 48)
        }
        .padding(.horizontal, 24)
    }

    private func cycleOptionRow(_ option: CycleOption) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCycle = option
            }
        } label: {
            HStack {
                Text(option.rawValue)
                    .font(.body.bold())
                    .foregroundStyle(Color.beautyText)
                Spacer()
                Image(systemName: selectedCycle == option
                      ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedCycle == option
                                     ? Color.beautyRose : Color.beautySubText)
                    .font(.title3)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedCycle == option
                          ? Color.beautyRose.opacity(0.08) : Color.beautyCard)
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedCycle == option
                            ? Color.beautyRose : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var amountField: some View {
        HStack(spacing: 10) {
            Image(systemName: "yensign.circle")
                .foregroundStyle(Color.beautySubText)
                .frame(width: 20)
            TextField("1枚あたりの金額（任意）", text: $contactAmountText)
                .keyboardType(.numberPad)
                .font(.body)
            if !contactAmountText.isEmpty {
                Text("円")
                    .font(.body)
                    .foregroundStyle(Color.beautySubText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.beautyCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var customDaysStepper: some View {
        HStack {
            Text("日数")
                .font(.body)
                .foregroundStyle(Color.beautyText)
            Spacer()
            Stepper("\(customDays) 日", value: $customDays, in: 1...365)
                .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.beautyCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Page 3: Date

    private var datePage: some View {
        VStack(spacing: 0) {
            pageIndicator(current: 2, total: 4)
            Spacer()
            Text("前回の交換日は？")
                .font(.title2.bold())
                .padding(.bottom, 6)
            Text("最後にカラコンを交換した日を教えてください")
                .font(.subheadline)
                .foregroundStyle(Color.beautySubText)
                .multilineTextAlignment(.center)
                .padding(.bottom, 24)

            Picker("", selection: $isApproximate) {
                Text("正確な日付").tag(false)
                Text("だいたい").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 20)

            if isApproximate {
                approximateDateSection
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                DatePicker(
                    "",
                    selection: $lastExchangeDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(Color.beautyRose)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer()
            HStack(spacing: 10) {
                Image(systemName: "yensign.circle")
                    .foregroundStyle(Color.beautySubText)
                    .frame(width: 20)
                TextField("金額（円）", text: $amountText)
                    .keyboardType(.numberPad)
            }
            .padding(10)
            .background(Color.beautyBG)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.bottom, 12)

            primaryButton("次へ") { page = 3 }
                .padding(.bottom, 48)
        }
        .padding(.horizontal, 24)
        .animation(.easeInOut(duration: 0.2), value: isApproximate)
    }

    private var approximateDateSection: some View {
        VStack(spacing: 12) {
            Text("だいたい \(Int(daysAgoSlider)) 日前")
                .font(.title3.bold())
                .foregroundStyle(Color.beautyText)
            Slider(value: $daysAgoSlider, in: sliderRange, step: 1)
                .tint(Color.beautyRose)
                .onChange(of: daysAgoSlider) { _, val in
                    lastExchangeDate = Calendar.current.date(
                        byAdding: .day, value: -Int(val), to: Date()
                    ) ?? Date()
                }
            Text("だいたいの日付")
                .font(.caption)
                .foregroundStyle(Color.beautySubText)
        }
        .padding()
        .background(Color.beautyCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Page 4: Result + notification

    private var resultPage: some View {
        VStack(spacing: 0) {
            pageIndicator(current: 3, total: 4)
            Spacer()
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 56))
                .foregroundStyle(Color.beautyRose)
                .padding(.bottom, 20)

            Text("✨ 次回交換日は")
                .font(.title3)
                .foregroundStyle(Color.beautySubText)
            Text(nextExchangeDate, format: .dateTime.month().day())
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundStyle(Color.beautyRose)
                .padding(.vertical, 4)
            Text("です")
                .font(.title3)
                .foregroundStyle(Color.beautySubText)
                .padding(.bottom, 24)

            Text("通知を受け取って、交換し忘れを防ぎましょう")
                .font(.subheadline)
                .foregroundStyle(Color.beautySubText)
                .multilineTextAlignment(.center)

            Spacer()

            primaryButton("通知を許可して続ける") {
                Task {
                    await NotificationManager.shared.requestPermission()
                    page = 4
                }
            }
            .padding(.bottom, 12)

            Button {
                page = 4
            } label: {
                Text("後で設定する")
                    .font(.subheadline)
                    .foregroundStyle(Color.beautySubText)
            }
            .padding(.bottom, 48)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Page 5: Complete

    private var completePage: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.skinGreen)
                .padding(.bottom, 28)
            Text("セットアップ完了！")
                .font(.largeTitle.bold())
                .padding(.bottom, 12)
            Text("美容ハックで\n美容ライフを管理しましょう✨")
                .font(.body)
                .foregroundStyle(Color.beautySubText)
                .multilineTextAlignment(.center)
            Spacer()
            primaryButton("アプリを始める") {
                saveOnboardingData()
                hasCompletedOnboarding = true
            }
            .padding(.bottom, 48)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Shared components

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.beautyRose)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func pageIndicator(current: Int, total: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(1...total, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Color.beautyRose : Color.beautySubText.opacity(0.3))
                    .frame(width: i == current ? 20 : 6, height: 6)
                    .animation(.easeInOut, value: current)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Save

    private func saveOnboardingData() {
        let descriptor = FetchDescriptor<BeautyCategory>(
            predicate: #Predicate { $0.name == "カラコン" }
        )
        let category = (try? modelContext.fetch(descriptor))?.first

        let record = BeautyRecord()
        record.title = "カラコン交換日"
        record.date = lastExchangeDate
        record.cycleDays = effectiveCycleDays
        record.nextDate = nextExchangeDate
        record.contactCycleDays = effectiveCycleDays
        record.contactStartDate = lastExchangeDate
        record.contactIsApproximate = isApproximate
        record.amount = Double(amountText)
        record.category = category

        let notifyBase = Calendar.current.date(
            byAdding: .day, value: -1, to: nextExchangeDate
        ) ?? nextExchangeDate
        let notifyTime = Calendar.current.date(
            bySettingHour: 9, minute: 0, second: 0, of: notifyBase
        ) ?? notifyBase
        let reminder = BeautyReminder(
            type: .beforeDays,
            daysBefore: 1,
            notifyTime: notifyTime
        )
        record.reminders.append(reminder)
        modelContext.insert(record)
        try? modelContext.save()
        NotificationManager.shared.scheduleNotifications(for: record)
    }
}
