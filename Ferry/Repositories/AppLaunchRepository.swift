import Foundation

@Observable
final class AppLaunchRepository {
    private(set) var items: [AppLaunchEntry] = []
    private let defaults = UserDefaults.standard

    init() {
        load()
    }

    func add(_ entry: AppLaunchEntry) {
        items.append(entry)
        save()
    }

    func update(_ entry: AppLaunchEntry) {
        guard let index = items.firstIndex(where: { $0.id == entry.id }) else { return }
        items[index] = entry
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
        guard let data = defaults.data(forKey: UserDefaults.Keys.appLaunchEntries),
              let decoded = try? JSONDecoder().decode([AppLaunchEntry].self, from: data) else { return }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: UserDefaults.Keys.appLaunchEntries)
    }
}
