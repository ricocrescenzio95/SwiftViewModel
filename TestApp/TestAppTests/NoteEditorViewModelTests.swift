import SwiftViewModel
import Testing
@testable import TestApp
import Observation

@MainActor
@Suite("NoteEditorViewModel")
struct NoteEditorViewModelTests {
  @Test
  func loadsExistingNoteWhenEnvironmentIsReady() {
    let note = Note(title: "Original", details: "Original details")
    let storage = NoteStorage(notes: [note])

    @TestViewModelObject(environment: makeEnvironment(noteStorage: storage))
    var viewModel = NoteEditorViewModel(noteID: note.id)

    #expect(viewModel.isCreating == false)
    #expect(viewModel.title == "Original")
    #expect(viewModel.details == "Original details")
  }

  @Test
  func newEditorStartsEmpty() {
    let storage = NoteStorage()

    @TestViewModelObject(environment: makeEnvironment(noteStorage: storage))
    var viewModel = NoteEditorViewModel()

    #expect(viewModel.isCreating)
    #expect(viewModel.title.isEmpty)
    #expect(viewModel.details.isEmpty)
    #expect(viewModel.canSave == false)
  }

  @Test
  func canSaveRequiresNonBlankTitle() {
    let storage = NoteStorage()

    @TestViewModelObject(environment: makeEnvironment(noteStorage: storage))
    var viewModel = NoteEditorViewModel()

    viewModel.title = "   "
    #expect(viewModel.canSave == false)

    viewModel.title = "Buy milk"
    #expect(viewModel.canSave)
  }

  @Test
  func saveCreatesTrimmedNote() async throws {
    let storage = NoteStorage()

    @TestViewModelObject(environment: makeEnvironment(noteStorage: storage))
    var viewModel = NoteEditorViewModel()

    viewModel.title = "  Buy milk  "
    viewModel.details = "  Remember oat milk  "
    
    try #require(storage.notes.isEmpty)
    
    await waitViewModelTasks {
      viewModel.save()
      #expect(viewModel.isSaving)
    }
    #expect(!viewModel.isSaving)
    
    #expect(storage.notes.count == 1)
    #expect(storage.notes.first?.title == "Buy milk")
    #expect(storage.notes.first?.details == "Remember oat milk")
  }

  @Test
  func saveUpdatesExistingNote() async {
    let note = Note(title: "Old", details: "Old details")
    let storage = NoteStorage(notes: [note])

    @TestViewModelObject(environment: makeEnvironment(noteStorage: storage))
    var viewModel = NoteEditorViewModel(noteID: note.id)

    viewModel.title = "New"
    viewModel.details = "New details"
    
    await waitViewModelTasks {
      viewModel.save()
    }

    let updatedNote = storage.note(withID: note.id)
    #expect(updatedNote?.title == "New")
    #expect(updatedNote?.details == "New details")
  }

  @Test
  func saveIgnoresBlankTitle() {
    let storage = NoteStorage()

    @TestViewModelObject(environment: makeEnvironment(noteStorage: storage))
    var viewModel = NoteEditorViewModel()

    viewModel.title = "\n  \t"
    viewModel.details = "Ignored details"
    viewModel.save()

    #expect(storage.notes.isEmpty)
  }
}
