import Foundation

struct NetworkService {
    static func getLocalIPAddress() -> String? {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/sbin/ipconfig")
        process.arguments = ["getifaddr", "en0"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return output?.isEmpty == true ? nil : output
    }

    static func getDeviceIPAddress(device: Device, adbService: ADBService) async throws -> String? {
        let output = try await adbService.execute(
            arguments: ["shell", "ip", "route", "show", "dev", "wlan0"],
            on: device
        )
        // "... src 192.168.x.x ..." パターンからIPを取得
        guard let regex = try? NSRegularExpression(pattern: "src\\s+(\\d+\\.\\d+\\.\\d+\\.\\d+)") else { return nil }
        let range = NSRange(output.startIndex..., in: output)
        if let match = regex.firstMatch(in: output, range: range),
           let ipRange = Range(match.range(at: 1), in: output) {
            return String(output[ipRange])
        }
        return nil
    }
}
