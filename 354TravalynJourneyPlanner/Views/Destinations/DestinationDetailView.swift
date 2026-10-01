import SwiftUI

struct DestinationDetailView: View {
    @EnvironmentObject private var store: AppStore
    let destinationId: UUID
    @State private var showEditor = false
    @State private var spentDraft = ""
    @State private var morningDraft = ""
    @State private var afternoonDraft = ""
    @State private var eveningDraft = ""
    @State private var residueDraft = ""

    var body: some View {
        Group {
            if let destination = store.destination(id: destinationId) {
                detail(for: destination)
            } else {
                missingTrip
            }
        }
        .deskBackdrop()
        .navigationTitle("Gate")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showEditor = true
                }
                .foregroundStyle(Palette.primary)
            }
        }
        .sheet(isPresented: $showEditor, onDismiss: hydrateDrafts) {
            DestinationEditorView(existingId: destinationId)
                .environmentObject(store)
        }
        .onAppear {
            hydrateDrafts()
        }
        .onChange(of: destinationId) { _ in
            hydrateDrafts()
        }
    }

    private func detail(for destination: Destination) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BannerStrip(imageName: "BannerMap", caption: "DEPARTURE DESK")
                TicketStubCard(destination: destination)
                    .padding(.horizontal, 16)
                if store.needsDepartureBrief(for: destination.id) {
                    departureBriefCard(destination)
                        .padding(.horizontal, 16)
                } else if destination.lastBriefDayKey == store.dayKey() {
                    DeskSurface {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("BRIEF CLEARED TODAY")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(Palette.accent)
                            Text(destination.briefResidue.isEmpty ? "Open loops parked until tomorrow’s brief." : "Residue: \(destination.briefResidue)")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(Palette.primary)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                visitStamp(destination)
                    .padding(.horizontal, 16)
                budgetCard(destination)
                    .padding(.horizontal, 16)
                dayPlanCard(destination)
                    .padding(.horizontal, 16)
                if destination.notes.isEmpty == false {
                    DeskSurface {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("TRIP NOTES")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(Palette.accent)
                            Text(destination.notes)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(Palette.primary)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                HStack(spacing: 12) {
                    NavigationLink {
                        PackingListView(destinationId: destination.id)
                    } label: {
                        actionLabel("Kit", symbol: "lock.rectangle.stack.fill")
                    }
                    .buttonStyle(.plain)
                    NavigationLink {
                        TransitGuideView(preferredCityId: destination.id)
                    } label: {
                        actionLabel("Lines", symbol: "tram.fill")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .clearScrollBackground()
        .onAppear {
            store.markTripEdited(destination.id)
            if residueDraft.isEmpty {
                residueDraft = destination.briefResidue
            }
        }
    }

    private func departureBriefCard(_ destination: Destination) -> some View {
        let loops = store.departureBriefLoops(for: destination.id)
        return DeskSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text("DEPARTURE BRIEF")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Palette.accent)
                Text("Open loops before you leave the gate")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Palette.primary)
                ForEach(loops.prefix(8)) { loop in
                    HStack(alignment: .top, spacing: 10) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Palette.primary)
                            .frame(width: 3, height: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loop.title)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(Palette.primary)
                            Text(loop.detail)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(Palette.accent)
                        }
                    }
                }
                DeskTextField(
                    placeholder: "Residue to carry (optional)",
                    text: $residueDraft,
                    autocapitalization: .sentences
                )
                Button("Clear brief for today") {
                    store.acknowledgeBrief(destinationId: destination.id, residue: residueDraft)
                    Haptics.confirm()
                }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Palette.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Palette.primary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private func visitStamp(_ destination: Destination) -> some View {
        DeskSurface {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(destination.visited ? "TRIP CLOSED" : "TRIP OPEN")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Palette.accent)
                    Text(destination.visited ? "Marked finished. Brief pauses for this rail." : "Keep open until you land and wrap the city.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Palette.primary)
                }
                Spacer()
                Button {
                    store.setVisited(destination.id, visited: destination.visited == false)
                    if destination.visited == false {
                        Haptics.confirm()
                    } else {
                        Haptics.tap()
                    }
                } label: {
                    Image(systemName: destination.visited ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(Palette.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(destination.visited ? "Mark as open" : "Mark finished")
            }
        }
    }

    private func budgetCard(_ destination: Destination) -> some View {
        let remaining = destination.budgetPlanned - destination.budgetSpent
        let ratio = destination.budgetPlanned > 0 ? min(1, max(0, destination.budgetSpent / destination.budgetPlanned)) : 0
        return DeskSurface {
            VStack(alignment: .leading, spacing: 10) {
                Text("SPEND RAIL")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Palette.accent)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Planned")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Palette.accent)
                        Text(TripFormat.money(destination.budgetPlanned, currency: destination.budgetCurrency))
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Palette.primary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Remaining")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Palette.accent)
                        Text(TripFormat.money(remaining, currency: destination.budgetCurrency))
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(remaining < 0 ? Palette.primary : Palette.accent)
                    }
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Palette.background.opacity(0.55))
                        Capsule()
                            .fill(Palette.primary)
                            .frame(width: geo.size.width * ratio)
                    }
                }
                .frame(height: 8)
                DeskTextField(
                    placeholder: "Spent so far",
                    text: $spentDraft,
                    autocapitalization: .never,
                    usesDecimalPad: true
                )
                Button("Update spent") {
                    store.updateBudgetSpent(id: destination.id, spent: TripFormat.amountValue(spentDraft))
                    Haptics.tap()
                }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Palette.background)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Palette.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private func dayPlanCard(_ destination: Destination) -> some View {
        DeskSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text("DAY BOARD")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Palette.accent)
                Text("Empty slots roll into Departure Brief.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Palette.primary)
                planSlot("Morning", text: $morningDraft, placeholder: "Market, museum opening, coffee")
                    .onChange(of: morningDraft) { value in
                        store.updateDayPlan(id: destination.id, morning: value)
                    }
                planSlot("Day", text: $afternoonDraft, placeholder: "Walk, lunch, neighborhood")
                    .onChange(of: afternoonDraft) { value in
                        store.updateDayPlan(id: destination.id, afternoon: value)
                    }
                planSlot("Evening", text: $eveningDraft, placeholder: "Dinner, show, night train")
                    .onChange(of: eveningDraft) { value in
                        store.updateDayPlan(id: destination.id, evening: value)
                    }
            }
        }
    }

    private func planSlot(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(Palette.accent)
            DeskNoteEditor(text: text, placeholder: placeholder, minHeight: 72)
        }
    }

    private func hydrateDrafts() {
        guard let destination = store.destination(id: destinationId) else {
            return
        }
        spentDraft = TripFormat.amountString(destination.budgetSpent)
        morningDraft = destination.planMorning
        afternoonDraft = destination.planAfternoon
        eveningDraft = destination.planEvening
        residueDraft = destination.briefResidue
    }

    private func actionLabel(_ title: String, symbol: String) -> some View {
        HStack {
            Image(systemName: symbol)
            Text(title)
                .font(.system(.headline, design: .rounded))
        }
        .foregroundStyle(Palette.background)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Palette.primary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var missingTrip: some View {
        VStack(spacing: 10) {
            Text("This trip is no longer on the board.")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Palette.primary)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}
