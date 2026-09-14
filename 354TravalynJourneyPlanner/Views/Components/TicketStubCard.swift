import SwiftUI

struct TicketStubCard: View {
    @EnvironmentObject private var store: AppStore
    let destination: Destination

    var body: some View {
        HStack(spacing: 0) {
            stubRail
            perforation
            passBody
        }
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Palette.primary.opacity(0.55), lineWidth: 1.2)
        )
    }

    private var stubRail: some View {
        VStack(spacing: 9) {
            Text(TripFormat.cityCode(destination.city))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Palette.background)
                .rotationEffect(.degrees(-90))
                .frame(width: 44)
            ForEach(0..<5, id: \.self) { _ in
                Circle()
                    .fill(Palette.background)
                    .frame(width: 9, height: 9)
            }
        }
        .padding(.vertical, 12)
        .frame(width: 36)
        .frame(maxHeight: .infinity)
        .background(Palette.primary)
    }

    private var perforation: some View {
        VStack(spacing: 3) {
            ForEach(0..<14, id: \.self) { _ in
                Capsule()
                    .fill(Palette.background.opacity(0.75))
                    .frame(width: 2, height: 5)
            }
        }
        .padding(.vertical, 8)
        .frame(width: 12)
        .background(Palette.surface)
    }

    private var passBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("BOARDING PASS")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundStyle(Palette.accent)
                    .tracking(1.4)
                Spacer()
                if destination.visited {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Palette.primary)
                } else {
                    Text("PLANNED")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Palette.accent)
                }
            }
            Text(destination.city)
                .font(.system(.title3, design: .serif).weight(.semibold))
                .foregroundStyle(Palette.primary)
            Text(destination.country)
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(Palette.accent)
            HStack {
                Text(TripFormat.dateRange(start: destination.startDate, end: destination.endDate))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Palette.accent)
                Spacer()
                Text(packingLabel)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Palette.primary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var packingLabel: String {
        let progress = store.packingProgress(for: destination.id)
        return TripFormat.packedCount(done: progress.done, total: progress.total).uppercased()
    }
}
