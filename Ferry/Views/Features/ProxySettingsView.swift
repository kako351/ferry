import SwiftUI

struct ProxySettingsPanel: View {
    let device: Device?
    let service: ADBService?
    let serviceErrorMessage: String?
    @State private var viewModel = ProxyViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: viewModel.isProxyEnabled ? "network.badge.shield.half.filled" : "network.slash")
                    .font(.body)
                    .foregroundStyle(viewModel.isProxyEnabled ? Color.green : Color.secondary)
                Text(viewModel.isProxyEnabled ? "オン" : "オフ")
                    .font(.body)
                    .fontWeight(.medium)
                if let proxy = viewModel.currentProxy {
                    Text(proxy)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Text("ホスト:")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                    Text(viewModel.localIP ?? "不明")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(viewModel.localIP != nil ? Color.primary : Color.red)
                }

                HStack(spacing: 6) {
                    Text("ポート:")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                    TextField("", text: $viewModel.port)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 64)
                        .font(.subheadline)
                }
            }

            if viewModel.isProxyEnabled {
                Button {
                    guard let device else { return }
                    guard let service else {
                        viewModel.errorMessage = serviceErrorMessage ?? ADBError.adbNotFound.localizedDescription
                        return
                    }
                    Task { await viewModel.disableProxy(device: device, using: service) }
                } label: {
                    Label("オフにする", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ActionButtonStyle(color: .red, isDisabled: viewModel.isToggling))
            } else {
                Button {
                    guard let device else { return }
                    guard let service else {
                        viewModel.errorMessage = serviceErrorMessage ?? ADBError.adbNotFound.localizedDescription
                        return
                    }
                    Task { await viewModel.enableProxy(device: device, using: service) }
                } label: {
                    Label("オンにする", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ActionButtonStyle(color: .blue, isDisabled: viewModel.isToggling))
            }

            if viewModel.isToggling {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("切り替え中...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .errorAlert($viewModel.errorMessage)
        .task(id: device?.id) {
            guard let device, let service else { return }
            await viewModel.fetchStatus(device: device, using: service)
        }
    }
}
