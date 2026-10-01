import SwiftUI

struct TicketStubCard: View {
    @EnvironmentObject private var store: AppStore
    let destination: Destination

    var body: some View {
        HStack(spacing: 0) {
            gateMark
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("DEPARTURE RAIL")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.accent)
                        .tracking(1.1)
                    Spacer()
                    statusChip
                }
                Text(destination.city)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Palette.primary)
                Text(destination.country)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Palette.accent)
                HStack {
                    Text(TripFormat.dateRange(start: destination.startDate, end: destination.endDate))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Palette.accent)
                    Spacer()
                    Text(statusLine)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Palette.primary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            LinearGradient(
                colors: [Palette.surface, Palette.background.opacity(0.65)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Palette.primary.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 6, y: 3)
    }

    private var gateMark: some View {
        VStack(spacing: 8) {
            Text(TripFormat.cityCode(destination.city))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Palette.background)
                .rotationEffect(.degrees(-90))
                .frame(width: 42)
            Image(systemName: destination.isKitSealed ? "lock.fill" : "lock.open")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Palette.background)
        }
        .padding(.vertical, 14)
        .frame(width: 40)
        .frame(maxHeight: .infinity)
        .background(Palette.primary)
    }

    private var statusChip: some View {
        Text(destination.visited ? "DONE" : "OPEN")
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(destination.visited ? Palette.background : Palette.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(destination.visited ? Palette.accent : Palette.background.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var statusLine: String {
        let progress = store.packingProgress(for: destination.id)
        let kit = destination.isKitSealed ? "SEALED" : "UNSEALED"
        return "\(kit) · \(TripFormat.packedCount(done: progress.done, total: progress.total).uppercased())"
    }
}
