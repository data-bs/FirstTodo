import Foundation

struct TodoItem: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let category: String
    var isDone: Bool = false
    let dateAdded: Date
    let targetDate: Date?
}
