import Foundation

struct URLScheme: Identifiable, Codable, Equatable {
    let id: UUID
    var label: String
    var urlTemplate: String

    init(id: UUID = UUID(), label: String, urlTemplate: String) {
        self.id = id
        self.label = label
        self.urlTemplate = urlTemplate
    }

    var placeholders: [String] {
        guard let regex = try? NSRegularExpression(pattern: "\\{([^}]+)\\}") else { return [] }
        let range = NSRange(urlTemplate.startIndex..., in: urlTemplate)
        return regex.matches(in: urlTemplate, range: range).compactMap { match in
            guard let range = Range(match.range(at: 1), in: urlTemplate) else { return nil }
            return String(urlTemplate[range])
        }
    }

    func buildURL(with values: [String: String]) -> String {
        var result = urlTemplate
        for (key, value) in values {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return result
    }
}
