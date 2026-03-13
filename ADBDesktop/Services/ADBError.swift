import Foundation

enum ADBError: LocalizedError {
    case adbNotFound
    case deviceNotConnected
    case commandFailed(String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .adbNotFound:
            "adbが見つかりません。Android SDKがインストールされているか確認してください。"
        case .deviceNotConnected:
            "デバイスが接続されていません。"
        case .commandFailed(let message):
            "コマンドの実行に失敗しました: \(message)"
        case .timeout:
            "コマンドがタイムアウトしました。"
        }
    }
}
