import Foundation

struct Device: Identifiable, Equatable, Hashable {
    let id: String
    let serialNumber: String
    let status: DeviceStatus
    var displayName: String

    init(serialNumber: String, status: DeviceStatus, displayName: String? = nil) {
        self.id = serialNumber
        self.serialNumber = serialNumber
        self.status = status
        self.displayName = displayName ?? serialNumber
    }
}

enum DeviceStatus: String {
    case device = "device"
    case offline = "offline"
    case unauthorized = "unauthorized"
    case unknown = "unknown"

    var label: String {
        switch self {
        case .device: "接続中"
        case .offline: "オフライン"
        case .unauthorized: "未認証"
        case .unknown: "不明"
        }
    }

    var color: String {
        switch self {
        case .device: "green"
        case .offline: "red"
        case .unauthorized: "orange"
        case .unknown: "gray"
        }
    }
}
