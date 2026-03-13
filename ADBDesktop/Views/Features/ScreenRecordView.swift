import SwiftUI

struct ScreenRecordPanel: View {
    let device: Device?
    @State private var viewModel = ScreenRecordViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.isRecording {
                HStack(spacing: 10) {
                    Circle()
                        .fill(.red)
                        .frame(width: 10, height: 10)
                    Text(viewModel.formattedElapsedTime)
                        .font(.system(.title3, design: .monospaced))
                        .foregroundStyle(.red)
                }

                Button {
                    guard let device, let service = try? ADBService() else { return }
                    Task { await viewModel.stopRecording(on: device, using: service) }
                } label: {
                    Label("停止", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ActionButtonStyle(color: .red, isDisabled: false))
            } else {
                Button {
                    guard let device, let service = try? ADBService() else { return }
                    Task { await viewModel.startRecording(on: device, using: service) }
                } label: {
                    Label("録画開始", systemImage: "record.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ActionButtonStyle(color: .blue, isDisabled: device == nil))
            }

            HStack {
                Text("保存先")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text("~/Downloads/")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            if let lastPath = viewModel.lastSavedPath {
                HStack {
                    Text("最新")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(lastPath)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .errorAlert($viewModel.errorMessage)
    }
}
