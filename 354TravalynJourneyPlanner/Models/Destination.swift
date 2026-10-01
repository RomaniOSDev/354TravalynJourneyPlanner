import Foundation

struct Destination: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var city: String
    var country: String
    var notes: String
    var startDate: Date
    var endDate: Date
    var visited: Bool
    var budgetCurrency: String
    var budgetPlanned: Double
    var budgetSpent: Double
    var planMorning: String
    var planAfternoon: String
    var planEvening: String
    var kitSealedAt: Date?
    var sealedEssentialIds: [UUID]
    var lastBriefDayKey: String?
    var briefResidue: String

    init(
        id: UUID,
        city: String,
        country: String,
        notes: String,
        startDate: Date,
        endDate: Date,
        visited: Bool,
        budgetCurrency: String = "EUR",
        budgetPlanned: Double = 0,
        budgetSpent: Double = 0,
        planMorning: String = "",
        planAfternoon: String = "",
        planEvening: String = "",
        kitSealedAt: Date? = nil,
        sealedEssentialIds: [UUID] = [],
        lastBriefDayKey: String? = nil,
        briefResidue: String = ""
    ) {
        self.id = id
        self.city = city
        self.country = country
        self.notes = notes
        self.startDate = startDate
        self.endDate = endDate
        self.visited = visited
        self.budgetCurrency = budgetCurrency
        self.budgetPlanned = budgetPlanned
        self.budgetSpent = budgetSpent
        self.planMorning = planMorning
        self.planAfternoon = planAfternoon
        self.planEvening = planEvening
        self.kitSealedAt = kitSealedAt
        self.sealedEssentialIds = sealedEssentialIds
        self.lastBriefDayKey = lastBriefDayKey
        self.briefResidue = briefResidue
    }

    var isKitSealed: Bool {
        kitSealedAt != nil
    }

    private enum CodingKeys: String, CodingKey {
        case id, city, country, notes, startDate, endDate, visited
        case plannedDate
        case budgetCurrency, budgetPlanned, budgetSpent
        case planMorning, planAfternoon, planEvening
        case kitSealedAt, sealedEssentialIds, lastBriefDayKey, briefResidue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        city = try container.decode(String.self, forKey: .city)
        country = try container.decode(String.self, forKey: .country)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        if let start = try container.decodeIfPresent(Date.self, forKey: .startDate) {
            startDate = start
        } else {
            startDate = try container.decodeIfPresent(Date.self, forKey: .plannedDate) ?? Date()
        }
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate) ?? startDate
        visited = try container.decodeIfPresent(Bool.self, forKey: .visited) ?? false
        budgetCurrency = try container.decodeIfPresent(String.self, forKey: .budgetCurrency) ?? "EUR"
        budgetPlanned = try container.decodeIfPresent(Double.self, forKey: .budgetPlanned) ?? 0
        budgetSpent = try container.decodeIfPresent(Double.self, forKey: .budgetSpent) ?? 0
        planMorning = try container.decodeIfPresent(String.self, forKey: .planMorning) ?? ""
        planAfternoon = try container.decodeIfPresent(String.self, forKey: .planAfternoon) ?? ""
        planEvening = try container.decodeIfPresent(String.self, forKey: .planEvening) ?? ""
        kitSealedAt = try container.decodeIfPresent(Date.self, forKey: .kitSealedAt)
        sealedEssentialIds = try container.decodeIfPresent([UUID].self, forKey: .sealedEssentialIds) ?? []
        lastBriefDayKey = try container.decodeIfPresent(String.self, forKey: .lastBriefDayKey)
        briefResidue = try container.decodeIfPresent(String.self, forKey: .briefResidue) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(city, forKey: .city)
        try container.encode(country, forKey: .country)
        try container.encode(notes, forKey: .notes)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(visited, forKey: .visited)
        try container.encode(budgetCurrency, forKey: .budgetCurrency)
        try container.encode(budgetPlanned, forKey: .budgetPlanned)
        try container.encode(budgetSpent, forKey: .budgetSpent)
        try container.encode(planMorning, forKey: .planMorning)
        try container.encode(planAfternoon, forKey: .planAfternoon)
        try container.encode(planEvening, forKey: .planEvening)
        try container.encodeIfPresent(kitSealedAt, forKey: .kitSealedAt)
        try container.encode(sealedEssentialIds, forKey: .sealedEssentialIds)
        try container.encodeIfPresent(lastBriefDayKey, forKey: .lastBriefDayKey)
        try container.encode(briefResidue, forKey: .briefResidue)
    }
}

enum DestinationFilter: String, Codable, CaseIterable, Identifiable {
    case all
    case planned
    case visited

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .planned:
            return "Open"
        case .visited:
            return "Done"
        }
    }
}

enum DestinationSort: String, Codable, CaseIterable, Identifiable {
    case date
    case city
    case country

    var id: String { rawValue }

    var title: String {
        switch self {
        case .date:
            return "Date"
        case .city:
            return "City"
        case .country:
            return "Country"
        }
    }
}

enum TripCurrency: String, CaseIterable, Identifiable {
    case eur = "EUR"
    case usd = "USD"
    case gbp = "GBP"
    case jpy = "JPY"
    case chf = "CHF"
    case cad = "CAD"
    case aud = "AUD"
    case pln = "PLN"
    case czk = "CZK"
    case sek = "SEK"
    case uah = "UAH"

    var id: String { rawValue }
}

struct BriefLoop: Identifiable, Equatable {
    var id: String
    var title: String
    var detail: String
}
