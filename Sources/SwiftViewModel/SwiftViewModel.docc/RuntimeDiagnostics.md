# Runtime Diagnostics

Understand SwiftViewModel runtime warnings in debug builds.

## Overview

SwiftViewModel emits runtime warnings when an API is used before the view model is connected to an environment. The most common case is reading ``ViewModel/environment`` before ``ViewModelObject`` or ``TestViewModelObject`` installs environment values.

```swift
@MainActor
final class BadViewModel: ViewModel {
    init() {
        // Reads default values and emits a runtime warning in debug builds.
        _ = environment.locale
    }
}
```

Move environment-dependent setup to ``ViewModel/onEnvironmentReady()``:

```swift
@MainActor
final class GoodViewModel: ViewModel {
    func onEnvironmentReady() {
        _ = environment.locale
    }
}
```
