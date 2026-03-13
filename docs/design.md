# ADB Desktop - 設計書

## アーキテクチャ

### 全体構成

MVVM（Model-View-ViewModel）パターンを採用する。

```
┌─────────────────────────────────────────────┐
│                   View (SwiftUI)            │
│  NavigationSplitView + 各機能画面            │
├─────────────────────────────────────────────┤
│                ViewModel                     │
│  各機能ごとにViewModelを用意                  │
│  @Observable マクロを使用                    │
├─────────────────────────────────────────────┤
│                  Model / Service             │
│  ADBService: adbコマンド実行の抽象化          │
│  各種Repository: データ永続化               │
├─────────────────────────────────────────────┤
│              Infrastructure                  │
│  ProcessRunner: Process()によるCLI実行       │
│  UserDefaults: データ保存                    │
└─────────────────────────────────────────────┘
```

### ディレクトリ構成

```
ADBDesktop/
├── ADBDesktopApp.swift          # エントリーポイント
├── Models/
│   ├── Device.swift             # デバイスモデル
│   ├── TextHistory.swift        # テキスト入力履歴
│   ├── URLScheme.swift          # URLスキームテンプレート
│   ├── AppLaunchEntry.swift     # アプリ起動エントリー
│   └── CommandPreset.swift      # カスタムコマンドプリセット
├── Services/
│   ├── ADBService.swift         # adbコマンド実行サービス
│   ├── ADBPathResolver.swift    # adbパス自動検出
│   └── NetworkService.swift     # IPアドレス取得
├── Repositories/
│   ├── TextHistoryRepository.swift
│   ├── URLSchemeRepository.swift
│   ├── AppLaunchRepository.swift
│   ├── CommandPresetRepository.swift
│   └── ProxySettingsRepository.swift
├── ViewModels/
│   ├── DeviceViewModel.swift
│   ├── TextInputViewModel.swift
│   ├── URLSchemeViewModel.swift
│   ├── ScreenshotViewModel.swift
│   ├── ScreenRecordViewModel.swift
│   ├── WiFiConnectionViewModel.swift
│   ├── ProxyViewModel.swift
│   └── CommandPresetViewModel.swift
├── Views/
│   ├── ContentView.swift        # メインレイアウト（NavigationSplitView）
│   ├── Sidebar/
│   │   ├── SidebarView.swift    # サイドバー全体
│   │   └── DeviceListView.swift # デバイス一覧
│   ├── Features/
│   │   ├── TextInputView.swift
│   │   ├── URLSchemeView.swift
│   │   ├── ScreenshotView.swift
│   │   ├── ScreenRecordView.swift
│   │   ├── WiFiConnectionView.swift
│   │   ├── ProxySettingsView.swift
│   │   └── CommandPresetView.swift
│   └── Components/
│       ├── StatusBadge.swift     # 接続状態バッジ
│       └── ErrorAlert.swift     # エラーアラート共通
└── Extensions/
    └── UserDefaults+Keys.swift  # UserDefaultsキー定義
```

---

## データモデル

### Device

```swift
struct Device: Identifiable, Equatable {
    let id: String          // シリアル番号
    let serialNumber: String
    let status: DeviceStatus
    var displayName: String  // adb shell getprop ro.product.model で取得
}

enum DeviceStatus: String {
    case device       // 正常接続
    case offline      // オフライン
    case unauthorized // USB認証未許可
}
```

### TextHistory

```swift
struct TextHistory: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let createdAt: Date
}
```

### URLScheme

```swift
struct URLScheme: Identifiable, Codable, Equatable {
    let id: UUID
    var label: String           // 表示名（例: "商品詳細"）
    var urlTemplate: String     // URLテンプレート（例: "myapp://product/{id}"）
}
```

### AppLaunchEntry

```swift
struct AppLaunchEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var label: String           // 表示名（例: "ZOZOTOWN"）
    var packageName: String     // パッケージ名
    var activityName: String    // アクティビティ名
}
```

### CommandPreset

