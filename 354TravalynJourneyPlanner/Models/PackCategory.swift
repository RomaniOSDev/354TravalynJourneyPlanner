import Foundation

struct PackCategory: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var destinationId: UUID
    var title: String
    var sortIndex: Int
}
