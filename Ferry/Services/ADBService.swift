import Foundation

@Observable
final class ADBService {
    let adbPath: String
    private var recordingProcess: Process?
    private var recordingRemotePath: String?

    init() throws {
        self.adbPath = try ADBPathResolver.resolve()
    }

    // MARK: - デバイス管理

    func getDevices() async throws -> [Device] {
        let output = try await runADB(["devices", "-l"])
        return parseDeviceList(output)
    }

    func getDeviceModel(serial: String) async -> String? {
        let result = try? await runADB(["-s", serial, "shell", "getprop", "ro.product.model"])
        return result?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - テキスト入力

    func inputText(_ text: String, to device: Device) async throws {
        let escaped = text.replacingOccurrences(of: " ", with: "%s")
            .replacingOccurrences(of: "&", with: "\\&")
            .replacingOccurrences(of: "<", with: "\\<")
            .replacingOccurrences(of: ">", with: "\\>")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\"", with: "\\\"")
        _ = try await runADB(["-s", device.serialNumber, "shell", "input", "text", escaped])
    }

    // MARK: - URLスキーム

    func openURL(_ url: String, on device: Device) async throws {
        _ = try await runADB(["-s", device.serialNumber, "shell", "am", "start", "-a", "android.intent.action.VIEW", "-d", url])
    }

    // MARK: - スクリーンショット

    func takeScreenshot(from device: Device, saveTo directory: URL) async throws -> URL {
        let timestamp = Self.timestampString()
        let fileName = "screenshot_\(timestamp).png"
        let remotePath = "/sdcard/\(fileName)"
        let localPath = directory.appendingPathComponent(fileName)

        _ = try await runADB(["-s", device.serialNumber, "shell", "screencap", "-p", remotePath])
        _ = try await runADB(["-s", device.serialNumber, "pull", remotePath, localPath.path])
        _ = try await runADB(["-s", device.serialNumber, "shell", "rm", remotePath])

        return localPath
    }

    // MARK: - 画面録画

    func startRecording(on device: Device) async throws {
        let timestamp = Self.timestampString()
        let remotePath = "/sdcard/recording_\(timestamp).mp4"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: adbPath)
        process.arguments = ["-s", device.serialNumber, "shell", "screenrecord", remotePath]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()
        recordingProcess = process
        recordingRemotePath = remotePath
    }

    func stopRecording(on device: Device, saveTo directory: URL) async throws -> URL {
        if let process = recordingProcess, process.isRunning {
            process.interrupt()
            process.waitUntilExit()
        }
        recordingProcess = nil

        guard let remotePath = recordingRemotePath else {
            throw ADBError.commandFailed("録画中のファイル情報が見つかりません")
        }
        recordingRemotePath = nil

        // 録画ファイルを端末から取得
        try await Task.sleep(for: .seconds(1))

        let fileName = URL(fileURLWithPath: remotePath).lastPathComponent
        let localPath = directory.appendingPathComponent(fileName)
        _ = try await runADB(["-s", device.serialNumber, "pull", remotePath, localPath.path])
        _ = try await runADB(["-s", device.serialNumber, "shell", "rm", remotePath])

        return localPath
    }

    // MARK: - Wi-Fi接続

    func enableTcpip(on device: Device, port: Int = 5555) async throws {
        _ = try await runADB(["-s", device.serialNumber, "tcpip", "\(port)"])
    }

    func connectWiFi(ip: String, port: Int = 5555) async throws {
        let output = try await runADB(["connect", "\(ip):\(port)"])
        if output.contains("failed") || output.contains("unable") {
            throw ADBError.commandFailed(output)
        }
    }

    func disconnect(from address: String) async throws {
        _ = try await runADB(["disconnect", address])
    }

    // MARK: - プロキシ

    func setProxy(host: String, port: Int, on device: Device) async throws {
        _ = try await runADB(["-s", device.serialNumber, "shell", "settings", "put", "global", "http_proxy", "\(host):\(port)"])
    }

    func clearProxy(on device: Device) async throws {
        _ = try await runADB(["-s", device.serialNumber, "shell", "settings", "put", "global", "http_proxy", ":0"])
    }

    func getProxyStatus(on device: Device) async throws -> String? {
        let output = try await runADB(["-s", device.serialNumber, "shell", "settings", "get", "global", "http_proxy"])
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "null" || trimmed == ":0" {
            return nil
        }
        return trimmed
    }

    // MARK: - アプリ起動

    func launchApp(package: String, activity: String?, on device: Device) async throws {
        if let activity, !activity.isEmpty {
            _ = try await runADB(["-s", device.serialNumber, "shell", "am", "start", "-n", "\(package)/\(activity)"])
        } else {
            _ = try await runADB(["-s", device.serialNumber, "shell", "monkey", "-p", package, "-c", "android.intent.category.LAUNCHER", "1"])
        }
    }

    // MARK: - 汎用コマンド

    func execute(arguments: [String], on device: Device) async throws -> String {
        var args = ["-s", device.serialNumber]
        args.append(contentsOf: arguments)
        return try await runADB(args)
    }

    // MARK: - Private

    private func runADB(_ arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let pipe = Pipe()

            process.executableURL = URL(fileURLWithPath: adbPath)
            process.arguments = arguments
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: ADBError.commandFailed(error.localizedDescription))
                return
            }

            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            if process.terminationStatus != 0 {
                let message = output.isEmpty
                    ? "終了コード: \(process.terminationStatus)"
                    : output
                continuation.resume(throwing: ADBError.commandFailed(message))
            } else {
                continuation.resume(returning: output)
            }
        }
    }

    private func parseDeviceList(_ output: String) -> [Device] {
        output.split(separator: "\n")
            .dropFirst() // "List of devices attached" の行をスキップ
            .compactMap { line -> Device? in
                let parts = line.split(separator: " ", maxSplits: 1)
                guard parts.count >= 2 else { return nil }
                let serial = String(parts[0])
                let statusString = String(parts[1]).trimmingCharacters(in: .whitespaces)
                    .split(separator: " ").first.map(String.init) ?? ""
                let status = DeviceStatus(rawValue: statusString) ?? .unknown
                return Device(serialNumber: serial, status: status)
            }
    }

    private static func timestampString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: Date())
    }
}
