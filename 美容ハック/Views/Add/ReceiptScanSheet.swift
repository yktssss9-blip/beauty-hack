import SwiftUI
import SwiftData

struct ReceiptScanSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BeautyCategory.sortOrder) var categories: [BeautyCategory]

    @State private var selectedImage: UIImage?
    @State private var isScanning = false
    @State private var result: ParsedReceipt?
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary

    @State private var editTitle = ""
    @State private var editDate = Date()
    @State private var editAmountText = ""
    @State private var editStoreName = ""
    @State private var selectedCategoryId: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if isScanning {
                    scanningView
                } else if result != nil {
                    confirmationForm
                } else {
                    imageSelectorView
                }
            }
            .navigationTitle("レシートを読み込む")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(Color.beautySubText)
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(sourceType: imagePickerSource, selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { _, image in
            guard let image else { return }
            Task {
                isScanning = true
                let scanned = await ReceiptScanner.scan(image: image)
                result = scanned
                editTitle = scanned.title ?? ""
                editDate = scanned.date ?? Date()
                editAmountText = scanned.amount.map { String(Int($0)) } ?? ""
                editStoreName = scanned.storeName ?? ""
                selectedCategoryId = categories.first { $0.name == scanned.detectedCategoryName }?.id
                isScanning = false
            }
        }
    }

    // MARK: - Phase 1: Image selector

    private var imageSelectorView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "doc.viewfinder")
                .font(.system(size: 72))
                .foregroundStyle(Color.beautyRose)
            Text("予約確認やレシートを読み込む")
                .font(.title3.bold())
            Text("スクリーンショットやレシートの写真から\n日付・金額・内容を自動で入力します")
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.beautySubText)
            Spacer()
            VStack(spacing: 12) {
                primaryButton("写真から選ぶ", isEnabled: true) {
                    imagePickerSource = .photoLibrary
                    showImagePicker = true
                }
                secondaryButton("カメラで撮る") {
                    imagePickerSource = .camera
                    showImagePicker = true
                }
            }
            .padding(.bottom, 48)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Phase 2: Scanning

    private var scanningView: some View {
        VStack {
            Spacer()
            ProgressView("スキャン中...")
                .tint(Color.beautyRose)
                .font(.headline)
            Spacer()
        }
    }

    // MARK: - Phase 3: Confirmation form

    private var confirmationForm: some View {
        Form {
            Section {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.skinGreen)
                    Text("スキャン完了 — 内容を確認してください")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.beautyText)
                }
            }
            .listRowBackground(Color.skinGreen.opacity(0.12))

            Section("施術・内容") {
                TextField("タイトル", text: $editTitle)
            }
            Section("日付・時間") {
                DatePicker("", selection: $editDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .tint(Color.beautyRose)
            }
            Section("金額") {
                TextField("例：12000", text: $editAmountText)
                    .keyboardType(.numberPad)
            }
            Section("店舗名（任意）") {
                TextField("サロン名 / クリニック名", text: $editStoreName)
            }
            Section("カテゴリ") {
                Picker("カテゴリ", selection: $selectedCategoryId) {
                    Text("未分類").tag(nil as UUID?)
                    ForEach(categories) { cat in
                        Label(cat.name, systemImage: cat.icon).tag(cat.id as UUID?)
                    }
                }
            }
            Section {
                primaryButton("この内容で登録する", isEnabled: !editTitle.isEmpty) {
                    saveRecord()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
    }

    // MARK: - Button helpers

    private func primaryButton(_ title: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isEnabled ? Color.beautyRose : Color.gray.opacity(0.4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!isEnabled)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.beautyRose, lineWidth: 1.5))
                .foregroundStyle(Color.beautyRose)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Save

    private func saveRecord() {
        let record = BeautyRecord()
        record.title = editTitle
        record.date = editDate
        record.amount = Double(editAmountText)
        record.clinicName = editStoreName.isEmpty ? nil : editStoreName

        if let id = selectedCategoryId {
            record.category = categories.first { $0.id == id }
        }

        modelContext.insert(record)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - UIImagePickerController wrapper

struct ImagePickerView: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView

        init(_ parent: ImagePickerView) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
