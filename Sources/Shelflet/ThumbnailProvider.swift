import AppKit
import QuickLookThumbnailing

final class ThumbnailProvider {
    func loadThumbnail(for url: URL?, size: CGSize, completion: @escaping (NSImage) -> Void) {
        guard let url else {
            completion(NSImage(named: NSImage.cautionName) ?? NSImage(size: size))
            return
        }

        let fallback = NSWorkspace.shared.icon(forFile: url.path)
        fallback.size = size

        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: NSScreen.screens.first?.backingScaleFactor ?? 2,
            representationTypes: [.thumbnail, .icon]
        )

        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, _ in
            let image: NSImage
            if let representation {
                image = NSImage(cgImage: representation.cgImage, size: size)
            } else {
                image = fallback
            }

            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}
