import Foundation

struct AppLaunchEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var label: String
    var packageName: String
    var activityName: String

    init(id: UUID = UUID(), label: String, packageName: String, activityName: String) {
        self.id = id
        self.label = label
        self.packageName = packageName
        self.activityName = activityName
    }

    var fullComponentName: String {
        activityName.isEmpty ? packageName : "\(packageName)/\(activityName)"
    }
}
