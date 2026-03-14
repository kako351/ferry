# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 概要

Ferry は、Android Debug Bridge (adb) の頻出操作をワンクリックで実行できる macOS ネイティブアプリケーション。Swift / SwiftUI 製。

## ビルド・実行

```bash
# ビルドして即起動（開発時はこちら）
./run.sh

# ビルドのみ
swift build

# リリースビルド
swift build -c release
```

`run.sh` は `swift build` 後に `.app` バンドルを構築し、既存プロセスを終了してから起動する。

### Xcodeプロジェクト生成

`project.yml` は XcodeGen 用の設定ファイル。Xcode で開発する場合は `xcodegen` で `.xcodeproj` を生成する。

## アーキテクチャ

MVVM パターン。`@Observable` マクロを使用。

```
View (SwiftUI)
  └── ViewModel (@Observable)
        └── ADBService / Repository
              └── Process() でadbコマンド実行 / UserDefaults
```

### データフロー

- すべての adb コマンドは `ADBService` を経由して実行する
- `ADBService.runADB(_:)` が `Process()` を使って adb バイナリを呼び出す
- adb バイナリのパスは `ADBPathResolver.resolve()` が `ANDROID_HOME` → `ANDROID_SDK_ROOT` の順で環境変数から解決する
- データ永続化はすべて `UserDefaults` + `Codable`。キーは `UserDefaults+Keys.swift` に定義

### 主要コンポーネント

| クラス/ファイル | 役割 |
|---|---|
| `ADBService` | adb コマンド実行の中心。全機能の実装を持つ |
| `ADBPathResolver` | 環境変数から adb パスを解決 |
| `NetworkService` | Mac の IP アドレス取得 (en0) |
| `DeviceViewModel` | デバイス一覧・選択管理。他の ViewModel が依存する |
| `ContentView` | `NavigationSplitView` による2カラムレイアウトのルート |

### ソースディレクトリ

`Ferry/` 配下にすべてのソースコードが格納されている。

### 機能と対応ファイル

各機能は `Feature` enum で管理され、ViewModel と View が1対1で対応する。

| 機能 | ViewModel | View |
|---|---|---|
| デバイス管理 | `DeviceViewModel` | サイドバー内 |
| テキスト入力 | `TextInputViewModel` | `TextInputView` |
| URLスキーム | `URLSchemeViewModel` | `URLSchemeView` |
| スクリーンショット | `ScreenshotViewModel` | `ScreenshotView` |
| 画面録画 | `ScreenRecordViewModel` | `ScreenRecordView` |
| Wi-Fi接続 | `WiFiConnectionViewModel` | `WiFiConnectionView` |
| プロキシ設定 | `ProxyViewModel` | `ProxySettingsView` |
| コマンドプリセット | `CommandPresetViewModel` | `CommandPresetView` |

## 設計上の注意

- **コマンドインジェクション対策**: ユーザー入力をシェルコマンド文字列に結合せず、`Process.arguments` の配列要素として渡す
- **非同期処理**: adb コマンドは `async/await` で実行し UI をブロックしない。`runADB` 内で `withCheckedThrowingContinuation` を使用
- **エラーハンドリング**: 各 ViewModel に `errorMessage: String?` を持たせ、View 側で `.alert` 表示。`ADBError` enum に定義済み
- **App Sandbox 無効**: `project.yml` で `ENABLE_APP_SANDBOX: false`（adb 実行に必要）
- **保存先**: スクリーンショット・録画ファイルはすべて `~/Downloads/` 固定

## 動作要件

- macOS 14 (Sonoma) 以上
- Android SDK インストール済み（`ANDROID_HOME` または `ANDROID_SDK_ROOT` 環境変数が必要）
