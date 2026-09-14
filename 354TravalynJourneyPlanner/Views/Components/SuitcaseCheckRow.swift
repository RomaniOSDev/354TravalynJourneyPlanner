import SwiftUI

struct SuitcaseCheckRow: View {
    let title: String
    let isComplete: Bool
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onToggle: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: isComplete ? "checkmark.square.fill" : "square")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(isComplete ? Palette.primary : Palette.accent)
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 3) {
                    Text("LUGGAGE TAG")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Palette.accent)
                    Text(title)
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(Palette.primary)
                        .strikethrough(isComplete, color: Palette.accent)
                }
                Spacer()
                Button("Edit", action: onEdit)
                    .font(.system(.caption, design: .serif).weight(.semibold))
                    .foregroundStyle(Palette.accent)
            }
            HStack(spacing: 8) {
                orderButton(title: "Move Up", enabled: canMoveUp, action: onMoveUp)
                orderButton(title: "Move Down", enabled: canMoveDown, action: onMoveDown)
            }
        }
        .padding(12)
        .background(Palette.background.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Palette.accent.opacity(0.28), lineWidth: 1)
        )
    }

    private func orderButton(title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(.caption2, design: .monospaced).weight(.semibold))
            .foregroundStyle(enabled ? Palette.primary : Palette.accent.opacity(0.4))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Palette.surface)
            .clipShape(Capsule())
            .disabled(enabled == false)
    }
}
