import SwiftData
import Foundation

@Model
class BeautyPhoto {
    var id: UUID = UUID()
    @Attribute(.externalStorage)
    var imageData: Data = Data()
    var label: PhotoLabel = PhotoLabel.other
    var takenAt: Date = Date()

    init(imageData: Data, label: PhotoLabel) {
        self.imageData = imageData
        self.label = label
    }
}

enum PhotoLabel: String, Codable {
    case before = "ビフォー"
    case after = "アフター"
    case progress = "経過"
    case other = "その他"
}
