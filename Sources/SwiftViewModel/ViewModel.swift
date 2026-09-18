import SwiftUI

// MARK: - ViewModel definition

/// A reference type that receives SwiftUI environment values from a view.
///
/// Use a view model to keep view-specific behavior and asynchronous work outside
/// of a SwiftUI view while still allowing SwiftViewModel to install the view's
/// current environment.
///
/// In SwiftUI views, always store a view model with ``ViewModelObject`` when it
/// reads ``ViewModel/environment``. A view model created or held directly doesn't
/// receive values from the view hierarchy, and reads default environment values instead.
/// In unit tests, use ``TestViewModelObject`` to install explicit environment
/// values without mounting a view.
///
/// The following example defines a view model that reads the current locale after
/// SwiftViewModel installs the environment:
///
/// ```swift
/// import Observation
/// import SwiftUI
/// import SwiftViewModel
///
/// @Observable
/// final class GreetingViewModel: ViewModel {
///   private(set) var greeting = "Hello"
///
///   func onEnvironmentReady() {
///     if environment.locale.language.languageCode?.identifier == "it" {
///       greeting = "Ciao"
///     }
///   }
/// }
/// ```
@MainActor
public protocol ViewModel: AnyObject, DynamicProperty {
  /// Responds after SwiftViewModel installs the first environment on the view model.
  ///
  /// Override this method to start work that depends on values from ``environment``.
  /// SwiftViewModel calls this method once for each ``ViewModelObject`` or
  /// ``TestViewModelObject`` lifecycle.
  func onEnvironmentReady()
}

// MARK: - ViewModel defaults

extension ViewModel {
  nonisolated var id: ObjectIdentifier { ObjectIdentifier(self) }
  
  /// Provides an empty default environment-ready callback.
  public func onEnvironmentReady() {}

  /// The SwiftUI environment values currently installed on the view model.
  ///
  /// ``ViewModelObject`` updates this value before each SwiftUI update.
  /// ``TestViewModelObject`` installs the environment you provide when creating
  /// the test wrapper. Reading this property before an environment is installed
  /// returns default environment values and emits a runtime warning in debug builds.
  public internal(set) var environment: EnvironmentValues {
    get {
      if let environment = viewModelStorage.storage[id]?.environment {
        return environment
      } else {
        __runtimeWarning(
          """
          Accessing ViewEnvironment's value before being installed on a View.
          This usually happens if you accessed the environment in the \(Self.self)'s init. This will always read the default value.
          Use it from onEnvironmentReady().
          """
        )
        return EnvironmentValues()
      }
    }
    set { viewModelStorage.storage[id, default: .init()].environment = newValue }
  }
  
  /// Starts a throwing asynchronous task owned by the view model.
  ///
  /// Starting another throwing task with the same identifier cancels the previous
  /// task before storing the new one. SwiftViewModel removes the task from storage
  /// when the operation finishes or is cancelled.
  ///
  /// - Parameters:
  ///   - taskID: The identifier used to replace an existing task. The default value
  ///     creates a new independent task.
  ///   - name: A name to associate with the task.
  ///   - priority: The priority to use when creating the task.
  ///   - keepAlive: A Boolean value that indicates whether the task should continue
  ///     running after the view model storage is released.
  ///   - operation: The asynchronous throwing work to perform.
  ///
  /// - Important: `keepAlive` keeps the task alive, but does not keep the view model,
  ///   its environment, or the view model storage alive. Capture required
  ///   dependencies before starting a task that may outlive the view model.
  /// - Returns: The task created for the operation.
  @discardableResult public func task<ID: Hashable & Sendable>(
    id taskID: ID = UUID(),
    name: String? = nil,
    priority: TaskPriority? = nil,
    keepAlive: Bool = false,
    @_implicitSelfCapture operation: @escaping @MainActor () async throws -> Void
  ) -> Task<Void, any Error> {
    let taskID = ViewModelTaskID(taskID)
    viewModelStorage.storage[id]?.throwingTasks[taskID]?.task?.cancel()
    
    let viewModelTask = ViewModelTask<any Error>(keepAlive: keepAlive)

    let task = Task(name: name, priority: priority) {
      defer {
        viewModelStorage.removeTaskIfCurrent(viewModelTask, id: taskID, for: id)
        ViewModelTasksBag.bag?.removeTaskIfCurrent(viewModelTask, id: taskID)
      }
      
      try await withTaskCancellationHandler {
        try await operation()
      } onCancel: { @MainActor in
        viewModelStorage.removeTaskIfCurrent(viewModelTask, id: taskID, for: id)
        ViewModelTasksBag.bag?.removeTaskIfCurrent(viewModelTask, id: taskID)
      }
    }
    
    viewModelTask.task = task
    
    viewModelStorage.storage[id, default: .init()].throwingTasks[taskID] = viewModelTask
    ViewModelTasksBag.bag?.throwingTasks[taskID] = viewModelTask
    return task
  }
  
