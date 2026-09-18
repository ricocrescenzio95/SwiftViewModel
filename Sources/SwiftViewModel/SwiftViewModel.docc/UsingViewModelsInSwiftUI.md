# Using View Models in SwiftUI

Keep view-specific behavior in a reference type while letting SwiftViewModel install the current SwiftUI environment.

## Overview

A ``ViewModel`` can read ``ViewModel/environment`` after SwiftViewModel installs environment values from the view hierarchy. In a SwiftUI view, that installation happens through ``ViewModelObject``.

Use ``ViewModelObject`` when the view creates the model:

```swift
import Observation
import SwiftUI
import SwiftViewModel

@MainActor
@Observable
final class ProfileViewModel: ViewModel {
    private(set) var title = "Profile"

    func onEnvironmentReady() {
        if environment.locale.language.languageCode?.identifier == "it" {
            title = "Profilo"
        }
    }
}

struct ProfileView: View {
    @ViewModelObject private var viewModel = ProfileViewModel()

    var body: some View {
        Text(viewModel.title)
    }
}
```

SwiftViewModel calls ``ViewModel/onEnvironmentReady()`` once, the first time ``ViewModelObject`` receives an environment from SwiftUI. Use that method for setup that depends on ``ViewModel/environment``.

> Important: Avoid reading ``ViewModel/environment`` in the view model initializer. At initialization time SwiftUI hasn't installed the view environment yet, so the model only has default values.

## Use the Environment for Dependency Injection

The environment can also carry custom objects, so it can be used as a lightweight
dependency-injection mechanism. Define an `EnvironmentKey` for the dependency
and read it from the view model after the environment has been installed.

```swift
import Observation
import SwiftUI
import SwiftViewModel

protocol UserService {
    func currentUserName() async throws -> String
}

private struct UserServiceImpl: UserService {
    func currentUserName() async throws -> String {
        let (data, _) = try await URLSession.shared.data(
            for: URLRequest(url: URL(string: "https://myserver.com/fetchUserName")!)
        )
        return String(data: data, encoding: .utf8) ?? "--"
    }
}

private struct PreviewUserService: UserService {
    func currentUserName() async throws -> String { "Preview User" }
}

extension EnvironmentValues {
    @Entry var userService: any UserService = UserServiceImpl()
}

@MainActor
@Observable
final class ProfileViewModel: ViewModel {
    private(set) var userName = ""

    func onEnvironmentReady() {
        let service = environment.userService
        task {
            userName = try await service.currentUserName()
        }
    }
}

struct ProfileView: View {
    @ViewModelObject private var viewModel = ProfileViewModel()

    var body: some View {
        Text(viewModel.userName)
    }
}

#Preview {
    @Previewable @State var userService = PreviewUserService()
    ProfileView()
        .environment(\.userService, userService)
}

struct MyApp: View {
    @State private var userService = UserServiceImpl()

    var body: some View {
        ProfileView()
            .environment(\.userService, userService)
    }
}
```

This keeps the view model independent from the concrete service implementation.
The same mechanism can be used in tests with `TestViewModelObject` by installing
an environment containing a mock or in-memory implementation.

## Bind to View Model Properties

``ViewModelObject`` projects bindings through SwiftUI's `Bindable` support, so views can bind controls directly to mutable observable properties.

```swift
struct NotesView: View {
    @ViewModelObject private var viewModel = NotesViewModel()

    var body: some View {
        TextEditor(text: $viewModel.notes)
    }
}
```
