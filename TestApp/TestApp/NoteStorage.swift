import Foundation
import Observation
import SwiftUI
import SwiftViewModel

nonisolated protocol NoteStorageProtocol: AnyObject & Observable {
  var notes: [Note] { get }

  func note(withID id: Note.ID) -> Note?

  @discardableResult
  func addNote(title: String, details: String) -> Note.ID

  func updateNote(id: Note.ID, title: String, details: String)

  func toggleCompletion(for id: Note.ID)

  func deleteNote(id: Note.ID)

  func deleteNotes(withIDs ids: [Note.ID])
}

@Observable
nonisolated final class NoteStorage: NoteStorageProtocol {
  private(set) var notes: [Note]

  init(notes: [Note] = []) {
    self.notes = notes
  }

  func note(withID id: Note.ID) -> Note? {
    notes.first { $0.id == id }
  }

  @discardableResult
  func addNote(title: String, details: String) -> Note.ID {
    let note = Note(title: title, details: details)
    notes.insert(note, at: 0)
    return note.id
  }

  func updateNote(id: Note.ID, title: String, details: String) {
    guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
    notes[index].title = title
    notes[index].details = details
    notes[index].modifiedAt = .now
  }

  func toggleCompletion(for id: Note.ID) {
    guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
    notes[index].isCompleted.toggle()
    notes[index].modifiedAt = .now
  }

  func deleteNote(id: Note.ID) {
    notes.removeAll { $0.id == id }
  }

  func deleteNotes(withIDs ids: [Note.ID]) {
    let ids = Set(ids)
    notes.removeAll { ids.contains($0.id) }
  }
}

extension NoteStorage {
  static func sample() -> NoteStorage {
    NoteStorage(
      notes: [
        Note(
          title: "Write DocC examples",
          details: "Show ViewModelObject, environment, and projected bindings.",
          isCompleted: true,
          createdAt: Date(timeIntervalSinceNow: -86_400)
        ),
        Note(
          title: "Try the sample app",
          details: "Create, edit, complete, and delete a note from the TestApp.",
          createdAt: Date(timeIntervalSinceNow: -3_600)
        ),
        Note(
          title: "Add unit tests",
          details: "Use TestViewModelObject to inject mocked EnvironmentValues.",
          createdAt: Date(timeIntervalSinceNow: -900)
        ),
      ]
    )
  }
}

extension EnvironmentValues {
  @Entry var noteStorage: any NoteStorageProtocol = NoteStorage.sample()
}

extension ViewModel {
  var noteStorage: any NoteStorageProtocol {
    environment.noteStorage
  }
}
