import Foundation

struct TransitNote: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var destinationId: UUID
    var body: String
    var updatedAt: Date
}

struct TransitPreference: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var destinationId: UUID
    var usesMetro: Bool
    var usesTaxi: Bool
    var usesRental: Bool
}

enum FrictionKind: String, Codable, CaseIterable, Identifiable {
    case crowded
    case delayed
    case confusing
    case cashOnly
    case language
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .crowded:
            return "Crowded"
        case .delayed:
            return "Delayed"
        case .confusing:
            return "Confusing"
        case .cashOnly:
            return "Cash only"
        case .language:
            return "Language"
        case .other:
            return "Other"
        }
    }

    var prepTip: String {
        switch self {
        case .crowded:
            return "Leave 15 minutes earlier for peak stations."
        case .delayed:
            return "Keep a backup rail or rideshare note on Lines."
        case .confusing:
            return "Save one landmark transfer before you leave the gate."
        case .cashOnly:
            return "Pack small bills in Kit essentials before sealing."
        case .language:
            return "Pin two destination phrases in your transit memo."
        case .other:
            return "Log the detail so Pulse can spot the pattern next trip."
        }
    }
}

struct FrictionEvent: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var destinationId: UUID
    var kind: FrictionKind
    var note: String
    var createdAt: Date
}
