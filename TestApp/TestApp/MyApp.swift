import SwiftUI

@main
struct MyApp: App {
  @State private var noteStorage = NoteStorage.sample()

  var body: some Scene {
    WindowGroup {
      NoteListView()
        .environment(\.noteStorage, noteStorage)
    }
  }
}

#Preview {
  @Previewable @State var storage = NoteStorage.sample()
  NoteListView()
    .environment(\.noteStorage, storage)
}
