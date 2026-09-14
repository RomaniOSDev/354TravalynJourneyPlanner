import SwiftUI

struct BannerStrip: View {
    let imageName: String
    let caption: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 118)
                .clipped()
            LinearGradient(
                colors: [Palette.background.opacity(0.05), Palette.background.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
            Text(caption)
                .font(.system(.caption, design: .serif).weight(.semibold))
                .foregroundStyle(Palette.primary)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 118)
        .clipped()
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Palette.primary)
                .frame(height: 3)
        }
    }
}
