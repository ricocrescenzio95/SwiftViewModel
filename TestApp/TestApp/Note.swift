import Foundation

nonisolated struct Note: Identifiable, Hashable {
  let id: UUID
  var title: String
  var details: String
  var isCompleted: Bool
  let createdAt: Date
  var modifiedAt: Date

  init(
    id: UUID = UUID(),
    title: String,
    details: String = "",
    isCompleted: Bool = false,
    createdAt: Date = .now,
    modifiedAt: Date? = nil
  ) {
    self.id = id
    self.title = title
    self.details = details
    self.isCompleted = isCompleted
    self.createdAt = createdAt
    self.modifiedAt = modifiedAt ?? createdAt
  }
}
