import SwiftUI

struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "追加"

    var body: some View {
        HStack(alignment: .center) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            if let action {
                Button {
                    action()
                } label: {
                    Label(actionLabel, systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
            }
        }
    }
}

struct FeatureHeader: View {
    let title: String
    let icon: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    var isMono: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .trailing)
            if isMono {
                Text(value)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(valueColor)
                    .textSelection(.enabled)
            } else {
                Text(value)
                    .foregroundStyle(valueColor)
                    .textSelection(.enabled)
            }
        }
        .font(.subheadline)
    }
}
