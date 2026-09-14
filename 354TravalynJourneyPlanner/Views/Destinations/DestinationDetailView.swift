import SwiftUI

struct DestinationDetailView: View {
    @EnvironmentObject private var store: AppStore
    let destinationId: UUID
    @State private var showEditor = false
    @State private var spentDraft = ""
    @State private var morningDraft = ""
    @State private var afternoonDraft = ""
    @State private var eveningDraft = ""

    var body: some View {
        Group {
            if let destination = store.destination(id: destinationId) {
                detail(for: destination)
            } else {
                missingTrip
            }
        }
        .deskBackdrop()
        .navigationTitle("Ticket")
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
                BannerStrip(imageName: "BannerMap", caption: "BOARDING DESK")
                TicketStubCard(destination: destination)
                    .padding(.horizontal, 16)
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
                                .font(.system(.body, design: .serif))
                                .foregroundStyle(Palette.primary)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                HStack(spacing: 12) {
                    NavigationLink {
                        PackingListView(destinationId: destination.id)
                    } label: {
                        actionLabel("Pack", symbol: "suitcase.fill")
                    }
                    .buttonStyle(.plain)
                    NavigationLink {
                        TransitGuideView(preferredCityId: destination.id)
                    } label: {
                        actionLabel("Transit", symbol: "tram.fill")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            store.markTripEdited(destination.id)
        }
    }

    private func visitStamp(_ destination: Destination) -> some View {
        DeskSurface {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(destination.visited ? "STAMPED" : "AWAITING STAMP")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Palette.accent)
                    Text(destination.visited ? "This city is marked visited." : "Mark visited when the trip wraps.")
                        .font(.system(.subheadline, design: .serif))
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
                .accessibilityLabel(destination.visited ? "Mark as planned" : "Mark visited")
            }
        }
    }

    private func budgetCard(_ destination: Destination) -> some View {
        let remaining = destination.budgetPlanned - destination.budgetSpent
        let ratio = destination.budgetPlanned > 0 ? min(1, max(0, destination.budgetSpent / destination.budgetPlanned)) : 0
        return DeskSurface {
            VStack(alignment: .leading, spacing: 10) {
                Text("LOCAL LEDGER")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Palette.accent)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Planned")
                            .font(.system(.caption, design: .serif))
                            .foregroundStyle(Palette.accent)
                        Text(TripFormat.money(destination.budgetPlanned, currency: destination.budgetCurrency))
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(Palette.primary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Remaining")
                            .font(.system(.caption, design: .serif))
                            .foregroundStyle(Palette.accent)
                        Text(TripFormat.money(remaining, currency: destination.budgetCurrency))
                            .font(.system(.headline, design: .serif))
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
                .font(.system(.subheadline, design: .serif).weight(.semibold))
                .foregroundStyle(Palette.background)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Palette.primary)
                .clipShape(Capsule())
            }
        }
    }

    private func dayPlanCard(_ destination: Destination) -> some View {
        DeskSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text("DAY BOARD")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Palette.accent)
                Text("Morning / day / evening notes for this city.")
                    .font(.system(.subheadline, design: .serif))
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
                .font(.system(.caption, design: .serif).weight(.semibold))
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
    }

    private func actionLabel(_ title: String, symbol: String) -> some View {
        HStack {
            Image(systemName: symbol)
            Text(title)
                .font(.system(.headline, design: .serif))
        }
        .foregroundStyle(Palette.background)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Palette.primary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var missingTrip: some View {
        VStack(spacing: 10) {
            Text("This ticket is no longer on the desk.")
                .font(.system(.headline, design: .serif))
                .foregroundStyle(Palette.primary)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}
