import Foundation
import Observation
import SwiftUI
import SwiftViewModel

@Observable
final class NoteDetailViewModel: ViewModel {
  let noteID: Note.ID
  var isEditingNote = false

  init(noteID: Note.ID) {
    self.noteID = noteID
  }

  var note: Note? {
    noteStorage.note(withID: noteID)
  }

  var isCompleted: Bool {
    note?.isCompleted ?? false
  }

  func editNote() {
    isEditingNote = true
  }

  func toggleCompletion() {
    withAnimation {
      noteStorage.toggleCompletion(for: noteID)
    }
  }

  func deleteNote() {
    noteStorage.deleteNote(id: noteID)
    environment.dismiss()
  }
}

struct NoteDetailView: View {
  @ViewModelObject private var viewModel: NoteDetailViewModel

  init(noteID: Note.ID) {
    _viewModel = ViewModelObject(wrappedValue: NoteDetailViewModel(noteID: noteID))
  }

  var body: some View {
    List {
      if let note = viewModel.note {
        NoteDetailHeader(
          title: note.title,
          isCompleted: note.isCompleted,
          toggleCompletion: viewModel.toggleCompletion
        )
        NoteDetailsSection(details: note.details)
        NoteDatesSection(createdAt: note.createdAt, modifiedAt: note.modifiedAt)
        NoteDeleteSection(deleteNote: viewModel.deleteNote)
      } else {
        MissingNoteView()
      }
    }
    .navigationTitle("Note")
    .toolbar {
      Button(action: viewModel.toggleCompletion) {
        Image(systemName: viewModel.isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle")
      }
      .disabled(viewModel.note == nil)
      .accessibilityLabel(viewModel.isCompleted ? "Reopen Note" : "Complete Note")

      Button(action: viewModel.editNote) {
        Image(systemName: "square.and.pencil")
      }
      .disabled(viewModel.note == nil)
      .accessibilityLabel("Edit Note")
    }
    .sheet(isPresented: $viewModel.isEditingNote) {
      NavigationStack {
        NoteEditorView(noteID: viewModel.noteID)
      }
    }
  }
}

private struct NoteDetailHeader: View {
  let title: String
  let isCompleted: Bool
  let toggleCompletion: () -> Void

  var body: some View {
    Section {
      VStack(alignment: .leading, spacing: 12) {
        HStack(alignment: .top, spacing: 12) {
          Text(title)
            .font(.title2)
            .fontWeight(.semibold)
            .strikethrough(isCompleted)
            .frame(maxWidth: .infinity, alignment: .leading)

          Button(action: toggleCompletion) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
              .imageScale(.large)
          }
          .buttonStyle(.plain)
          .foregroundStyle(isCompleted ? .green : .secondary)
          .accessibilityLabel(isCompleted ? "Reopen Note" : "Complete Note")
        }

        Label(isCompleted ? "Completed" : "Open", systemImage: isCompleted ? "checkmark.circle.fill" : "circle")
          .font(.subheadline)
          .foregroundStyle(isCompleted ? .green : .secondary)
      }
      .padding(.vertical, 4)
    }
  }
}

private struct NoteDetailsSection: View {
  let details: String

  var body: some View {
    Section("Details") {
      if details.isEmpty {
        Text("No details")
          .foregroundStyle(.secondary)
      } else {
        Text(details)
      }
    }
  }
}

private struct NoteDatesSection: View {
  let createdAt: Date
  let modifiedAt: Date

  var body: some View {
    Section("Dates") {
      LabeledContent("Created", value: createdAt.formatted(date: .abbreviated, time: .shortened))
      LabeledContent("Modified", value: modifiedAt.formatted(date: .abbreviated, time: .shortened))
    }
  }
}

private struct NoteDeleteSection: View {
  let deleteNote: () -> Void

  var body: some View {
    Section {
      Button(role: .destructive, action: deleteNote) {
        Label("Delete Note", systemImage: "trash")
      }
    }
  }
}

private struct MissingNoteView: View {
  var body: some View {
    Section {
      VStack(spacing: 12) {
        Image(systemName: "exclamationmark.triangle")
          .font(.largeTitle)
          .foregroundStyle(.secondary)
        Text("Note Not Found")
          .font(.headline)
        Text("This note may have already been deleted.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 24)
    }
  }
}
