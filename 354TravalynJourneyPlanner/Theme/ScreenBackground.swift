import SwiftUI

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                ZStack {
                    Color("AppBackground")
                    Image("BgSkyline")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.28)
                    LinearGradient(
                        colors: [
                            Palette.background.opacity(0.15),
                            Palette.background.opacity(0.72)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .clipped()
                .ignoresSafeArea()
            }
    }
}

extension View {
    func deskBackdrop() -> some View {
        modifier(ScreenBackground())
    }

    func clearScrollBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.clear)
    }
}
