import Foundation

struct PackItem: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var categoryId: UUID
    var title: String
    var isComplete: Bool
    var sortIndex: Int
}
