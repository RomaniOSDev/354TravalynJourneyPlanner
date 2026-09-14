import SwiftUI

struct DestinationEditorView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let existingId: UUID?

    @State private var city = ""
    @State private var country = ""
    @State private var notes = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var budgetCurrency = "EUR"
    @State private var plannedText = ""
    @State private var spentText = ""
    @State private var showDuplicateConfirm = false
    @State private var showValidation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    BannerStrip(imageName: "BannerMap", caption: existingId == nil ? "NEW TICKET" : "REISSUE TICKET")
                    DeskSurface {
                        VStack(alignment: .leading, spacing: 14) {
                            labeledField("City", placeholder: "Lisbon", text: $city)
                            labeledField("Country", placeholder: "Portugal", text: $country)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes")
                                    .font(.system(.caption, design: .serif).weight(.semibold))
                                    .foregroundStyle(Palette.accent)
                                DeskNoteEditor(
                                    text: $notes,
                                    placeholder: "Neighborhoods, reservations, reminders"
                                )
                            }
                            DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                                .font(.system(.subheadline, design: .serif))
                                .foregroundStyle(Palette.primary)
                                .tint(Palette.primary)
                                .onChange(of: startDate) { newValue in
                                    if endDate < newValue {
                                        endDate = newValue
                                    }
                                }
                            DatePicker("End date", selection: $endDate, displayedComponents: .date)
                                .font(.system(.subheadline, design: .serif))
                                .foregroundStyle(Palette.primary)
                                .tint(Palette.primary)
                                .onChange(of: endDate) { newValue in
                                    if newValue < startDate {
                                        startDate = newValue
                                    }
                                }
                            if showValidation {
                                Text("City and country are required.")
                                    .font(.system(.caption, design: .serif))
                                    .foregroundStyle(Palette.accent)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    DeskSurface {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("TRIP BUDGET")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(Palette.accent)
                            Picker("Currency", selection: $budgetCurrency) {
                                ForEach(TripCurrency.allCases) { currency in
                                    Text(currency.rawValue).tag(currency.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Palette.primary)
                            labeledField("Planned", placeholder: "1200", text: $plannedText)
                            labeledField("Spent", placeholder: "0", text: $spentText)
                        }
                    }
                    .padding(.horizontal, 16)
                    if existingId != nil {
                        Button("Delete city", role: .destructive) {
                            if let existingId {
                                store.deleteDestination(existingId)
                                dismiss()
                            }
                        }
                        .font(.system(.subheadline, design: .serif).weight(.semibold))
                        .foregroundStyle(Palette.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 24)
            }
            .deskBackdrop()
            .navigationTitle(existingId == nil ? "Add city" : "Edit city")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(Palette.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        attemptSave(forceDuplicate: false)
                    }
                    .foregroundStyle(Palette.primary)
                }
            }
            .onAppear(perform: hydrate)
            .alert("Duplicate city", isPresented: $showDuplicateConfirm) {
                Button("Add anyway") {
                    attemptSave(forceDuplicate: true)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("A trip to \(trimmed(city)), \(trimmed(country)) is already on the desk. Add another boarding pass?")
            }
        }
    }

    private func labeledField(_ title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.caption, design: .serif).weight(.semibold))
                .foregroundStyle(Palette.accent)
            DeskTextField(
                placeholder: placeholder,
                text: text,
                autocapitalization: title == "Planned" || title == "Spent" ? .never : .words,
                usesDecimalPad: title == "Planned" || title == "Spent"
            )
        }
    }

    private func hydrate() {
        guard let existingId, let destination = store.destination(id: existingId) else {
            return
        }
        city = destination.city
        country = destination.country
        notes = destination.notes
        startDate = destination.startDate
        endDate = destination.endDate
        budgetCurrency = destination.budgetCurrency
        plannedText = TripFormat.amountString(destination.budgetPlanned)
        spentText = TripFormat.amountString(destination.budgetSpent)
    }

    private func attemptSave(forceDuplicate: Bool) {
        let cityValue = trimmed(city)
        let countryValue = trimmed(country)
        if cityValue.isEmpty || countryValue.isEmpty {
            showValidation = true
            return
        }
        showValidation = false
        if forceDuplicate == false && store.hasMatchingCity(cityValue, country: countryValue, excluding: existingId) {
            showDuplicateConfirm = true
            return
        }
        let planned = TripFormat.amountValue(plannedText)
        let spent = TripFormat.amountValue(spentText)
        let tripEnd = max(startDate, endDate)
        if let existingId, var destination = store.destination(id: existingId) {
            destination.city = cityValue
            destination.country = countryValue
            destination.notes = trimmed(notes)
            destination.startDate = min(startDate, tripEnd)
            destination.endDate = tripEnd
            destination.budgetCurrency = budgetCurrency
            destination.budgetPlanned = planned
            destination.budgetSpent = spent
            store.updateDestination(destination)
        } else {
            let id = store.addDestination(
                city: cityValue,
                country: countryValue,
                notes: trimmed(notes),
                startDate: min(startDate, tripEnd),
                endDate: tripEnd,
                budgetCurrency: budgetCurrency,
                budgetPlanned: planned
            )
            if spent > 0 {
                store.updateBudgetSpent(id: id, spent: spent)
            }
        }
        dismiss()
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
