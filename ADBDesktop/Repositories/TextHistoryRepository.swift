import Foundation

@Observable
final class TextHistoryRepository {
    private(set) var items: [TextHistory] = []
    private let defaults = UserDefaults.standard

    init() {
        load()
    }

    func add(_ text: String) {
        // 重複チェック
        if items.contains(where: { $0.text == text }) { return }
        let entry = TextHistory(text: text)
        items.insert(entry, at: 0)
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

    func removeAll() {
        items.removeAll()
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: UserDefaults.Keys.textHistory),
              let decoded = try? JSONDecoder().decode([TextHistory].self, from: data) else { return }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: UserDefaults.Keys.textHistory)
    }
}
