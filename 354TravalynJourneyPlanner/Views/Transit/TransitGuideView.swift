import SwiftUI

struct TransitGuideView: View {
    @EnvironmentObject private var store: AppStore
    let preferredCityId: UUID?

    @State private var noteDraft = ""

    var body: some View {
        Group {
            if store.destinations.isEmpty {
                emptyState
            } else {
                guideDesk
            }
        }
        .deskBackdrop()
        .navigationTitle("Transit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            activatePreferredCity()
            syncDraft()
        }
        .onChange(of: store.selectedCity) { _ in
            syncDraft()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dataReset"))) { _ in
            noteDraft = ""
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            BannerStrip(imageName: "BannerMetro", caption: "LINE MAP")
            DeskSurface {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No cities on the line")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(Palette.primary)
                    Text("Add a city from Destinations to keep metro, taxi, and rental notes for that ticket.")
                        .font(.system(.subheadline, design: .default))
                        .foregroundStyle(Palette.accent)
                }
            }
            .padding(.horizontal, 16)
            Spacer()
        }
    }

    private var guideDesk: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BannerStrip(imageName: "BannerMetro", caption: "CITY TRANSIT")
                cityPicker
                    .padding(.horizontal, 16)
                if let city = activeDestination {
                    modeBoard(for: city)
                        .padding(.horizontal, 16)
                    notesForm(for: city)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 28)
                }
            }
        }
    }

    private var cityPicker: some View {
        DeskSurface {
            VStack(alignment: .leading, spacing: 8) {
                Text("SAVED CITY")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Palette.accent)
                Picker("City", selection: Binding(
                    get: { store.selectedCity ?? activeDestination?.id },
                    set: { value in
                        store.selectCity(value)
                    }
                )) {
                    ForEach(sortedCities) { destination in
                        Text(destination.city + ", " + destination.country)
                            .tag(Optional(destination.id))
                    }
                }
                .pickerStyle(.menu)
                .tint(Palette.primary)
            }
        }
    }

    private func modeBoard(for destination: Destination) -> some View {
        let preference = store.preference(for: destination.id)
        return DeskSurface {
            VStack(alignment: .leading, spacing: 8) {
                Text("LINE CHOICES")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Palette.accent)
                Text(destination.city)
                    .font(.system(.title3, design: .serif).weight(.semibold))
                    .foregroundStyle(Palette.primary)
                MetroLineRow(
                    title: "Metro",
                    subtitle: "Stations, transfers, late trains",
                    isOn: preference.usesMetro,
                    onChange: { value in
                        store.setPreference(destinationId: destination.id, metro: value)
                    }
                )
                MetroLineRow(
                    title: "Taxi",
                    subtitle: "Ranks, late-night stands, receipts",
                    isOn: preference.usesTaxi,
                    onChange: { value in
                        store.setPreference(destinationId: destination.id, taxi: value)
                    }
                )
                MetroLineRow(
                    title: "Rental",
                    subtitle: "Desk hours, fuel, parking notes",
                    isOn: preference.usesRental,
                    onChange: { value in
                        store.setPreference(destinationId: destination.id, rental: value)
                    }
                )
            }
        }
    }

    private func notesForm(for destination: Destination) -> some View {
        DeskSurface {
            VStack(alignment: .leading, spacing: 10) {
                Text("CUSTOM NOTES")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Palette.accent)
                Text("Local transit memo for this city")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Palette.primary)
                DeskNoteEditor(
                    text: $noteDraft,
                    placeholder: "Stations, transfers, taxi ranks, rental desk hours",
                    minHeight: 140
                )
                .onChange(of: noteDraft) { newValue in
                    store.updateNote(destinationId: destination.id, body: newValue)
                }
            }
        }
    }

    private var sortedCities: [Destination] {
        store.destinations.sorted { lhs, rhs in
            lhs.city.localizedCaseInsensitiveCompare(rhs.city) == .orderedAscending
        }
    }

    private var activeDestination: Destination? {
        if let selected = store.selectedCity, let found = store.destination(id: selected) {
            return found
        }
        return sortedCities.first
    }

    private func activatePreferredCity() {
        if let preferredCityId, store.destination(id: preferredCityId) != nil {
            store.selectCity(preferredCityId)
            return
        }
        if let selected = store.selectedCity, store.destination(id: selected) != nil {
            return
        }
        store.selectCity(sortedCities.first?.id)
    }

    private func syncDraft() {
        if let city = activeDestination {
            noteDraft = store.noteText(for: city.id)
        } else {
            noteDraft = ""
        }
    }
}
