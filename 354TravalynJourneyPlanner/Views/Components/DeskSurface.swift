import SwiftUI

struct GateRailPanel<Content: View>: View {
    private let content: Content
    var accentEdge = true

    init(accentEdge: Bool = true, @ViewBuilder content: () -> Content) {
        self.accentEdge = accentEdge
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        Palette.surface,
                        Palette.surface.opacity(0.88),
                        Palette.background.opacity(0.55)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(alignment: .leading) {
                if accentEdge {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Palette.primary)
                        .frame(width: 4)
                        .padding(.vertical, 10)
                        .padding(.leading, 0)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Palette.accent.opacity(0.28), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.22), radius: 8, y: 4)
    }
}

struct DeskSurface<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GateRailPanel(content: { content })
    }
}
