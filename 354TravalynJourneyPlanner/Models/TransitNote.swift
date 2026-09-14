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
