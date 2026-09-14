import SwiftUI

struct DeskTextField: View {
    let placeholder: String
    @Binding var text: String
    var autocapitalization: TextInputAutocapitalization = .words
    var usesDecimalPad = false

    var body: some View {
        TextField(
            "",
            text: $text,
            prompt: Text(placeholder)
                .foregroundColor(Palette.accent)
        )
        .textInputAutocapitalization(autocapitalization)
        .keyboardType(usesDecimalPad ? .decimalPad : .default)
        .foregroundStyle(Palette.primary)
        .padding(10)
        .background(Palette.background.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Palette.accent.opacity(0.35), lineWidth: 1)
        )
    }
}

struct DeskNoteEditor: View {
    @Binding var text: String
    var placeholder: String
    var minHeight: CGFloat = 90

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .foregroundStyle(Palette.primary)
                .frame(minHeight: minHeight)
                .padding(8)
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(placeholder)
                    .font(.body)
                    .foregroundColor(Palette.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false)
            }
        }
        .background(Palette.background.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Palette.accent.opacity(0.35), lineWidth: 1)
        )
    }
}
