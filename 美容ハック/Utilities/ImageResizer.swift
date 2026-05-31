import UIKit

struct ImageResizer {
    static func resize(_ image: UIImage, maxSize: CGFloat = 1024) -> Data? {
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height)
        guard ratio < 1 else { return image.jpegData(compressionQuality: 0.8) }
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }
}
