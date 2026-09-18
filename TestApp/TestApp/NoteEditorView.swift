import Foundation
import Observation
import SwiftUI
import SwiftViewModel

@Observable
final class NoteEditorViewModel: ViewModel {
  let noteID: Note.ID?
  var field: FocusField?
  var title = ""
  var details = ""
  private(set) var isSaving = false

  init(noteID: Note.ID? = nil) {
    self.noteID = noteID
  }

  var isCreating: Bool {
    noteID == nil
  }

  var canSave: Bool {
    !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  func onEnvironmentReady() {
    guard let noteID, let note = noteStorage.note(withID: noteID) else { return }
    title = note.title
    details = note.details
  }

  func save() {
    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedTitle.isEmpty else { return }

    isSaving = true
    task { [noteStorage, dismiss = environment.dismiss] in
      defer { isSaving = false }

      try await Task.sleep(for: .seconds(2))
      
      if let noteID {
        noteStorage.updateNote(id: noteID, title: trimmedTitle, details: trimmedDetails)
      } else {
        noteStorage.addNote(title: trimmedTitle, details: trimmedDetails)
      }
      
      dismiss()
    }
  }

  func cancel() {
    environment.dismiss()
  }
}

@globalActor
actor TestActor {
  static let shared = TestActor()
}

extension NoteEditorViewModel {
  enum FocusField {
    case title
    case details
  }
}

struct NoteEditorView: View {
  @ViewModelObject private var viewModel: NoteEditorViewModel
  
  init(noteID: Note.ID? = nil) {
    _viewModel = ViewModelObject(wrappedValue: NoteEditorViewModel(noteID: noteID))
  }

  var body: some View {
    Form {
      Section("Title") {
        TextField("Title", text: $viewModel.title)
          .focused($viewModel.field, equals: .title)
      }
      Section("Details") {
        TextEditor(text: $viewModel.details)
          .frame(minHeight: 160)
          .focused($viewModel.field, equals: .details)
      }
    }
    .safeAreaInset(edge: .bottom) {
      if viewModel.field != nil {
        GlassEffectContainer {
          HStack {
            Button {
              viewModel.field = .title
            } label: {
              Image(systemName: "chevron.backward")
            }
            Button {
              viewModel.field = .details
            } label: {
              Image(systemName: "chevron.forward")
            }
            Spacer()
          }
        }
        .buttonStyle(.glass)
        .padding(8)
        .glassEffect()
        .padding(8)
      }
    }
    .navigationTitle(viewModel.isCreating ? Text("New Note") : Text("Edit Note"))
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel", action: viewModel.cancel)
          .disabled(viewModel.isSaving)
      }
      ToolbarItem(placement: .confirmationAction) {
        if viewModel.isSaving {
          ProgressView()
        } else {
          Button("Save", action: viewModel.save)
            .disabled(!viewModel.canSave)
        }
      }
    }
    .interactiveDismissDisabled(viewModel.isSaving)
  }
}

private struct FocusModifier: ViewModifier {
  @FocusState private var __isFocused: Bool
  @Binding var isFocused: Bool

  func body(content: Content) -> some View {
    content
      .focused($__isFocused)
      .onAppear {
        isFocused = __isFocused
      }
  }
}

extension View {
  func focused(_ condition: Binding<Bool>) -> some View {
    modifier(
      FocusModifier(isFocused: condition)
    )
  }
  
  func focused<T: Hashable>(_ field: Binding<T>, equals value: T) -> some View {
    modifier(
      FocusModifier(isFocused: .constant(false))
    )
  }
}
