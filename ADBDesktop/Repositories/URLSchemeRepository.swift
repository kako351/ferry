import Foundation

@Observable
final class URLSchemeRepository {
    private(set) var items: [URLScheme] = []
    private let defaults = UserDefaults.standard

    init() {
        load()
    }

    func add(_ scheme: URLScheme) {
        items.append(scheme)
        save()
    }

    func update(_ scheme: URLScheme) {
        guard let index = items.firstIndex(where: { $0.id == scheme.id }) else { return }
        items[index] = scheme
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
        guard let data = defaults.data(forKey: UserDefaults.Keys.urlSchemes),
              let decoded = try? JSONDecoder().decode([URLScheme].self, from: data) else { return }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: UserDefaults.Keys.urlSchemes)
    }
}
