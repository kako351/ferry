import SwiftUI

struct CommandPresetPanel: View {
    let device: Device?
    @State private var viewModel = CommandPresetViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // アプリ起動
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("アプリ起動")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)
                    Spacer()
                    Button {
                        viewModel.startAddingApp()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }

                if viewModel.appLaunchRepository.items.isEmpty {
                    Text("アプリが登録されていません")
                        .font(.subheadline)
                        .foregroundStyle(.quaternary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(viewModel.appLaunchRepository.items) { entry in
                        HStack(spacing: 10) {
                            Image(systemName: "app")
                                .font(.subheadline)
                                .foregroundStyle(.blue)

                            Text(entry.label)
                                .font(.body)
                                .fontWeight(.medium)

                            Text(entry.fullComponentName)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.quaternary)
                                .lineLimit(1)

                            Spacer()

                            Button {
                                guard let device, let service = try? ADBService() else { return }
                                Task { await viewModel.launchApp(entry, on: device, using: service) }
                            } label: {
                                Image(systemName: "play.fill")
                            }
                            .buttonStyle(SmallActionButtonStyle(color: .blue, isDisabled: device == nil || viewModel.isExecuting))

                            Menu {
                                Button("編集") { viewModel.startEditingApp(entry) }
                                Divider()
                                Button("削除", role: .destructive) {
                                    withAnimation { viewModel.appLaunchRepository.remove(id: entry.id) }
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundStyle(.tertiary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }

            Divider()

            // カスタムコマンド
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("カスタムコマンド")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)
                    Spacer()
                    Button {
                        viewModel.startAddingPreset()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }

                if viewModel.presetRepository.items.isEmpty {
                    Text("カスタムコマンドが登録されていません")
                        .font(.subheadline)
                        .foregroundStyle(.quaternary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(viewModel.presetRepository.items) { preset in
                        HStack(spacing: 10) {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .font(.caption)
                                .foregroundStyle(.orange)

                            Text(preset.label)
                                .font(.body)
                                .fontWeight(.medium)

                            Text("adb \(preset.command)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.quaternary)
                                .lineLimit(1)

                            Spacer()

                            Button {
                                guard let device, let service = try? ADBService() else { return }
                                Task { await viewModel.executePreset(preset, on: device, using: service) }
                            } label: {
                                Image(systemName: "play.fill")
                            }
                            .buttonStyle(SmallActionButtonStyle(color: .blue, isDisabled: device == nil || viewModel.isExecuting))

                            Menu {
                                Button("編集") { viewModel.startEditingPreset(preset) }
                                Divider()
                                Button("削除", role: .destructive) {
                                    withAnimation { viewModel.presetRepository.remove(id: preset.id) }
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundStyle(.tertiary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }

            // 実行結果
            if let output = viewModel.lastOutput, !output.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("実行結果")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                    Text(output)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .errorAlert($viewModel.errorMessage)
        .sheet(isPresented: $viewModel.isAddingApp) { appEditSheet(isNew: true) }
        .sheet(isPresented: .init(
            get: { viewModel.editingApp != nil },
            set: { if !$0 { viewModel.cancelAppEdit() } }
        )) { appEditSheet(isNew: false) }
        .sheet(isPresented: $viewModel.isAddingPreset) { presetEditSheet(isNew: true) }
        .sheet(isPresented: .init(
            get: { viewModel.editingPreset != nil },
            set: { if !$0 { viewModel.cancelPresetEdit() } }
        )) { presetEditSheet(isNew: false) }
    }

    // MARK: - シート

    private func appEditSheet(isNew: Bool) -> some View {
        VStack(spacing: 24) {
            Text(isNew ? "アプリを追加" : "アプリを編集")
                .font(.title3)
                .fontWeight(.semibold)
            VStack(alignment: .leading, spacing: 14) {
                sheetField("ラベル", placeholder: "例: ZOZOTOWN", text: $viewModel.editLabel)
                sheetField("パッケージ名", placeholder: "例: jp.zozo.android", text: $viewModel.editPackage)
                VStack(alignment: .leading, spacing: 4) {
                    Text("アクティビティ名（任意）").font(.body).foregroundStyle(.secondary)
                    TextField("例: .MainActivity", text: $viewModel.editActivity)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                    Text("省略するとデフォルトのアクティビティで起動します")
                        .font(.subheadline).foregroundStyle(.tertiary)
                }
            }
            HStack {
                Button("キャンセル") { viewModel.cancelAppEdit() }
                    .controlSize(.large)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(isNew ? "追加" : "保存") { viewModel.saveApp() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(viewModel.editLabel.isEmpty || viewModel.editPackage.isEmpty)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 440)
    }

    private func presetEditSheet(isNew: Bool) -> some View {
        VStack(spacing: 24) {
            Text(isNew ? "カスタムコマンドを追加" : "カスタムコマンドを編集")
                .font(.title3)
                .fontWeight(.semibold)
            VStack(alignment: .leading, spacing: 14) {
                sheetField("ラベル", placeholder: "例: キャッシュクリア", text: $viewModel.editLabel)
                sheetField("コマンド", placeholder: "例: shell pm clear com.example", text: $viewModel.editCommand)
                Text("adb の後に続くコマンドを入力してください")
                    .font(.subheadline).foregroundStyle(.tertiary)
            }
            HStack {
                Button("キャンセル") { viewModel.cancelPresetEdit() }
                    .controlSize(.large)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(isNew ? "追加" : "保存") { viewModel.savePreset() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(viewModel.editLabel.isEmpty || viewModel.editCommand.isEmpty)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 440)
    }

    private func sheetField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.body).foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
                .font(.body)
        }
    }
}
