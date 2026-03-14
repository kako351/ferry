import Foundation

@Observable
final class URLSchemeViewModel {
    var errorMessage: String?
    private(set) var isSending = false
    var placeholderValues: [String: String] = [:]

    let repository = URLSchemeRepository()

    var isAddingNew = false
    var editingScheme: URLScheme?
    var editLabel = ""
    var editURL = ""

    func sendURL(_ scheme: URLScheme, to device: Device, using service: ADBService) async {
        let url = scheme.buildURL(with: placeholderValues)
        guard !url.isEmpty else { return }

        isSending = true
        defer { isSending = false }

        do {
            try await service.openURL(url, on: device)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startAdding() {
        editLabel = ""
        editURL = ""
        isAddingNew = true
    }

    func startEditing(_ scheme: URLScheme) {
        editLabel = scheme.label
        editURL = scheme.urlTemplate
        editingScheme = scheme
    }

    func saveNew() {
        guard !editLabel.isEmpty, !editURL.isEmpty else { return }
        let scheme = URLScheme(label: editLabel, urlTemplate: editURL)
        repository.add(scheme)
        isAddingNew = false
    }

    func saveEdit() {
        guard var scheme = editingScheme, !editLabel.isEmpty, !editURL.isEmpty else { return }
        scheme.label = editLabel
        scheme.urlTemplate = editURL
        repository.update(scheme)
        editingScheme = nil
    }

    func cancelEdit() {
        isAddingNew = false
        editingScheme = nil
    }
}
