import Foundation
import SwiftViewModel
import Testing
@testable import TestApp

@MainActor
@Suite("NoteListViewModel")
struct NoteListViewModelTests {
  @Test
  func readsNotesAndOpenCountFromStorage() {
    let openNote = Note(title: "Buy milk")
    let completedNote = Note(title: "Write docs", isCompleted: true)
    let storage = NoteStorage(notes: [openNote, completedNote])

    @TestViewModelObject(environment: makeEnvironment(noteStorage: storage))
    var viewModel = NoteListViewModel()

    #expect(viewModel.notes == [openNote, completedNote])
    #expect(viewModel.openNotesCount == 1)
  }

  @Test
  func showCreateNotePresentsEditor() {
    let storage = NoteStorage()

    @TestViewModelObject(environment: makeEnvironment(noteStorage: storage))
    var viewModel = NoteListViewModel()

    viewModel.showCreateNote()

    #expect(viewModel.isCreatingNote)
  }

  @Test
  func toggleCompletionUpdatesStorage() {
    let note = Note(title: "Ship sample app")
    let storage = NoteStorage(notes: [note])

    @TestViewModelObject(environment: makeEnvironment(noteStorage: storage))
    var viewModel = NoteListViewModel()

    viewModel.toggleCompletion(for: note.id)

    #expect(storage.note(withID: note.id)?.isCompleted == true)
    #expect(viewModel.openNotesCount == 0)
  }

  @Test
  func deleteNoteRemovesItFromStorage() {
    let firstNote = Note(title: "Keep")
    let secondNote = Note(title: "Delete")
    let storage = NoteStorage(notes: [firstNote, secondNote])

    @TestViewModelObject(environment: makeEnvironment(noteStorage: storage))
    var viewModel = NoteListViewModel()

    viewModel.deleteNote(id: secondNote.id)

    #expect(storage.note(withID: secondNote.id) == nil)
    #expect(viewModel.notes == [firstNote])
  }

  @Test
  func deleteNotesAtOffsetsRemovesMatchingVisibleNotes() {
    let firstNote = Note(title: "First")
    let secondNote = Note(title: "Second")
    let thirdNote = Note(title: "Third")
    let storage = NoteStorage(notes: [firstNote, secondNote, thirdNote])

    @TestViewModelObject(environment: makeEnvironment(noteStorage: storage))
    var viewModel = NoteListViewModel()

    viewModel.deleteNotes(at: IndexSet([0, 2]))

    #expect(viewModel.notes == [secondNote])
  }
}
