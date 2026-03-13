import Foundation

@Observable
final class ProxyViewModel {
    var errorMessage: String?
    private(set) var isToggling = false
    private(set) var currentProxy: String?
    var port: String = "8080"

    var isProxyEnabled: Bool {
        currentProxy != nil
    }

    var localIP: String? {
        NetworkService.getLocalIPAddress()
    }

    func fetchStatus(device: Device, using service: ADBService) async {
        do {
            currentProxy = try await service.getProxyStatus(on: device)
        } catch {
            currentProxy = nil
        }
    }

    func enableProxy(device: Device, using service: ADBService) async {
        guard let ip = localIP, let portInt = Int(port) else {
            errorMessage = "IPアドレスまたはポートの取得に失敗しました。"
            return
        }

        isToggling = true
        defer { isToggling = false }

        do {
            try await service.setProxy(host: ip, port: portInt, on: device)
            currentProxy = "\(ip):\(port)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func disableProxy(device: Device, using service: ADBService) async {
        isToggling = true
        defer { isToggling = false }

        do {
            try await service.clearProxy(on: device)
            currentProxy = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
