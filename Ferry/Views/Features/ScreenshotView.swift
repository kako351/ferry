import SwiftUI

struct ScreenshotPanel: View {
    let device: Device?
    let service: ADBService?
    let serviceErrorMessage: String?
    @State private var viewModel = ScreenshotViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                guard let device else { return }
                guard let service else {
                    viewModel.errorMessage = serviceErrorMessage ?? ADBError.adbNotFound.localizedDescription
                    return
                }
                Task { await viewModel.takeScreenshot(from: device, using: service) }
            } label: {
                Label("保存", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ActionButtonStyle(color: .blue, isDisabled: device == nil || viewModel.isTaking))

            Button {
                guard let device else { return }
                guard let service else {
                    viewModel.errorMessage = serviceErrorMessage ?? ADBError.adbNotFound.localizedDescription
                    return
                }
                Task { await viewModel.takeScreenshotToClipboard(from: device, using: service) }
            } label: {
                Label("クリップボードにコピー", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ActionButtonStyle(color: .orange, isDisabled: device == nil || viewModel.isTaking))

            if viewModel.isTaking {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("撮影中...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
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

            if viewModel.copiedToClipboard {
                Label("クリップボードにコピーしました", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .errorAlert($viewModel.errorMessage)
    }
}
