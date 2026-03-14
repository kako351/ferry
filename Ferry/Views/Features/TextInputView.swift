import SwiftUI

struct TextInputPanel: View {
    let device: Device?
    let service: ADBService?
    let serviceErrorMessage: String?
    @State private var viewModel = TextInputViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                TextField("テキストを入力...", text: $viewModel.inputText)
                    .textFieldStyle(.roundedBorder)
                    .font(.body)
                    .onSubmit { send() }

                Button {
                    send()
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(SmallActionButtonStyle(color: .blue, isDisabled: device == nil || viewModel.inputText.isEmpty || viewModel.isSending))
                .keyboardShortcut(.return, modifiers: .command)
            }

            if !viewModel.repository.items.isEmpty {
                Picker(selection: $viewModel.selectedHistoryId) {
                    Text("履歴から選択").tag(String?.none)
                    Divider()
                    ForEach(viewModel.repository.items) { item in
                        Text(item.text).tag(Optional(item.id.uuidString))
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.selectedHistoryId) { _, newValue in
                    if let id = newValue,
                       let uuid = UUID(uuidString: id),
                       let item = viewModel.repository.items.first(where: { $0.id == uuid }) {
                        viewModel.inputText = item.text
                        viewModel.selectedHistoryId = nil
                    }
                }
            }
        }
        .errorAlert($viewModel.errorMessage)
    }

    private func send() {
        guard let device else { return }
        guard let service else {
            viewModel.errorMessage = serviceErrorMessage ?? ADBError.adbNotFound.localizedDescription
            return
        }
        Task { await viewModel.sendText(to: device, using: service) }
    }

    private func resend(_ text: String) {
        guard let device else { return }
        guard let service else {
            viewModel.errorMessage = serviceErrorMessage ?? ADBError.adbNotFound.localizedDescription
            return
        }
        Task { await viewModel.resend(text, to: device, using: service) }
    }
}
