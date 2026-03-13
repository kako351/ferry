import Foundation

@Observable
final class ScreenRecordViewModel {
    var errorMessage: String?
    private(set) var isRecording = false
    private(set) var lastSavedPath: String?
    private(set) var elapsedSeconds: Int = 0
    private var timer: Timer?

    private let saveDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!

    func startRecording(on device: Device, using service: ADBService) async {
        do {
            try await service.startRecording(on: device)
            isRecording = true
            elapsedSeconds = 0
            startTimer()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopRecording(on device: Device, using service: ADBService) async {
        stopTimer()

        do {
            let url = try await service.stopRecording(on: device, saveTo: saveDirectory)
            lastSavedPath = url.lastPathComponent
            isRecording = false
        } catch {
            isRecording = false
            errorMessage = error.localizedDescription
        }
    }

    var formattedElapsedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
