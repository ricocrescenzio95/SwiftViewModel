# Testing View Models

Install explicit environment values on a view model without mounting a SwiftUI view.

## Overview

Use ``TestViewModelObject`` in unit tests when view-model behavior depends on ``ViewModel/environment``. The wrapper stores the view model, installs the environment you provide, and calls ``ViewModel/onEnvironmentReady()`` immediately.

```swift
import SwiftUI
import SwiftViewModel
import Testing

final class GreetingViewModel: ViewModel {
    private(set) var greeting = "Hello"

    func onEnvironmentReady() {
        if environment.locale.identifier == "it_IT" {
            greeting = "Ciao"
        }
    }
}

@MainActor
@Test
func readsLocaleFromEnvironment() {
    var environment = EnvironmentValues()
    environment.locale = Locale(identifier: "it_IT")

    @TestViewModelObject(environment: environment)
    var viewModel = GreetingViewModel()

    #expect(viewModel.greeting == "Ciao")
}
```

``TestViewModelObject`` is designed for unit tests. In production SwiftUI views, use ``ViewModelObject`` so the model receives the environment from the actual view hierarchy.
