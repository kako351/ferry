import SwiftUI

struct StatusBadge: View {
    let status: DeviceStatus

    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
            .help(status.label)
    }

    private var statusColor: Color {
        switch status {
        case .device: .green
        case .offline: .red
        case .unauthorized: .orange
        case .unknown: .gray
        }
    }
}
