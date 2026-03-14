import Foundation

@Observable
final class DeviceViewModel {
    private(set) var devices: [Device] = []
    var selectedDevice: Device?
    var errorMessage: String?
    private(set) var isLoading = false

    private var adbService: ADBService?

    init() {
        do {
            adbService = try ADBService()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var service: ADBService? { adbService }

    func refreshDevices() async {
        guard let adbService else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            var newDevices = try await adbService.getDevices()

            // デバイス名を取得
            for i in newDevices.indices {
                if let model = await adbService.getDeviceModel(serial: newDevices[i].serialNumber) {
                    newDevices[i].displayName = model
                }
            }

            devices = newDevices

            // 選択中のデバイスが消えた場合はクリア、未選択なら最初のデバイスを選択
            if let selected = selectedDevice, !newDevices.contains(where: { $0.id == selected.id }) {
                selectedDevice = newDevices.first
            } else if selectedDevice == nil {
                selectedDevice = newDevices.first
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
