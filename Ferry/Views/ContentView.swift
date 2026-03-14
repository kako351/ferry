import SwiftUI

struct ContentView: View {
    @State private var deviceViewModel = DeviceViewModel()

    private var features: [[Feature]] {
        let all = Feature.allCases
        return stride(from: 0, to: all.count, by: 3).map { i in
            Array(all[i..<min(i + 3, all.count)])
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            deviceBar

            Divider()

            if deviceViewModel.devices.isEmpty && !deviceViewModel.isLoading {
                emptyDeviceView
            } else {
                panelGrid
            }
        }
        .frame(minWidth: 960, minHeight: 650)
        .task {
            await deviceViewModel.refreshDevices()
        }
    }

    // MARK: - デバイスバー

    private var deviceBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "iphone")
                .foregroundStyle(.secondary)

            if deviceViewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
                Text("検出中...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if let device = deviceViewModel.selectedDevice {
                StatusBadge(status: device.status)
                Picker(selection: Binding(
                    get: { deviceViewModel.selectedDevice },
                    set: { deviceViewModel.selectedDevice = $0 }
                )) {
                    ForEach(deviceViewModel.devices) { d in
                        Text("\(d.displayName) (\(d.serialNumber))")
                            .tag(Optional(d))
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 300)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
                Text("デバイス未接続")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task { await deviceViewModel.refreshDevices() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .help("デバイス再検出")
            .disabled(deviceViewModel.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: - パネルグリッド

    private var panelGrid: some View {
        ScrollView {
            Grid(alignment: .topLeading, horizontalSpacing: 12, verticalSpacing: 12) {
                ForEach(Array(features.enumerated()), id: \.offset) { _, row in
                    GridRow {
                        ForEach(row) { feature in
                            FeaturePanel(
                                feature: feature,
                                device: deviceViewModel.selectedDevice
                            )
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - 空状態

    private var emptyDeviceView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "cable.connector.slash")
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            Text("デバイスが接続されていません")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Text("AndroidデバイスをUSBで接続してください")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Button {
                Task { await deviceViewModel.refreshDevices() }
            } label: {
                Label("再検出", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 4)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
