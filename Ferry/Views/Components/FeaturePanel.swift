import SwiftUI

struct FeaturePanel: View {
    let feature: Feature
    let device: Device?
    let service: ADBService?
    let serviceErrorMessage: String?

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
            TextInputPanel(device: device, service: service, serviceErrorMessage: serviceErrorMessage)
        case .urlScheme:
            URLSchemePanel(device: device, service: service, serviceErrorMessage: serviceErrorMessage)
        case .screenshot:
            ScreenshotPanel(device: device, service: service, serviceErrorMessage: serviceErrorMessage)
        case .screenRecord:
            ScreenRecordPanel(device: device, service: service, serviceErrorMessage: serviceErrorMessage)
        case .wifiConnection:
            WiFiConnectionPanel(device: device, service: service, serviceErrorMessage: serviceErrorMessage)
        case .proxySettings:
            ProxySettingsPanel(device: device, service: service, serviceErrorMessage: serviceErrorMessage)
        case .commandPreset:
            CommandPresetPanel(device: device, service: service, serviceErrorMessage: serviceErrorMessage)
        }
    }
}
