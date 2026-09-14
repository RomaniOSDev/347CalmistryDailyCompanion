import UIKit

enum PhotoDisk {
    private static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func save(_ data: Data) -> String? {
        let fileName = "photo-\(UUID().uuidString).jpg"
        guard let url = resolvedURL(for: fileName) else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return fileName
        } catch {
            return nil
        }
    }

    static func load(_ fileName: String) -> UIImage? {
        guard let url = resolvedURL(for: fileName) else { return nil }
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    static func delete(_ fileName: String) {
        guard let url = resolvedURL(for: fileName) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    static func jpegData(from image: UIImage, quality: CGFloat = 0.82) -> Data? {
        image.jpegData(compressionQuality: quality)
    }

    private static func resolvedURL(for fileName: String) -> URL? {
        let trimmed = (fileName as NSString).lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != ".", trimmed != ".." else { return nil }
        return documentsURL.appendingPathComponent(trimmed)
    }
}
