# Managing View Model Tasks

Start asynchronous work that is tied to a view model lifecycle.

## Overview

``ViewModel`` includes convenience methods for creating tasks and storing them in SwiftViewModel's internal storage. Starting another task with the same identifier cancels the previous task before the new one is stored.

Use a stable identifier when an operation should replace earlier work, such as a search request:

```swift
import Foundation
import Observation
import SwiftViewModel

@MainActor
@Observable
final class SearchViewModel: ViewModel {
    private let searchTaskID = UUID()
    var query = ""
    var results: [String] = []

    func search() {
        task(id: searchTaskID) {
            let query = self.query
            try? await Task.sleep(for: .milliseconds(300))
            results = await loadResults(matching: query)
        }
    }

    private func loadResults(matching query: String) async -> [String] {
        []
    }
}
```

By default, SwiftViewModel cancels stored tasks when the view model storage is released. Pass `keepAlive: true` only for work that must continue independently of the view model lifecycle.

> Note: View model tasks use Swift's regular `Task` initializer. Their operation is scheduled asynchronously and inherits the actor context of the call site.

> Warning: `keepAlive` keeps the task alive, but does not keep the view model, its environment, or the view model storage alive. A task using `keepAlive: true` may outlive the view model. Capture any required dependencies before starting the task, and avoid accessing `self` or `environment` after the view model is released.

## Throwing Work

Use the throwing overload when the asynchronous operation can throw:

```swift
func refresh() {
    task {
        try await service.reload()
    }
}
```

## Testing View Model Tasks

Use ``waitViewModelTasks(_:)`` to wait for tasks started by a view model during
a test. The helper waits until all tracked tasks have finished before returning.

```swift
import Testing
import SwiftViewModel

@MainActor
@Test
func savesNote() async {
    let storage = NoteStorage()

    @TestViewModelObject(environment: makeEnvironment(noteStorage: storage))
    var viewModel = NoteEditorViewModel()
    viewModel.title = "  Buy milk  "

    await waitViewModelTasks {
        viewModel.save()
    }

    #expect(storage.notes.count == 1)
    #expect(storage.notes.first?.title == "Buy milk")
}
```
