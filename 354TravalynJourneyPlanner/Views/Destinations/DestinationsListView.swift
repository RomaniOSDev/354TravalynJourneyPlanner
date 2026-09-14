import SwiftUI

struct DestinationsListView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showEditor = false
    @State private var searchText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                searchField
                    .padding(.top, 8)
                filterStrip
                sortStrip
                if let next = store.nextUpcomingTrip(), searchText.isEmpty {
                    countdownCard(next)
                }
                if store.visibleDestinations(search: searchText).isEmpty {
                    emptyDesk
                } else {
                    ticketStack
                }
            }
            .padding(.bottom, 28)
        }
        .deskBackdrop()
        .navigationTitle("Destinations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Palette.primary)
                }
                .accessibilityLabel("Add city")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    TripStatsView()
                } label: {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(Palette.primary)
                }
                .accessibilityLabel("Statistics")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(Palette.primary)
                }
                .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $showEditor) {
            DestinationEditorView(existingId: nil)
                .environmentObject(store)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dataReset"))) { _ in
            showEditor = false
            searchText = ""
        }
    }

    private var searchField: some View {
        DeskTextField(
            placeholder: "Search city or country",
            text: $searchText,
            autocapitalization: .words
        )
        .padding(.horizontal, 16)
    }

    private var filterStrip: some View {
        HStack(spacing: 8) {
            ForEach(DestinationFilter.allCases) { filter in
                Button {
                    store.setFilter(filter)
                    Haptics.tap()
                } label: {
                    Text(filter.title)
                        .font(.system(.caption, design: .serif).weight(.semibold))
                        .foregroundStyle(store.filterPreference == filter ? Palette.background : Palette.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(store.filterPreference == filter ? Palette.primary : Palette.surface)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Palette.accent.opacity(0.45), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private var sortStrip: some View {
        HStack(spacing: 8) {
            Text("SORT")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Palette.accent)
            ForEach(DestinationSort.allCases) { sort in
                Button {
                    store.setSort(sort)
                    Haptics.tap()
                } label: {
                    Text(sort.title)
                        .font(.system(.caption2, design: .serif).weight(.semibold))
                        .foregroundStyle(store.sortPreference == sort ? Palette.background : Palette.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(store.sortPreference == sort ? Palette.accent : Palette.surface)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private func countdownCard(_ destination: Destination) -> some View {
        DeskSurface {
            VStack(alignment: .leading, spacing: 6) {
                Text("NEXT STAMP")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Palette.accent)
                Text(destination.city)
                    .font(.system(.title3, design: .serif).weight(.semibold))
                    .foregroundStyle(Palette.primary)
                Text(TripFormat.countdown(start: destination.startDate, end: destination.endDate))
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Palette.primary)
                Text(TripFormat.dateRange(start: destination.startDate, end: destination.endDate))
                    .font(.system(.caption, design: .default))
                    .foregroundStyle(Palette.accent)
            }
        }
        .padding(.horizontal, 16)
    }

    private var ticketStack: some View {
        VStack(spacing: 14) {
            ForEach(store.visibleDestinations(search: searchText)) { destination in
                NavigationLink {
                    DestinationDetailView(destinationId: destination.id)
                } label: {
                    TicketStubCard(destination: destination)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    private var emptyDesk: some View {
        DeskSurface {
            VStack(alignment: .leading, spacing: 10) {
                Text(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No tickets on the desk" : "No matching tickets")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Palette.primary)
                Text(emptyCopy)
                    .font(.system(.subheadline, design: .default))
                    .foregroundStyle(Palette.accent)
                if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button("Add city") {
                        showEditor = true
                    }
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .foregroundStyle(Palette.background)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Palette.primary)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var emptyCopy: String {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return "Try another city or country, or clear the search field."
        }
        switch store.filterPreference {
        case .all:
            return "Stamp a boarding pass to start a trip, then sort the suitcase and jot metro notes."
        case .planned:
            return "Nothing planned yet. Add a city or switch the filter to see visited trips."
        case .visited:
            return "No visited stamps yet. Open a ticket and mark the city when the trip is done."
        }
    }
}
