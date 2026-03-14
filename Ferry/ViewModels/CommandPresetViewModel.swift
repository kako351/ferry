import Foundation

@Observable
final class CommandPresetViewModel {
    var errorMessage: String?
    private(set) var isExecuting = false
    private(set) var lastOutput: String?

    let appLaunchRepository = AppLaunchRepository()
    let presetRepository = CommandPresetRepository()

    // 編集用
    var isAddingApp = false
    var isAddingPreset = false
    var editingApp: AppLaunchEntry?
    var editingPreset: CommandPreset?
    var editLabel = ""
    var editPackage = ""
    var editActivity = ""
    var editCommand = ""

    func launchApp(_ entry: AppLaunchEntry, on device: Device, using service: ADBService) async {
        isExecuting = true
        defer { isExecuting = false }

        do {
            let activity: String? = entry.activityName.isEmpty ? nil : entry.activityName
            try await service.launchApp(package: entry.packageName, activity: activity, on: device)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func executePreset(_ preset: CommandPreset, on device: Device, using service: ADBService) async {
        isExecuting = true
        defer { isExecuting = false }

        do {
            let args = preset.command.split(separator: " ").map(String.init)
            lastOutput = try await service.execute(arguments: args, on: device)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - アプリ起動エントリー編集

    func startAddingApp() {
        editLabel = ""
        editPackage = ""
        editActivity = ""
        isAddingApp = true
    }

    func startEditingApp(_ entry: AppLaunchEntry) {
        editLabel = entry.label
        editPackage = entry.packageName
        editActivity = entry.activityName
        editingApp = entry
    }

    func saveApp() {
        guard !editLabel.isEmpty, !editPackage.isEmpty else { return }

        if var entry = editingApp {
            entry.label = editLabel
            entry.packageName = editPackage
            entry.activityName = editActivity
            appLaunchRepository.update(entry)
            editingApp = nil
        } else {
            let entry = AppLaunchEntry(label: editLabel, packageName: editPackage, activityName: editActivity)
            appLaunchRepository.add(entry)
            isAddingApp = false
        }
    }

    func cancelAppEdit() {
        isAddingApp = false
        editingApp = nil
    }

    // MARK: - カスタムプリセット編集

    func startAddingPreset() {
        editLabel = ""
        editCommand = ""
        isAddingPreset = true
    }

    func startEditingPreset(_ preset: CommandPreset) {
        editLabel = preset.label
        editCommand = preset.command
        editingPreset = preset
    }

    func savePreset() {
        guard !editLabel.isEmpty, !editCommand.isEmpty else { return }

        if var preset = editingPreset {
            preset.label = editLabel
            preset.command = editCommand
            presetRepository.update(preset)
            editingPreset = nil
        } else {
            let preset = CommandPreset(label: editLabel, command: editCommand)
            presetRepository.add(preset)
            isAddingPreset = false
        }
    }

    func cancelPresetEdit() {
        isAddingPreset = false
        editingPreset = nil
    }
}
