import Foundation

@Observable
final class CommandPresetRepository {
    private(set) var items: [CommandPreset] = []
    private let defaults = UserDefaults.standard

    init() {
        load()
    }

    func add(_ preset: CommandPreset) {
        items.append(preset)
        save()
    }

    func update(_ preset: CommandPreset) {
        guard let index = items.firstIndex(where: { $0.id == preset.id }) else { return }
        items[index] = preset
        save()
    }

    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: UserDefaults.Keys.customPresets),
              let decoded = try? JSONDecoder().decode([CommandPreset].self, from: data) else { return }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: UserDefaults.Keys.customPresets)
    }
}
