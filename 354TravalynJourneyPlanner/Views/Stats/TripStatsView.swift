import Charts
import SwiftUI

struct TripStatsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BannerStrip(imageName: "BannerMap", caption: "TRIP LEDGER")
                if store.destinations.isEmpty {
                    emptyDesk
                } else {
                    summaryRow
                    statusChartCard
                    packingChartCard
                    monthlyChartCard
                    transitChartCard
                }
            }
            .padding(.bottom, 28)
        }
        .deskBackdrop()
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var emptyDesk: some View {
        DeskSurface {
            VStack(alignment: .leading, spacing: 8) {
                Text("No stamps to chart")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Palette.primary)
                Text("Add a city ticket and the ledger will plot planned versus visited trips, packing, and transit modes.")
                    .font(.system(.subheadline, design: .default))
                    .foregroundStyle(Palette.accent)
            }
        }
        .padding(.horizontal, 16)
    }

    private var summaryRow: some View {
        HStack(spacing: 10) {
            summaryChip(title: "Cities", value: "\(store.destinations.count)")
            summaryChip(title: "Visited", value: "\(visitedCount)")
            summaryChip(title: "Packed", value: packedLabel)
        }
        .padding(.horizontal, 16)
    }

    private func summaryChip(title: String, value: String) -> some View {
        DeskSurface {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Palette.accent)
                Text(value)
                    .font(.system(.title3, design: .serif).weight(.semibold))
                    .foregroundStyle(Palette.primary)
            }
        }
    }

    private var statusChartCard: some View {
        DeskSurface {
            VStack(alignment: .leading, spacing: 12) {
                chartTitle("Ticket status")
                Chart(statusRows) { row in
                    BarMark(
                        x: .value("Status", row.title),
                        y: .value("Trips", row.count)
                    )
                    .foregroundStyle(row.color)
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                            .foregroundStyle(Palette.accent.opacity(0.22))
                        AxisValueLabel()
                            .foregroundStyle(Palette.accent)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Palette.primary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var packingChartCard: some View {
        DeskSurface {
            VStack(alignment: .leading, spacing: 12) {
                chartTitle("Suitcase progress")
                if packingRows.isEmpty {
                    Text("No packing items yet. Add tags to a suitcase to plot completion.")
                        .font(.system(.subheadline, design: .default))
                        .foregroundStyle(Palette.accent)
                } else {
                    Chart(packingRows) { row in
                        BarMark(
                            x: .value("Packed", row.percent),
                            y: .value("City", row.city)
                        )
                        .foregroundStyle(Palette.primary)
                    }
                    .frame(height: max(140, CGFloat(packingRows.count) * 36))
                    .chartXScale(domain: 0...100)
                    .chartXAxis {
                        AxisMarks(values: [0, 50, 100]) { value in
                            AxisGridLine()
                                .foregroundStyle(Palette.accent.opacity(0.22))
                            AxisValueLabel {
                                if let number = value.as(Int.self) {
                                    Text("\(number)%")
                                        .foregroundStyle(Palette.accent)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(Palette.primary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var monthlyChartCard: some View {
        DeskSurface {
            VStack(alignment: .leading, spacing: 12) {
                chartTitle("Trips by month")
                Chart(monthRows) { row in
                    BarMark(
                        x: .value("Month", row.title),
                        y: .value("Trips", row.count)
                    )
                    .foregroundStyle(Palette.accent)
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                            .foregroundStyle(Palette.accent.opacity(0.22))
                        AxisValueLabel()
                            .foregroundStyle(Palette.accent)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Palette.primary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var transitChartCard: some View {
        DeskSurface {
            VStack(alignment: .leading, spacing: 12) {
                chartTitle("Transit modes")
                Chart(transitRows) { row in
                    BarMark(
                        x: .value("Mode", row.title),
                        y: .value("Cities", row.count)
                    )
                    .foregroundStyle(row.color)
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                            .foregroundStyle(Palette.accent.opacity(0.22))
                        AxisValueLabel()
                            .foregroundStyle(Palette.accent)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Palette.primary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func chartTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(Palette.accent)
    }

    private var visitedCount: Int {
        store.destinations.filter(\.visited).count
    }

    private var packedLabel: String {
        let total = store.items.count
        if total == 0 {
            return "—"
        }
        let done = store.items.filter(\.isComplete).count
        return "\(Int((Double(done) / Double(total) * 100).rounded()))%"
    }

    private var statusRows: [NamedCount] {
        [
            NamedCount(title: "Planned", count: store.destinations.count - visitedCount, color: Palette.accent),
            NamedCount(title: "Visited", count: visitedCount, color: Palette.primary)
        ]
    }

    private var packingRows: [PackingRow] {
        store.destinations
            .sorted { lhs, rhs in
                lhs.city.localizedCaseInsensitiveCompare(rhs.city) == .orderedAscending
            }
            .compactMap { destination -> PackingRow? in
                let categoryIds = Set(store.categories(for: destination.id).map(\.id))
                let cityItems = store.items.filter { item in
                    categoryIds.contains(item.categoryId)
                }
                guard cityItems.isEmpty == false else {
                    return nil
                }
                let done = cityItems.filter(\.isComplete).count
                let percent = (Double(done) / Double(cityItems.count) * 100).rounded()
                return PackingRow(id: destination.id, city: destination.city, percent: percent)
            }
    }

    private var monthRows: [NamedCount] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.setLocalizedDateFormatFromTemplate("MMM yyyy")
        let grouped = Dictionary(grouping: store.destinations) { destination in
            calendar.dateInterval(of: .month, for: destination.startDate)?.start ?? destination.startDate
        }
        return grouped
            .sorted { lhs, rhs in
                lhs.key < rhs.key
            }
            .map { date, destinations in
                NamedCount(
                    title: formatter.string(from: date),
                    count: destinations.count,
                    color: Palette.accent
                )
            }
    }

    private var transitRows: [NamedCount] {
        var metro = 0
        var taxi = 0
        var rental = 0
        for destination in store.destinations {
            let preference = store.preference(for: destination.id)
            if preference.usesMetro {
                metro += 1
            }
            if preference.usesTaxi {
                taxi += 1
            }
            if preference.usesRental {
                rental += 1
            }
        }
        return [
            NamedCount(title: "Metro", count: metro, color: Palette.primary),
            NamedCount(title: "Taxi", count: taxi, color: Palette.accent),
            NamedCount(title: "Rental", count: rental, color: Palette.primary.opacity(0.65))
        ]
    }
}

private struct NamedCount: Identifiable {
    var id: String { title }
    let title: String
    let count: Int
    let color: Color
}

private struct PackingRow: Identifiable {
    let id: UUID
    let city: String
    let percent: Double
}
