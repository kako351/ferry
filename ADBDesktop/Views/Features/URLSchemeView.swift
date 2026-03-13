import SwiftUI

struct URLSchemePanel: View {
    let device: Device?
    @State private var viewModel = URLSchemeViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if viewModel.repository.items.isEmpty {
                HStack {
                    Text("URLスキームが登録されていません")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    addButton
                }
            } else {
                HStack {
                    Spacer()
                    addButton
                }

                ForEach(viewModel.repository.items) { scheme in
                    schemeRow(scheme)
                }
            }
        }
        .errorAlert($viewModel.errorMessage)
        .sheet(isPresented: $viewModel.isAddingNew) {
            schemeEditSheet(isNew: true)
        }
        .sheet(isPresented: .init(
            get: { viewModel.editingScheme != nil },
            set: { if !$0 { viewModel.cancelEdit() } }
        )) {
            schemeEditSheet(isNew: false)
        }
    }

    private var addButton: some View {
        Button {
            viewModel.startAdding()
        } label: {
            Label("追加", systemImage: "plus")
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
    }

    private func schemeRow(_ scheme: URLScheme) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(scheme.label)
                    .font(.body)
                    .fontWeight(.medium)

                Text(scheme.urlTemplate)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)

                Spacer()

                Button { viewModel.startEditing(scheme) } label: {
                    Image(systemName: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Button {
                    withAnimation { viewModel.repository.remove(id: scheme.id) }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                ForEach(scheme.placeholders, id: \.self) { placeholder in
                    TextField(placeholder, text: Binding(
                        get: { viewModel.placeholderValues[placeholder] ?? "" },
                        set: { viewModel.placeholderValues[placeholder] = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.body)
                    .frame(maxWidth: 160)
                }

                Spacer()

                Button {
                    guard let device, let service = try? ADBService() else { return }
                    Task { await viewModel.sendURL(scheme, to: device, using: service) }
                } label: {
                    Label("送信", systemImage: "paperplane.fill")
                }
                .buttonStyle(SmallActionButtonStyle(color: .blue, isDisabled: device == nil))
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func schemeEditSheet(isNew: Bool) -> some View {
        VStack(spacing: 20) {
            Text(isNew ? "URLスキームを追加" : "URLスキームを編集")
                .font(.title3)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ラベル").font(.body).foregroundStyle(.secondary)
                    TextField("例: 商品詳細", text: $viewModel.editLabel)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("URL").font(.body).foregroundStyle(.secondary)
                    TextField("例: myapp://product/{id}", text: $viewModel.editURL)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                    Text("{} で囲んだ部分がプレースホルダーになります")
                        .font(.subheadline).foregroundStyle(.tertiary)
                }
            }

            HStack {
                Button("キャンセル") { viewModel.cancelEdit() }
                    .controlSize(.large)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(isNew ? "追加" : "保存") {
                    if isNew { viewModel.saveNew() } else { viewModel.saveEdit() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.editLabel.isEmpty || viewModel.editURL.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 440)
    }
}