  /// Starts a nonthrowing asynchronous task owned by the view model.
  ///
  /// Starting another nonthrowing task with the same identifier cancels the previous
  /// task before storing the new one. SwiftViewModel removes the task from storage
  /// when the operation finishes or is cancelled.
  ///
  /// - Parameters:
  ///   - taskID: The identifier used to replace an existing task. The default value
  ///     creates a new independent task.
  ///   - name: A name to associate with the task.
  ///   - priority: The priority to use when creating the task.
  ///   - keepAlive: A Boolean value that indicates whether the task should continue
  ///     running after the view model storage is released.
  ///   - operation: The asynchronous work to perform.
  ///
  /// - Important: `keepAlive` keeps the task alive, but does not keep the view model,
  ///   its environment, or the view model storage alive. Capture required
  ///   dependencies before starting a task that may outlive the view model.
  /// - Returns: The task created for the operation.
  @discardableResult public func task<ID: Hashable & Sendable>(
    id taskID: ID = UUID(),
    name: String? = nil,
    priority: TaskPriority? = nil,
    keepAlive: Bool = false,
  @_implicitSelfCapture operation: @escaping @MainActor () async -> Void
  ) -> Task<Void, Never> {
    let taskID = ViewModelTaskID(taskID)
    viewModelStorage.storage[id]?.tasks[taskID]?.task?.cancel()
    
    let viewModelTask = ViewModelTask<Never>(keepAlive: keepAlive)

    let task = Task(name: name, priority: priority) {
      await withTaskCancellationHandler {
        await operation()
        
        viewModelStorage.removeTaskIfCurrent(viewModelTask, id: taskID, for: id)
        ViewModelTasksBag.bag?.removeTaskIfCurrent(viewModelTask, id: taskID)
      } onCancel: { @MainActor in
        viewModelStorage.removeTaskIfCurrent(viewModelTask, id: taskID, for: id)
        ViewModelTasksBag.bag?.removeTaskIfCurrent(viewModelTask, id: taskID)
      }
    }
    
    viewModelTask.task = task
    
    viewModelStorage.storage[id, default: .init()].tasks[taskID] = viewModelTask
    ViewModelTasksBag.bag?.tasks[taskID] = viewModelTask
    return task
  }
}

// MARK: - ViewModel Task

struct ViewModelTaskID: Hashable, @unchecked Sendable {
  let id: AnyHashable
  init<ID: Hashable & Sendable>(_ id: ID) {
    self.id = id
  }
}

@MainActor
final class ViewModelTask<Failure: Error>: Sendable {
  let keepAlive: Bool
  var task: Task<Void, Failure>?
  
  init(keepAlive: Bool) {
    self.keepAlive = keepAlive
  }
  
  deinit {
    if !keepAlive {
      task?.cancel()
    }
  }
}
