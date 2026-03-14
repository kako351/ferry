import SwiftUI

struct WiFiConnectionPanel: View {
    let device: Device?
    let service: ADBService?
    let serviceErrorMessage: String?
    @State private var viewModel = WiFiConnectionViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: viewModel.isWiFiConnected ? "wifi" : "cable.connector")
                    .font(.body)
                    .foregroundStyle(viewModel.isWiFiConnected ? Color.green : Color.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.isWiFiConnected ? "Wi-Fi接続中" : "USB接続中")
                        .font(.body)
                        .fontWeight(.medium)
                    if let ip = viewModel.deviceIP {
                        Text(ip)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .textSelection(.enabled)
                    }
                }
            }

            if viewModel.isWiFiConnected {
                Button {
                    guard let device else { return }
                    guard let service else {
                        viewModel.errorMessage = serviceErrorMessage ?? ADBError.adbNotFound.localizedDescription
                        return
                    }
                    Task { await viewModel.disconnect(device: device, using: service) }
                } label: {
                    Label("切断", systemImage: "wifi.slash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ActionButtonStyle(color: .red, isDisabled: device == nil || viewModel.isConnecting))
            } else {
                Button {
                    guard let device else { return }
                    guard let service else {
                        viewModel.errorMessage = serviceErrorMessage ?? ADBError.adbNotFound.localizedDescription
                        return
                    }
                    Task { await viewModel.connectViaWiFi(device: device, using: service) }
                } label: {
                    Label("Wi-Fiに切り替え", systemImage: "wifi")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ActionButtonStyle(color: .blue, isDisabled: device == nil || viewModel.isConnecting))
            }

            if viewModel.isConnecting {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("接続中...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .errorAlert($viewModel.errorMessage)
        .task(id: device?.id) {
            guard let device, let service else { return }
            await viewModel.fetchDeviceIP(device: device, using: service)
        }
    }
}
