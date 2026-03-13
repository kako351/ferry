import SwiftUI

struct FeaturePanel: View {
    let feature: Feature
    let device: Device?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ヘッダー
            HStack(spacing: 12) {
                Image(systemName: feature.systemImage)
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(feature.tintColor)
                    .clipShape(RoundedRectangle(cornerRadius: 7))

                Text(feature.rawValue)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .padding(.horizontal, 16)

            // コンテンツ
            featureContent
                .padding(16)
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
    }

    @ViewBuilder
    private var featureContent: some View {
        switch feature {
        case .textInput:
            TextInputPanel(device: device)
        case .urlScheme:
            URLSchemePanel(device: device)
        case .screenshot:
            ScreenshotPanel(device: device)
        case .screenRecord:
            ScreenRecordPanel(device: device)
        case .wifiConnection:
            WiFiConnectionPanel(device: device)
        case .proxySettings:
            ProxySettingsPanel(device: device)
        case .commandPreset:
            CommandPresetPanel(device: device)
        }
    }
}
