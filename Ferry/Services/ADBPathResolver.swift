import Foundation

struct ADBPathResolver {
    static func resolve() throws -> String {
        if let androidHome = ProcessInfo.processInfo.environment["ANDROID_HOME"] {
            let path = "\(androidHome)/platform-tools/adb"
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        if let sdkRoot = ProcessInfo.processInfo.environment["ANDROID_SDK_ROOT"] {
            let path = "\(sdkRoot)/platform-tools/adb"
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        // macOSでよくあるパスをフォールバックとして確認
        let commonPaths = [
            "\(NSHomeDirectory())/Library/Android/sdk/platform-tools/adb",
            "/usr/local/bin/adb",
            "/opt/homebrew/bin/adb"
        ]

        for path in commonPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        throw ADBError.adbNotFound
    }
}
