import SwiftUI

struct ActionButtonStyle: ButtonStyle {
    let color: Color
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isDisabled ? color.opacity(0.3) : color)
            )
            .opacity(configuration.isPressed && !isDisabled ? 0.8 : 1.0)
    }
}

struct SmallActionButtonStyle: ButtonStyle {
    let color: Color
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isDisabled ? color.opacity(0.3) : color)
            )
            .opacity(configuration.isPressed && !isDisabled ? 0.8 : 1.0)
    }
}
