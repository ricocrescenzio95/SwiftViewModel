import SwiftUI

/// A SwiftUI property wrapper that creates and owns a view model for a view.
///
/// ``ViewModelObject`` is similar to SwiftUI's `StateObject`: use it when a
/// view creates a reference-type model and needs that model to live for the
/// lifetime of the view's identity.
///
/// Always use ``ViewModelObject`` for a ``ViewModel`` that reads
/// ``ViewModel/environment`` from a SwiftUI view. The wrapper installs the
/// current SwiftUI environment and calls ``ViewModel/onEnvironmentReady()`` the
/// first time the environment is available.
///
/// The following example creates a view model, reads its state, and passes a
/// binding to one of its properties:
///
/// ```swift
/// import Observation
/// import SwiftUI
/// import SwiftViewModel
///
/// @MainActor
/// @Observable
/// final class NotesViewModel: ViewModel {
///   var notes = ""
///
///   func clear() {
///     notes = ""
///   }
/// }
///
/// struct NotesView: View {
///   @ViewModelObject private var viewModel = NotesViewModel()
///
///   var body: some View {
///     VStack {
///       TextEditor(text: $viewModel.notes)
///       Button("Clear", action: viewModel.clear)
///     }
///   }
/// }
/// ```
@propertyWrapper
@MainActor
public struct ViewModelObject<VM: ViewModel>: @MainActor DynamicProperty {
  
  @FocusState var focused: Bool
  
  @MainActor
  private final class ViewModelBox: ObservableObject {
    var viewModel: VM
    private var isEnvironmentLoaded = false
    private var onDeinit: (() -> Void)? = nil

    init(_ viewModel: VM) {
      self.viewModel = viewModel
    }
    
    func update(environment: EnvironmentValues) {
      viewModel.environment = environment
      let id = viewModel.id
      if !isEnvironmentLoaded {
        onDeinit = {
          viewModelStorage.storage.removeValue(forKey: id)
        }
        isEnvironmentLoaded = true
        viewModel.onEnvironmentReady()
      }
    }
    
    isolated deinit { onDeinit?() }
  }
  
  @StateObject private var box: ViewModelBox
  @Environment(\.self) private var environment

  /// Creates a view model object with an initial view model.
  ///
  /// SwiftUI evaluates the view model creation through the wrapper's private
  /// `StateObject` storage, preserving one view model instance for the lifetime
  /// of the view identity.
  ///
  /// - Parameter wrappedValue: The view model to create and store.
  public init(wrappedValue: @autoclosure @escaping () -> VM) {
    _box = StateObject(wrappedValue: .init(wrappedValue()))
  }

  /// The view model owned by the view.
  public var wrappedValue: VM { box.viewModel }

  /// A binding to the stored view model reference.
  public var projectedValue: Binding<VM> { _box.projectedValue.viewModel }

  /// Updates the property wrapper with the current SwiftUI environment.
  ///
  /// SwiftUI calls this method before evaluating the view's body. You don't call
  /// it directly.
  public func update() {
    box.update(environment: environment)
  }
}

/// A property wrapper that installs environment values on a view model for tests.
///
/// Use this wrapper in unit tests to create a view model with explicit
/// `EnvironmentValues` without mounting a SwiftUI view. The wrapper installs
/// the environment immediately and calls ``ViewModel/onEnvironmentReady()`` once.
///
/// The following example verifies behavior that depends on a mocked locale:
///
/// ```swift
/// import SwiftUI
/// import SwiftViewModel
/// import Testing
///
/// final class GreetingViewModel: ViewModel {
///   private(set) var greeting = "Hello"
///
///   func onEnvironmentReady() {
///     if environment.locale.identifier == "it_IT" {
///       greeting = "Ciao"
///     }
///   }
/// }
///
/// @Test
/// func readsLocaleFromEnvironment() {
///   var environment = EnvironmentValues()
///   environment.locale = Locale(identifier: "it_IT")
///
///   @TestViewModelObject(environment: environment)
///   var viewModel = GreetingViewModel()
///
///   #expect(viewModel.greeting == "Ciao")
/// }
/// ```
@propertyWrapper
@MainActor
public struct TestViewModelObject<VM: ViewModel> {
  private final class Lifecyle {
    let onDeinit: () -> Void
    init(onDeinit: @escaping () -> Void) {
      self.onDeinit = onDeinit
    }
    deinit { onDeinit() }
  }

  private let lifecyle: Lifecyle

  /// Creates a test view model object with explicit environment values.
  ///
  /// - Parameters:
  ///   - viewModel: The view model to prepare for testing.
  ///   - environment: The environment values to install on the view model.
  public init(
    wrappedValue viewModel: VM,
    environment: EnvironmentValues = EnvironmentValues()
  ) {
    let id = viewModel.id
    
    wrappedValue = viewModel
    lifecyle = Lifecyle {
      viewModelStorage.storage.removeValue(forKey: id)
    }

    viewModel.environment = environment
    viewModel.onEnvironmentReady()
  }

  /// The view model prepared for testing.
  public let wrappedValue: VM
}
