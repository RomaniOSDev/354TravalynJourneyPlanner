import SwiftUI

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color("AppBackground")
                    .overlay {
                        Image("BgSkyline")
                            .resizable()
                            .scaledToFill()
                            .opacity(0.33)
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
}
