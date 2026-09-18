import SwiftViewModel
import Testing
@testable import TestApp

@MainActor
@Suite("NoteDetailViewModel")
struct NoteDetailViewModelTests {
  @Test
  func exposesCurrentNoteAndCompletionState() {
    let note = Note(title: "Read environment", isCompleted: true)
    let storage = NoteStorage(notes: [note])

    @TestViewModelObject(environment: makeEnvironment(noteStorage: storage))
    var viewModel = NoteDetailViewModel(noteID: note.id)

    #expect(viewModel.note == note)
    #expect(viewModel.isCompleted)
  }

  @Test
  func editNotePresentsEditor() {
    let note = Note(title: "Edit me")
    let storage = NoteStorage(notes: [note])

    @TestViewModelObject(environment: makeEnvironment(noteStorage: storage))
    var viewModel = NoteDetailViewModel(noteID: note.id)

    viewModel.editNote()

    #expect(viewModel.isEditingNote)
  }

  @Test
  func toggleCompletionUpdatesStorage() {
    let note = Note(title: "Complete me")
    let storage = NoteStorage(notes: [note])

    @TestViewModelObject(environment: makeEnvironment(noteStorage: storage))
    var viewModel = NoteDetailViewModel(noteID: note.id)

    viewModel.toggleCompletion()

    #expect(storage.note(withID: note.id)?.isCompleted == true)
    #expect(viewModel.isCompleted)
  }

  @Test
  func deleteNoteRemovesItFromStorage() {
    let note = Note(title: "Delete me")
    let storage = NoteStorage(notes: [note])

    @TestViewModelObject(environment: makeEnvironment(noteStorage: storage))
    var viewModel = NoteDetailViewModel(noteID: note.id)

    viewModel.deleteNote()

    #expect(storage.note(withID: note.id) == nil)
    #expect(viewModel.note == nil)
  }
}
