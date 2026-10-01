import Combine
import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published var destinations: [Destination] = []
    @Published var filterPreference: DestinationFilter = .all
    @Published var sortPreference: DestinationSort = .date
    @Published var categories: [PackCategory] = []
    @Published var items: [PackItem] = []
    @Published var lastEditedTripId: UUID?
    @Published var selectedCity: UUID?
    @Published var transitPreferences: [TransitPreference] = []
    @Published var customTransitNotes: [TransitNote] = []
    @Published var packingTemplates: [PackTemplate] = []
    @Published var frictionEvents: [FrictionEvent] = []
    @Published var remindersEnabled = false

    private let defaults: UserDefaults
    private var isHydrating = false

    private enum Keys {
        static let destinations = "destinations"
        static let filterPreference = "filterPreference"
        static let sortPreference = "sortPreference"
        static let categories = "categories"
        static let items = "items"
        static let lastEditedTripId = "lastEditedTripId"
        static let selectedCity = "selectedCity"
        static let transitPreferences = "transitPreferences"
        static let customTransitNotes = "customTransitNotes"
        static let packingTemplates = "packingTemplates"
        static let frictionEvents = "frictionEvents"
        static let remindersEnabled = "remindersEnabled"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isHydrating = true
        destinations = decode([Destination].self, key: Keys.destinations, fallback: [])
        filterPreference = decode(DestinationFilter.self, key: Keys.filterPreference, fallback: .all)
        sortPreference = decode(DestinationSort.self, key: Keys.sortPreference, fallback: .date)
        categories = decode([PackCategory].self, key: Keys.categories, fallback: [])
        items = decode([PackItem].self, key: Keys.items, fallback: [])
        lastEditedTripId = uuid(from: Keys.lastEditedTripId)
        selectedCity = uuid(from: Keys.selectedCity)
        transitPreferences = decode([TransitPreference].self, key: Keys.transitPreferences, fallback: [])
        customTransitNotes = decode([TransitNote].self, key: Keys.customTransitNotes, fallback: [])
        packingTemplates = decode([PackTemplate].self, key: Keys.packingTemplates, fallback: [])
        frictionEvents = decode([FrictionEvent].self, key: Keys.frictionEvents, fallback: [])
        remindersEnabled = defaults.bool(forKey: Keys.remindersEnabled)
        let seededTemplates = seedDefaultTemplateIfNeeded()
        isHydrating = false
        if seededTemplates {
            save()
        }
        if remindersEnabled {
            TripReminders.reschedule(destinations: destinations)
        }
    }

    func dayKey(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func departureBriefLoops(for destinationId: UUID) -> [BriefLoop] {
        var loops: [BriefLoop] = []
        guard let destination = destination(id: destinationId) else {
            return loops
        }
        let openPack = categories(for: destinationId).flatMap { category in
            items(for: category.id).filter { item in
                item.isComplete == false
            }
        }
        for item in openPack.prefix(6) {
            loops.append(
                BriefLoop(
                    id: "pack-\(item.id.uuidString)",
                    title: item.title,
                    detail: "Open kit item"
                )
            )
        }
        if destination.planMorning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            loops.append(BriefLoop(id: "plan-morning", title: "Morning slot empty", detail: "Day board"))
        }
        if destination.planAfternoon.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            loops.append(BriefLoop(id: "plan-day", title: "Day slot empty", detail: "Day board"))
        }
        if destination.planEvening.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            loops.append(BriefLoop(id: "plan-evening", title: "Evening slot empty", detail: "Day board"))
        }
        if destination.isKitSealed == false {
            loops.append(BriefLoop(id: "kit-seal", title: "Kit not sealed", detail: "Gate essentials"))
        }
        if destination.briefResidue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            loops.insert(
                BriefLoop(
                    id: "residue",
                    title: destination.briefResidue,
                    detail: "Carried residue"
                ),
                at: 0
            )
        }
        return loops
    }

    func needsDepartureBrief(for destinationId: UUID) -> Bool {
        guard let destination = destination(id: destinationId), destination.visited == false else {
            return false
        }
        if destination.lastBriefDayKey == dayKey() {
            return false
        }
        return departureBriefLoops(for: destinationId).isEmpty == false
    }

    func acknowledgeBrief(destinationId: UUID, residue: String) {
        guard let index = destinations.firstIndex(where: { item in
            item.id == destinationId
        }) else {
            return
        }
        destinations[index].lastBriefDayKey = dayKey()
        destinations[index].briefResidue = trimmed(residue)
        lastEditedTripId = destinationId
        save()
    }

    func isEssential(_ itemId: UUID, destinationId: UUID) -> Bool {
        guard let destination = destination(id: destinationId) else {
            return false
        }
        return destination.sealedEssentialIds.contains(itemId)
    }

    func toggleEssential(itemId: UUID, destinationId: UUID) {
        guard let index = destinations.firstIndex(where: { item in
            item.id == destinationId
        }) else {
            return
        }
        if destinations[index].isKitSealed {
            return
        }
        var ids = destinations[index].sealedEssentialIds
        if let existing = ids.firstIndex(of: itemId) {
            ids.remove(at: existing)
        } else {
            guard ids.count < 3 else {
                return
            }
            ids.append(itemId)
        }
        destinations[index].sealedEssentialIds = ids
        lastEditedTripId = destinationId
        save()
    }

    func sealKit(destinationId: UUID) {
        guard let index = destinations.firstIndex(where: { item in
            item.id == destinationId
        }) else {
            return
        }
        guard destinations[index].sealedEssentialIds.isEmpty == false else {
            return
        }
        destinations[index].kitSealedAt = Date()
        lastEditedTripId = destinationId
        save()
    }

    func unsealKit(destinationId: UUID) {
        guard let index = destinations.firstIndex(where: { item in
            item.id == destinationId
        }) else {
            return
        }
        destinations[index].kitSealedAt = nil
        lastEditedTripId = destinationId
        save()
    }

    func frictionEvents(for destinationId: UUID) -> [FrictionEvent] {
        frictionEvents
            .filter { event in
                event.destinationId == destinationId
            }
            .sorted { lhs, rhs in
                lhs.createdAt > rhs.createdAt
            }
    }

    func addFriction(destinationId: UUID, kind: FrictionKind, note: String) {
        frictionEvents.append(
            FrictionEvent(
                id: UUID(),
                destinationId: destinationId,
                kind: kind,
                note: trimmed(note),
                createdAt: Date()
            )
        )
        selectedCity = destinationId
        save()
    }

    func deleteFriction(_ id: UUID) {
        frictionEvents.removeAll { event in
            event.id == id
        }
        save()
    }

    func frictionCounts() -> [(kind: FrictionKind, count: Int)] {
        FrictionKind.allCases.compactMap { kind in
            let count = frictionEvents.filter { event in
                event.kind == kind
            }.count
            return count > 0 ? (kind, count) : nil
        }
        .sorted { lhs, rhs in
            lhs.count > rhs.count
        }
    }

    func dominantFriction() -> FrictionKind? {
        frictionCounts().first?.kind
    }

    func visibleDestinations(search: String = "") -> [Destination] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var list = destinations
        switch filterPreference {
        case .all:
            break
        case .planned:
            list = list.filter { destination in
                destination.visited == false
            }
        case .visited:
            list = list.filter { destination in
                destination.visited
            }
        }
        if query.isEmpty == false {
            list = list.filter { destination in
                destination.city.lowercased().contains(query) || destination.country.lowercased().contains(query)
            }
        }
        list.sort { lhs, rhs in
            switch sortPreference {
            case .date:
                if lhs.startDate == rhs.startDate {
                    return lhs.city.localizedCaseInsensitiveCompare(rhs.city) == .orderedAscending
                }
                return lhs.startDate < rhs.startDate
            case .city:
                return lhs.city.localizedCaseInsensitiveCompare(rhs.city) == .orderedAscending
            case .country:
                let countryOrder = lhs.country.localizedCaseInsensitiveCompare(rhs.country)
                if countryOrder != .orderedSame {
                    return countryOrder == .orderedAscending
                }
                return lhs.city.localizedCaseInsensitiveCompare(rhs.city) == .orderedAscending
            }
        }
        return list
    }

    func nextUpcomingTrip() -> Destination? {
        let today = Calendar.current.startOfDay(for: Date())
        return destinations
            .filter { destination in
                destination.visited == false && Calendar.current.startOfDay(for: destination.endDate) >= today
            }
            .sorted { lhs, rhs in
                lhs.startDate < rhs.startDate
            }
            .first
    }

    func packingProgress(for destinationId: UUID) -> (done: Int, total: Int) {
        let categoryIds = Set(categories(for: destinationId).map(\.id))
        let cityItems = items.filter { item in
            categoryIds.contains(item.categoryId)
        }
        return (cityItems.filter(\.isComplete).count, cityItems.count)
    }

    func destination(id: UUID) -> Destination? {
        destinations.first { item in
            item.id == id
        }
    }

    func hasMatchingCity(_ city: String, country: String, excluding id: UUID?) -> Bool {
        let cityKey = normalized(city)
        let countryKey = normalized(country)
        return destinations.contains { destination in
            if let id, destination.id == id {
                return false
            }
            return normalized(destination.city) == cityKey && normalized(destination.country) == countryKey
        }
    }

    func addDestination(
        city: String,
        country: String,
        notes: String,
        startDate: Date,
        endDate: Date,
        budgetCurrency: String,
        budgetPlanned: Double
    ) -> UUID {
        let destination = Destination(
            id: UUID(),
            city: trimmed(city),
            country: trimmed(country),
            notes: trimmed(notes),
            startDate: startDate,
            endDate: max(startDate, endDate),
            visited: false,
            budgetCurrency: budgetCurrency,
            budgetPlanned: budgetPlanned
        )
        destinations.append(destination)
        seedStarterCategories(for: destination.id)
        lastEditedTripId = destination.id
        if selectedCity == nil {
            selectedCity = destination.id
        }
        save()
        syncReminders(for: destination)
        return destination.id
    }

    func updateDestination(_ destination: Destination) {
        guard let index = destinations.firstIndex(where: { item in
            item.id == destination.id
        }) else {
            return
        }
        destinations[index] = destination
        lastEditedTripId = destination.id
        save()
        syncReminders(for: destination)
    }

    func deleteDestination(_ id: UUID) {
        destinations.removeAll { item in
            item.id == id
        }
        let categoryIds = categories.compactMap { category in
            category.destinationId == id ? category.id : nil
        }
        categories.removeAll { category in
            category.destinationId == id
        }
        items.removeAll { item in
            categoryIds.contains(item.categoryId)
        }
        transitPreferences.removeAll { preference in
            preference.destinationId == id
        }
        customTransitNotes.removeAll { note in
            note.destinationId == id
        }
        frictionEvents.removeAll { event in
            event.destinationId == id
        }
        if lastEditedTripId == id {
            lastEditedTripId = nil
        }
        if selectedCity == id {
            selectedCity = destinations.first?.id
        }
        TripReminders.cancel(for: id)
        save()
    }

    func setVisited(_ id: UUID, visited: Bool) {
        guard let index = destinations.firstIndex(where: { item in
            item.id == id
        }) else {
            return
        }
        destinations[index].visited = visited
        lastEditedTripId = id
        save()
        if let destination = destination(id: id) {
            syncReminders(for: destination)
        }
    }

    func setFilter(_ filter: DestinationFilter) {
        filterPreference = filter
        save()
    }

    func setSort(_ sort: DestinationSort) {
        sortPreference = sort
        save()
    }

    func setRemindersEnabled(_ enabled: Bool) {
        remindersEnabled = enabled
        save()
        if enabled {
            TripReminders.requestAccess { granted in
                if granted {
                    TripReminders.reschedule(destinations: self.destinations)
                } else {
                    self.remindersEnabled = false
                    self.save()
                }
            }
        } else {
            TripReminders.cancelAll()
        }
    }

    func updateDayPlan(id: UUID, morning: String? = nil, afternoon: String? = nil, evening: String? = nil) {
        guard let index = destinations.firstIndex(where: { item in
            item.id == id
        }) else {
            return
        }
        if let morning {
            destinations[index].planMorning = morning
        }
        if let afternoon {
            destinations[index].planAfternoon = afternoon
        }
        if let evening {
            destinations[index].planEvening = evening
        }
        lastEditedTripId = id
        save()
    }

    func updateBudgetSpent(id: UUID, spent: Double) {
        guard let index = destinations.firstIndex(where: { item in
            item.id == id
        }) else {
            return
        }
        destinations[index].budgetSpent = max(0, spent)
        lastEditedTripId = id
        save()
    }

    func selectCity(_ id: UUID?) {
        selectedCity = id
        save()
    }

    func markTripEdited(_ id: UUID) {
        lastEditedTripId = id
        save()
    }

    func categories(for destinationId: UUID) -> [PackCategory] {
        categories
            .filter { category in
                category.destinationId == destinationId
            }
            .sorted { lhs, rhs in
                lhs.sortIndex < rhs.sortIndex
            }
    }

    func items(for categoryId: UUID) -> [PackItem] {
        items
            .filter { item in
                item.categoryId == categoryId
            }
            .sorted { lhs, rhs in
                lhs.sortIndex < rhs.sortIndex
            }
    }

    func addCategory(destinationId: UUID, title: String) {
        let nextIndex = (categories(for: destinationId).map(\.sortIndex).max() ?? -1) + 1
        let category = PackCategory(
            id: UUID(),
            destinationId: destinationId,
            title: trimmed(title),
            sortIndex: nextIndex
        )
        categories.append(category)
        lastEditedTripId = destinationId
        save()
    }

    func updateCategory(_ category: PackCategory) {
        guard let index = categories.firstIndex(where: { item in
            item.id == category.id
        }) else {
            return
        }
        categories[index] = category
        lastEditedTripId = category.destinationId
        save()
    }

    func deleteCategory(_ id: UUID) {
        guard let category = categories.first(where: { item in
            item.id == id
        }) else {
            return
        }
        categories.removeAll { item in
            item.id == id
        }
        items.removeAll { item in
            item.categoryId == id
        }
        lastEditedTripId = category.destinationId
        save()
    }

    func moveCategory(_ id: UUID, up: Bool) {
        guard let category = categories.first(where: { item in
            item.id == id
        }) else {
            return
        }
        var slice = categories(for: category.destinationId)
        guard let index = slice.firstIndex(where: { item in
            item.id == id
        }) else {
            return
        }
        let swapIndex = up ? index - 1 : index + 1
        guard slice.indices.contains(swapIndex) else {
            return
        }
        slice.swapAt(index, swapIndex)
        reindex(categories: slice)
        lastEditedTripId = category.destinationId
        save()
    }

    func addItem(categoryId: UUID, title: String) {
        guard let category = categories.first(where: { item in
            item.id == categoryId
        }) else {
            return
        }
        let nextIndex = (items(for: categoryId).map(\.sortIndex).max() ?? -1) + 1
        let item = PackItem(
            id: UUID(),
            categoryId: categoryId,
            title: trimmed(title),
            isComplete: false,
            sortIndex: nextIndex
        )
        items.append(item)
        lastEditedTripId = category.destinationId
        save()
    }

    func updateItem(_ item: PackItem) {
        guard let index = items.firstIndex(where: { existing in
            existing.id == item.id
        }) else {
            return
        }
        items[index] = item
        if let category = categories.first(where: { category in
            category.id == item.categoryId
        }) {
            lastEditedTripId = category.destinationId
        }
        save()
    }

    func toggleItem(_ id: UUID) {
        guard let index = items.firstIndex(where: { item in
            item.id == id
        }) else {
            return
        }
        if let category = categories.first(where: { category in
            category.id == items[index].categoryId
        }), let destination = destination(id: category.destinationId), destination.isKitSealed,
           destination.sealedEssentialIds.contains(id), items[index].isComplete {
            return
        }
        items[index].isComplete.toggle()
        if let category = categories.first(where: { category in
            category.id == items[index].categoryId
        }) {
            lastEditedTripId = category.destinationId
        }
        save()
    }

    func deleteItem(_ id: UUID) {
        guard let item = items.first(where: { existing in
            existing.id == id
        }) else {
            return
        }
        items.removeAll { existing in
            existing.id == id
        }
        if let category = categories.first(where: { category in
            category.id == item.categoryId
        }) {
            if let destIndex = destinations.firstIndex(where: { destination in
                destination.id == category.destinationId
            }) {
                destinations[destIndex].sealedEssentialIds.removeAll { sealed in
                    sealed == id
                }
            }
            lastEditedTripId = category.destinationId
        }
        save()
    }

    func moveItem(_ id: UUID, up: Bool) {
        guard let item = items.first(where: { existing in
            existing.id == id
        }) else {
            return
        }
        var slice = items(for: item.categoryId)
        guard let index = slice.firstIndex(where: { existing in
            existing.id == id
        }) else {
            return
        }
        let swapIndex = up ? index - 1 : index + 1
        guard slice.indices.contains(swapIndex) else {
            return
        }
        slice.swapAt(index, swapIndex)
        reindex(items: slice)
        if let category = categories.first(where: { category in
            category.id == item.categoryId
        }) {
            lastEditedTripId = category.destinationId
        }
        save()
    }

    func preference(for destinationId: UUID) -> TransitPreference {
        if let existing = transitPreferences.first(where: { preference in
            preference.destinationId == destinationId
        }) {
            return existing
        }
        return TransitPreference(
            id: UUID(),
            destinationId: destinationId,
            usesMetro: false,
            usesTaxi: false,
            usesRental: false
        )
    }

    func setPreference(destinationId: UUID, metro: Bool? = nil, taxi: Bool? = nil, rental: Bool? = nil) {
        if let index = transitPreferences.firstIndex(where: { preference in
            preference.destinationId == destinationId
        }) {
            if let metro {
                transitPreferences[index].usesMetro = metro
            }
            if let taxi {
                transitPreferences[index].usesTaxi = taxi
            }
            if let rental {
                transitPreferences[index].usesRental = rental
            }
        } else {
            let preference = TransitPreference(
                id: UUID(),
                destinationId: destinationId,
                usesMetro: metro ?? false,
                usesTaxi: taxi ?? false,
                usesRental: rental ?? false
            )
            transitPreferences.append(preference)
        }
        selectedCity = destinationId
        save()
    }

    func noteText(for destinationId: UUID) -> String {
        customTransitNotes.first(where: { note in
            note.destinationId == destinationId
        })?.body ?? ""
    }

    func updateNote(destinationId: UUID, body: String) {
        if let index = customTransitNotes.firstIndex(where: { note in
            note.destinationId == destinationId
        }) {
            customTransitNotes[index].body = body
            customTransitNotes[index].updatedAt = Date()
        } else {
            let note = TransitNote(
                id: UUID(),
                destinationId: destinationId,
                body: body,
                updatedAt: Date()
            )
            customTransitNotes.append(note)
        }
        selectedCity = destinationId
        save()
    }

    func saveTemplate(from destinationId: UUID, title: String) {
        let name = trimmed(title)
        guard name.isEmpty == false else {
            return
        }
        packingTemplates.append(
            PackTemplate(
                id: UUID(),
                title: name,
                categories: snapshot(for: destinationId)
            )
        )
        save()
    }

    func deleteTemplate(_ id: UUID) {
        packingTemplates.removeAll { template in
            template.id == id
        }
        save()
    }

    func applyTemplate(_ id: UUID, to destinationId: UUID) {
        guard let template = packingTemplates.first(where: { item in
            item.id == id
        }) else {
            return
        }
        replacePacking(destinationId: destinationId, categories: template.categories)
    }

    func copyPacking(from sourceId: UUID, to destinationId: UUID) {
        guard sourceId != destinationId else {
            return
        }
        replacePacking(destinationId: destinationId, categories: snapshot(for: sourceId))
    }

    func resetAllData() {
        destinations = []
        filterPreference = .all
        sortPreference = .date
        categories = []
        items = []
        lastEditedTripId = nil
        selectedCity = nil
        transitPreferences = []
        customTransitNotes = []
        packingTemplates = []
        frictionEvents = []
        remindersEnabled = false
        defaults.set(false, forKey: "didSeedPackTemplates")
        _ = seedDefaultTemplateIfNeeded()
        TripReminders.cancelAll()
        save()
        NotificationCenter.default.post(name: Notification.Name("dataReset"), object: nil)
    }

    func reloadFromDisk() {
        isHydrating = true
        destinations = decode([Destination].self, key: Keys.destinations, fallback: [])
        filterPreference = decode(DestinationFilter.self, key: Keys.filterPreference, fallback: .all)
        sortPreference = decode(DestinationSort.self, key: Keys.sortPreference, fallback: .date)
        categories = decode([PackCategory].self, key: Keys.categories, fallback: [])
        items = decode([PackItem].self, key: Keys.items, fallback: [])
        lastEditedTripId = uuid(from: Keys.lastEditedTripId)
        selectedCity = uuid(from: Keys.selectedCity)
        transitPreferences = decode([TransitPreference].self, key: Keys.transitPreferences, fallback: [])
        customTransitNotes = decode([TransitNote].self, key: Keys.customTransitNotes, fallback: [])
        packingTemplates = decode([PackTemplate].self, key: Keys.packingTemplates, fallback: [])
        frictionEvents = decode([FrictionEvent].self, key: Keys.frictionEvents, fallback: [])
        remindersEnabled = defaults.bool(forKey: Keys.remindersEnabled)
        isHydrating = false
    }

    private func seedStarterCategories(for destinationId: UUID) {
        let titles = ["Documents", "Carry", "Wear"]
        for (index, title) in titles.enumerated() {
            let category = PackCategory(
                id: UUID(),
                destinationId: destinationId,
                title: title,
                sortIndex: index
            )
            categories.append(category)
        }
    }

    private func reindex(categories slice: [PackCategory]) {
        for (index, category) in slice.enumerated() {
            if let stored = categories.firstIndex(where: { item in
                item.id == category.id
            }) {
                categories[stored].sortIndex = index
            }
        }
    }

    private func reindex(items slice: [PackItem]) {
        for (index, item) in slice.enumerated() {
            if let stored = items.firstIndex(where: { existing in
                existing.id == item.id
            }) {
                items[stored].sortIndex = index
            }
        }
    }

    private func save() {
        guard isHydrating == false else {
            return
        }
        encode(destinations, key: Keys.destinations)
        encode(filterPreference, key: Keys.filterPreference)
        encode(categories, key: Keys.categories)
        encode(items, key: Keys.items)
        encode(transitPreferences, key: Keys.transitPreferences)
        encode(customTransitNotes, key: Keys.customTransitNotes)
        encode(packingTemplates, key: Keys.packingTemplates)
        encode(frictionEvents, key: Keys.frictionEvents)
        encode(sortPreference, key: Keys.sortPreference)
        defaults.set(remindersEnabled, forKey: Keys.remindersEnabled)
        write(uuid: lastEditedTripId, key: Keys.lastEditedTripId)
        write(uuid: selectedCity, key: Keys.selectedCity)
    }

    private func syncReminders(for destination: Destination) {
        if remindersEnabled {
            TripReminders.schedule(for: destination)
        } else {
            TripReminders.cancel(for: destination.id)
        }
    }

    private func snapshot(for destinationId: UUID) -> [PackTemplateCategory] {
        categories(for: destinationId).map { category in
            PackTemplateCategory(
                title: category.title,
                items: items(for: category.id).map(\.title)
            )
        }
    }

    private func replacePacking(destinationId: UUID, categories snapshot: [PackTemplateCategory]) {
        let existingIds = Set(categories(for: destinationId).map(\.id))
        items.removeAll { item in
            existingIds.contains(item.categoryId)
        }
        categories.removeAll { category in
            category.destinationId == destinationId
        }
        for (index, block) in snapshot.enumerated() {
            let category = PackCategory(
                id: UUID(),
                destinationId: destinationId,
                title: trimmed(block.title),
                sortIndex: index
            )
            categories.append(category)
            for (itemIndex, title) in block.items.enumerated() {
                items.append(
                    PackItem(
                        id: UUID(),
                        categoryId: category.id,
                        title: trimmed(title),
                        isComplete: false,
                        sortIndex: itemIndex
                    )
                )
            }
        }
        lastEditedTripId = destinationId
        if let destIndex = destinations.firstIndex(where: { destination in
            destination.id == destinationId
        }) {
            destinations[destIndex].kitSealedAt = nil
            destinations[destIndex].sealedEssentialIds = []
        }
        save()
    }

    private func seedDefaultTemplateIfNeeded() -> Bool {
        if defaults.bool(forKey: "didSeedPackTemplates") {
            return false
        }
        if packingTemplates.isEmpty {
            packingTemplates = [
                PackTemplate(
                    id: UUID(),
                    title: "Gate essentials",
                    categories: [
                        PackTemplateCategory(title: "Documents", items: ["Passport", "Boarding QR", "Insurance"]),
                        PackTemplateCategory(title: "Carry", items: ["Phone charger", "Adapter", "Cash float"]),
                        PackTemplateCategory(title: "Wear", items: ["Day layer", "Walk shoes", "Weather shell"])
                    ]
                )
            ]
        }
        defaults.set(true, forKey: "didSeedPackTemplates")
        return packingTemplates.isEmpty == false
    }

    private func encode<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, key: String, fallback: T) -> T {
        guard let data = defaults.data(forKey: key) else {
            return fallback
        }
        if let value = try? JSONDecoder().decode(type, from: data) {
            return value
        }
        return fallback
    }

    private func uuid(from key: String) -> UUID? {
        guard let raw = defaults.string(forKey: key) else {
            return nil
        }
        return UUID(uuidString: raw)
    }

    private func write(uuid: UUID?, key: String) {
        if let uuid {
            defaults.set(uuid.uuidString, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalized(_ value: String) -> String {
        trimmed(value).lowercased()
    }
}
