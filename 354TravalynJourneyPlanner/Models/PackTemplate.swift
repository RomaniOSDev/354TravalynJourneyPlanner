import Foundation

struct PackTemplate: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var categories: [PackTemplateCategory]
}

struct PackTemplateCategory: Codable, Equatable, Hashable {
    var title: String
    var items: [String]
}
