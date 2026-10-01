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
                .frame(height: 108)
                .clipped()
            LinearGradient(
                colors: [Palette.background.opacity(0.05), Palette.background.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(Palette.primary)
                    .frame(width: 3, height: 18)
                Text(caption)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(Palette.primary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 108)
        .clipped()
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Palette.primary)
                .frame(height: 2)
        }
    }
}
