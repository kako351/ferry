import Foundation

@Observable
final class WiFiConnectionViewModel {
    var errorMessage: String?
    private(set) var isConnecting = false
    private(set) var deviceIP: String?
    private(set) var isWiFiConnected = false

    func fetchDeviceIP(device: Device, using service: ADBService) async {
        do {
            deviceIP = try await NetworkService.getDeviceIPAddress(device: device, adbService: service)
        } catch {
            deviceIP = nil
        }
    }

    func connectViaWiFi(device: Device, using service: ADBService) async {
        isConnecting = true
        defer { isConnecting = false }

        // 毎回最新のIPを取得してから接続する
        await fetchDeviceIP(device: device, using: service)

        guard let ip = deviceIP else {
            errorMessage = "デバイスのIPアドレスを取得できません。Wi-Fiに接続されているか確認してください。"
            return
        }

        do {
            try await service.enableTcpip(on: device)
            try await Task.sleep(for: .seconds(2))
            try await service.connectWiFi(ip: ip)
            isWiFiConnected = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func disconnect(device: Device, using service: ADBService) async {
        isConnecting = true
        defer { isConnecting = false }

        if deviceIP == nil {
            await fetchDeviceIP(device: device, using: service)
        }
        guard let ip = deviceIP else {
            errorMessage = "接続先IPが不明なため切断できませんでした。"
            return
        }

        do {
            try await service.disconnect(from: "\(ip):5555")
            isWiFiConnected = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
