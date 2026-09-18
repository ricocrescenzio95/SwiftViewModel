# ``SwiftViewModel``

Create SwiftUI view models that keep their view identity and receive the current environment.

## Overview

SwiftViewModel provides a small set of tools for moving view behavior out of a SwiftUI view without losing access to values from the SwiftUI environment.

Define your model by conforming to ``ViewModel``. Store it in a view with ``ViewModelObject`` so SwiftViewModel can install the current `EnvironmentValues` and preserve the model for the lifetime of the view identity, similarly to SwiftUI's `StateObject`.

> Important: If a view model reads ``ViewModel/environment`` from SwiftUI, always store it with ``ViewModelObject``. A view model created or held directly doesn't receive values from the view hierarchy and reads default environment values instead.

In tests, use ``TestViewModelObject`` to install explicit environment values without mounting a SwiftUI view.

```swift
import Observation
import SwiftUI
import SwiftViewModel

@MainActor
@Observable
final class NotesViewModel: ViewModel {
    var notes = ""

    func onEnvironmentReady() {
        if environment.locale.language.languageCode?.identifier == "it" {
            notes = "Modifica"
        }
    }
}

struct NotesView: View {
    @ViewModelObject private var viewModel = NotesViewModel()

    var body: some View {
        TextEditor(text: $viewModel.notes)
    }
}
```

## Topics

### Essentials

- ``ViewModel``
- ``ViewModelObject``
- ``TestViewModelObject``

### Guides

- <doc:UsingViewModelsInSwiftUI>
- <doc:TestingViewModels>
- <doc:ManagingViewModelTasks>

### Diagnostics

- <doc:RuntimeDiagnostics>
