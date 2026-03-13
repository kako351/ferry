import AppKit
import Foundation

@Observable
final class ScreenshotViewModel {
    var errorMessage: String?
    private(set) var isTaking = false
    private(set) var lastSavedPath: String?
    private(set) var copiedToClipboard = false

    private let saveDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!

    func takeScreenshot(from device: Device, using service: ADBService) async {
        isTaking = true
        defer { isTaking = false }

        do {
            let url = try await service.takeScreenshot(from: device, saveTo: saveDirectory)
            lastSavedPath = url.lastPathComponent
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func takeScreenshotToClipboard(from device: Device, using service: ADBService) async {
        isTaking = true
        copiedToClipboard = false
        defer { isTaking = false }

        do {
            let url = try await service.takeScreenshot(from: device, saveTo: saveDirectory)
            guard let image = NSImage(contentsOf: url) else { return }
            // クリップボードにコピー後、ファイルは削除
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([image])
            try? FileManager.default.removeItem(at: url)
            copiedToClipboard = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
