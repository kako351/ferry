import Foundation

@Observable
final class TextInputViewModel {
    var inputText = ""
    var selectedHistoryId: String?
    var errorMessage: String?
    private(set) var isSending = false

    let repository = TextHistoryRepository()

    func sendText(to device: Device, using service: ADBService) async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isSending = true
        defer { isSending = false }

        do {
            try await service.inputText(text, to: device)
            repository.add(text)
            inputText = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resend(_ text: String, to device: Device, using service: ADBService) async {
        isSending = true
        defer { isSending = false }

        do {
            try await service.inputText(text, to: device)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
