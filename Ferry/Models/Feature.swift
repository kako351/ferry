import SwiftUI

enum Feature: String, CaseIterable, Identifiable {
    case textInput = "テキスト入力"
    case urlScheme = "URLスキーム"
    case screenshot = "スクリーンショット"
    case screenRecord = "画面録画"
    case wifiConnection = "Wi-Fi接続"
    case proxySettings = "プロキシ設定"
    case commandPreset = "コマンドプリセット"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .textInput: "keyboard"
        case .urlScheme: "link"
        case .screenshot: "camera"
        case .screenRecord: "record.circle"
        case .wifiConnection: "wifi"
        case .proxySettings: "network"
        case .commandPreset: "terminal"
        }
    }

    var tintColor: Color {
        switch self {
        case .textInput: .blue
        case .urlScheme: .purple
        case .screenshot: .green
        case .screenRecord: .red
        case .wifiConnection: .orange
        case .proxySettings: .cyan
        case .commandPreset: .indigo
        }
    }
}
