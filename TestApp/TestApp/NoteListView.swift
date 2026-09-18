import Foundation
import Observation
import SwiftUI
import SwiftViewModel

@Observable
final class NoteListViewModel: ViewModel {
  var isCreatingNote = false

  var notes: [Note] {
    noteStorage.notes
  }

  var openNotesCount: Int {
    noteStorage.notes.filter { !$0.isCompleted }.count
  }

  func showCreateNote() {
    isCreatingNote = true
  }

  func toggleCompletion(for noteID: Note.ID) {
    noteStorage.toggleCompletion(for: noteID)
  }

  func deleteNote(id: Note.ID) {
    noteStorage.deleteNote(id: id)
  }

  func deleteNotes(at offsets: IndexSet) {
    let ids = offsets.map { notes[$0].id }
    noteStorage.deleteNotes(withIDs: ids)
  }
}

struct NoteListView: View {
  @ViewModelObject private var viewModel = NoteListViewModel()

  var body: some View {
    NavigationStack {
      List {
        NoteSummarySection(
          openCount: viewModel.openNotesCount,
          totalCount: viewModel.notes.count
        )

        if viewModel.notes.isEmpty {
          EmptyNotesView(addNote: viewModel.showCreateNote)
        } else {
          Section("Notes") {
            ForEach(viewModel.notes) { note in
              NavigationLink(value: note.id) {
                NoteRowView(note: note)
              }
              .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                  viewModel.toggleCompletion(for: note.id)
                } label: {
                  Label(
                    note.isCompleted ? "Reopen" : "Complete",
                    systemImage: note.isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle"
                  )
                }
                .tint(note.isCompleted ? .orange : .green)
              }
              .swipeActions {
                Button(role: .destructive) {
                  viewModel.deleteNote(id: note.id)
                } label: {
                  Label("Delete", systemImage: "trash")
                }
              }
            }
            .onDelete(perform: viewModel.deleteNotes)
          }
        }
      }
      .navigationTitle("Notes")
      .toolbar {
        Button(action: viewModel.showCreateNote) {
          Image(systemName: "square.and.pencil")
        }
        .accessibilityLabel("New Note")
      }
      .navigationDestination(for: Note.ID.self) { noteID in
        NoteDetailView(noteID: noteID)
      }
      .sheet(isPresented: $viewModel.isCreatingNote) {
        NavigationStack {
          NoteEditorView()
        }
      }
    }
  }
}

private struct NoteSummarySection: View {
  let openCount: Int
  let totalCount: Int

  var body: some View {
    Section {
      HStack(spacing: 16) {
        Label("Open", systemImage: "circle")
        Spacer()
        Text("\(openCount) of \(totalCount)")
          .foregroundStyle(.secondary)
      }
    }
  }
}

private struct EmptyNotesView: View {
  let addNote: () -> Void

  var body: some View {
    Section {
      VStack(spacing: 12) {
        Image(systemName: "checklist")
          .font(.largeTitle)
          .foregroundStyle(.secondary)
        Text("No Notes")
          .font(.headline)
        Text("Create your first note to start tracking what needs attention.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
        Button(action: addNote) {
          Label("Create Note", systemImage: "plus")
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 24)
    }
  }
}

private struct NoteRowView: View {
  let note: Note

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: note.isCompleted ? "checkmark.circle.fill" : "circle")
        .foregroundStyle(note.isCompleted ? .green : .secondary)
        .imageScale(.large)

      VStack(alignment: .leading, spacing: 4) {
        Text(note.title)
          .font(.headline)
          .strikethrough(note.isCompleted)
          .foregroundStyle(note.isCompleted ? .secondary : .primary)

        if !note.details.isEmpty {
          Text(note.details)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
      }
    }
    .padding(.vertical, 4)
  }
}