```swift
struct CommandPreset: Identifiable, Codable, Equatable {
    let id: UUID
    var label: String           // 表示名
    var command: String         // adb以降のコマンド文字列
    var isBuiltIn: Bool         // デフォルトプリセットかどうか
}
```

---

## サービス設計

### ADBService

adbコマンドの実行を担当する。すべてのadb操作はこのサービスを経由する。

```swift
@Observable
final class ADBService {
    private let adbPath: String

    // デバイス
    func getDevices() async throws -> [Device]

    // テキスト入力
    func inputText(_ text: String, to device: Device) async throws

    // URLスキーム
    func openURL(_ url: String, on device: Device) async throws

    // スクリーンショット
    func takeScreenshot(from device: Device, saveTo directory: URL) async throws -> URL

    // 画面録画
    func startRecording(on device: Device) async throws
    func stopRecording(on device: Device, saveTo directory: URL) async throws -> URL

    // Wi-Fi接続
    func enableTcpip(on device: Device) async throws
    func connectWiFi(ip: String, port: Int) async throws
    func disconnect(from device: Device) async throws

    // プロキシ
    func setProxy(host: String, port: Int, on device: Device) async throws
    func clearProxy(on device: Device) async throws
    func getProxyStatus(on device: Device) async throws -> String?

    // 汎用コマンド
    func execute(command: String, on device: Device) async throws -> String

    // アプリ起動
    func launchApp(package: String, activity: String, on device: Device) async throws
}
```

### ADBPathResolver

```swift
struct ADBPathResolver {
    /// 優先順: ANDROID_HOME → ANDROID_SDK_ROOT → エラー
    static func resolve() throws -> String
}
```

### NetworkService

```swift
struct NetworkService {
    /// MacのローカルIPアドレスを取得（en0）
    static func getLocalIPAddress() -> String?

    /// 接続中デバイスのIPアドレスを取得
    static func getDeviceIPAddress(device: Device, adbService: ADBService) async throws -> String
}
```

---

## 画面設計

### メインレイアウト

`NavigationSplitView` を使用した2カラムレイアウト。

- **サイドバー（左）**: デバイス一覧 + 機能メニュー
- **詳細エリア（右）**: 選択した機能の操作パネル

### 機能メニュー項目

```swift
enum Feature: String, CaseIterable, Identifiable {
    case textInput       = "テキスト入力"
    case urlScheme       = "URLスキーム"
    case screenshot      = "スクリーンショット"
    case screenRecord    = "画面録画"
    case wifiConnection  = "Wi-Fi接続"
    case proxySettings   = "プロキシ設定"
    case commandPreset   = "コマンドプリセット"
}
```

### 各画面の構成

#### テキスト入力画面
```
┌─────────────────────────────────┐
│ テキスト入力                      │
│                                  │
│ [テキストフィールド        ] [送信] │
│                                  │
│ 履歴:                            │
│ ┌──────────────────────────┐    │
│ │ user@example.com   [送信][×] │  │
│ │ password123        [送信][×] │  │
│ │ test_account       [送信][×] │  │
│ └──────────────────────────┘    │
└─────────────────────────────────┘
```

#### URLスキーム画面
```
┌──────────────────────────────────┐
│ URLスキーム                       │
│                                   │
│ [+ 追加]                          │
│                                   │
│ ┌───────────────────────────┐    │
│ │ 商品詳細                    │    │
│ │ myapp://product/{id}       │    │
│ │ [id: ___________] [送信][編集][×]│
│ ├───────────────────────────┤    │
│ │ トップ                     │    │
│ │ myapp://home               │    │
│ │                  [送信][編集][×] │
│ └───────────────────────────┘    │
└──────────────────────────────────┘
```

#### スクリーンショット画面
```
┌─────────────────────────────────┐
│ スクリーンショット                 │
│                                  │
│        [📸 撮影する]              │
│                                  │
│ 保存先: ~/Downloads/             │
│ 最後の撮影: screenshot_2026-...   │
└─────────────────────────────────┘
```

