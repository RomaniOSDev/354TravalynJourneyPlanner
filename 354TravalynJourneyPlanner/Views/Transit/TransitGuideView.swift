import SwiftUI

struct TransitGuideView: View {
    @EnvironmentObject private var store: AppStore
    let preferredCityId: UUID?

    @State private var noteDraft = ""
    @State private var selectedKind: FrictionKind = .crowded
    @State private var frictionNote = ""

    var body: some View {
        Group {
            if store.destinations.isEmpty {
                emptyState
            } else {
                guideDesk
            }
        }
        .deskBackdrop()
        .navigationTitle("Lines")
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
            frictionNote = ""
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            BannerStrip(imageName: "BannerMetro", caption: "FRICTION LINES")
            DeskSurface {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No trips on the line")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Palette.primary)
                    Text("Add a trip from Board, then log metro / taxi / rental choices and transit friction tags.")
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
                BannerStrip(imageName: "BannerMetro", caption: "TRANSIT FRICTION")
                cityPicker
                    .padding(.horizontal, 16)
                if let city = activeDestination {
                    modeBoard(for: city)
                        .padding(.horizontal, 16)
                    frictionBoard(for: city)
                        .padding(.horizontal, 16)
                    notesForm(for: city)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 28)
                }
            }
        }
        .clearScrollBackground()
    }

    private var cityPicker: some View {
        DeskSurface {
            VStack(alignment: .leading, spacing: 8) {
                Text("ACTIVE TRIP")
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
                    .font(.system(.title3, design: .rounded).weight(.bold))
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

    private func frictionBoard(for destination: Destination) -> some View {
        let events = store.frictionEvents(for: destination.id)
        return DeskSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text("FRICTION TAG")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Palette.accent)
                Text("Log what stalled you on the lines. Pulse uses these tags.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Palette.primary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(FrictionKind.allCases) { kind in
                            Button {
                                selectedKind = kind
                            } label: {
                                Text(kind.title)
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                                    .foregroundStyle(selectedKind == kind ? Palette.background : Palette.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedKind == kind ? Palette.primary : Palette.background.opacity(0.4))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                DeskTextField(
                    placeholder: "Optional note",
                    text: $frictionNote,
                    autocapitalization: .sentences
                )
                Button("Log friction") {
                    store.addFriction(destinationId: destination.id, kind: selectedKind, note: frictionNote)
                    frictionNote = ""
                    Haptics.confirm()
                }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Palette.background)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Palette.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                if events.isEmpty {
                    Text("No friction logged for this trip yet.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Palette.accent)
                } else {
                    ForEach(events.prefix(8)) { event in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.kind.title)
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(Palette.primary)
                                if event.note.isEmpty == false {
                                    Text(event.note)
                                        .font(.system(.caption, design: .default))
                                        .foregroundStyle(Palette.accent)
                                }
                            }
                            Spacer()
                            Button("Remove") {
                                store.deleteFriction(event.id)
                            }
                            .font(.system(.caption2, design: .rounded).weight(.semibold))
                            .foregroundStyle(Palette.accent)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private func notesForm(for destination: Destination) -> some View {
        DeskSurface {
            VStack(alignment: .leading, spacing: 10) {
                Text("LINE MEMO")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Palette.accent)
                Text("Local transit memo for this city")
                    .font(.system(.headline, design: .rounded))
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
