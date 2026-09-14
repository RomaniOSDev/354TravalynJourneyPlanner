import SwiftUI

struct MetroLineRow: View {
    let title: String
    let subtitle: String
    let isOn: Bool
    let onChange: (Bool) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            metroGlyph
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Palette.primary)
                Text(subtitle)
                    .font(.system(.caption, design: .default))
                    .foregroundStyle(Palette.accent)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { isOn },
                set: { value in
                    onChange(value)
                }
            ))
            .labelsHidden()
            .tint(Palette.primary)
        }
        .padding(.vertical, 6)
    }

    private var metroGlyph: some View {
        ZStack {
            Capsule()
                .fill(isOn ? Palette.primary : Palette.accent.opacity(0.45))
                .frame(width: 7)
            VStack {
                Circle()
                    .fill(Palette.background)
                    .overlay(
                        Circle()
                            .stroke(Palette.primary, lineWidth: 2)
                    )
                    .frame(width: 14, height: 14)
                Spacer()
                Circle()
                    .fill(Palette.primary)
                    .frame(width: 12, height: 12)
            }
        }
        .frame(width: 18, height: 52)
    }
}