#### 画面録画画面
```
┌─────────────────────────────────┐
│ 画面録画                         │
│                                  │
│        [⏺ 録画開始]              │
│    or  [⏹ 録画停止]  00:15       │
│                                  │
│ 保存先: ~/Downloads/             │
│ 最後の録画: recording_2026-...    │
└─────────────────────────────────┘
```

#### Wi-Fi接続画面
```
┌─────────────────────────────────┐
│ Wi-Fi adb接続                    │
│                                  │
│ 状態: USB接続中                   │
│ デバイスIP: 192.168.1.10         │
│                                  │
│ [Wi-Fiに切り替え] / [切断]        │
└─────────────────────────────────┘
```

#### プロキシ設定画面
```
┌─────────────────────────────────┐
│ プロキシ設定                      │
│                                  │
│ 状態: オフ                       │
│                                  │
│ ホスト: 192.168.1.5 (自動検出)    │
│ ポート: [8080]                   │
│                                  │
│ [プロキシをオンにする]             │
└─────────────────────────────────┘
```

#### コマンドプリセット画面
```
┌──────────────────────────────────┐
│ コマンドプリセット                  │
│                                   │
│ [+ カスタム追加]                   │
│                                   │
│ ■ アプリ起動                      │
│   ┌────────────────────────┐     │
│   │ ZOZOTOWN               │     │
│   │ jp.zozo.android/.Main  [▶][編集][×]│
│   │ MyApp                  │     │
│   │ com.example/.Main      [▶][編集][×]│
│   └────────────────────────┘     │
│   [+ アプリ追加]                   │
│                                   │
│ ■ テキスト入力           [▶]      │
│ ■ スクリーンショット撮影   [▶]     │
│ ■ 動画撮影               [▶]     │
│ ■ URLスキーム実行         [▶]     │
│ ■ Wi-Fiプロキシ設定       [▶]     │
│                                   │
│ ── カスタム ──                    │
│ ■ キャッシュクリア        [▶][編集][×]│
└──────────────────────────────────┘
```

---

## データ永続化

UserDefaultsを使用し、Codableプロトコルでシリアライズする。

### 保存キー

| キー | 型 | 内容 |
|------|-----|------|
| `text_history` | `[TextHistory]` | テキスト入力履歴 |
| `url_schemes` | `[URLScheme]` | URLスキームテンプレート |
| `app_launch_entries` | `[AppLaunchEntry]` | アプリ起動エントリー |
| `custom_presets` | `[CommandPreset]` | カスタムコマンドプリセット |
| `proxy_port` | `Int` | プロキシポート番号 |

---

## エラーハンドリング

### ADBError

```swift
enum ADBError: LocalizedError {
    case adbNotFound
    case deviceNotConnected
    case commandFailed(String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .adbNotFound:
            return "adbが見つかりません。Android SDKがインストールされているか確認してください。"
        case .deviceNotConnected:
            return "デバイスが接続されていません。"
        case .commandFailed(let message):
            return "コマンドの実行に失敗しました: \(message)"
        case .timeout:
            return "コマンドがタイムアウトしました。"
        }
    }
}
```

### エラー表示方針

- adbコマンド失敗時は `.alert` モディファイアでダイアログ表示
- 各ViewModelに `errorMessage: String?` プロパティを持たせ、非nilの場合にアラートを表示
- アラートのdismiss時に `errorMessage` を `nil` にクリアする

---

## 非同期処理

- すべてのadbコマンド実行は `async/await` で非同期化
- `Task {}` でViewからViewModelの非同期メソッドを呼び出す
- 画面録画の停止は `Ctrl+C`（SIGINT）相当のシグナルをProcessに送信

---

## セキュリティ考慮事項

- `adb shell input text` に渡す文字列はシェルエスケープする
- URLスキームの文字列もエスケープ処理を行う
- ユーザー入力を直接シェルコマンドに渡さず、引数として分離する（コマンドインジェクション対策）
