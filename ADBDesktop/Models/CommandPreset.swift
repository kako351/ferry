import Foundation

struct CommandPreset: Identifiable, Codable, Equatable {
    let id: UUID
    var label: String
    var command: String
    var isBuiltIn: Bool

    init(id: UUID = UUID(), label: String, command: String, isBuiltIn: Bool = false) {
        self.id = id
        self.label = label
        self.command = command
        self.isBuiltIn = isBuiltIn
    }
}
