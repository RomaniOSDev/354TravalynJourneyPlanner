import SwiftUI

struct SuitcaseCheckRow: View {
    let title: String
    let isComplete: Bool
    let isEssential: Bool
    let kitSealed: Bool
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onToggle: () -> Void
    let onToggleEssential: () -> Void
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
                    Text(isEssential ? "GATE ESSENTIAL" : "KIT ITEM")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(isEssential ? Palette.primary : Palette.accent)
                    Text(title)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Palette.primary)
                        .strikethrough(isComplete, color: Palette.accent)
                }
                Spacer()
                Button(action: onToggleEssential) {
                    Image(systemName: isEssential ? "star.fill" : "star")
                        .foregroundStyle(isEssential ? Palette.primary : Palette.accent)
                }
                .buttonStyle(.plain)
                .disabled(kitSealed)
                .opacity(kitSealed ? 0.45 : 1)
                Button("Edit", action: onEdit)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(Palette.accent)
                    .disabled(kitSealed)
                    .opacity(kitSealed ? 0.45 : 1)
            }
            HStack(spacing: 8) {
                orderButton(title: "Move Up", enabled: canMoveUp && kitSealed == false, action: onMoveUp)
                orderButton(title: "Move Down", enabled: canMoveDown && kitSealed == false, action: onMoveDown)
            }
        }
        .padding(12)
        .background(Palette.background.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isEssential ? Palette.primary.opacity(0.55) : Palette.accent.opacity(0.28), lineWidth: 1)
        )
    }

    private func orderButton(title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(.caption2, design: .monospaced).weight(.semibold))
            .foregroundStyle(enabled ? Palette.primary : Palette.accent.opacity(0.4))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .disabled(enabled == false)
    }
}
