import Foundation

@MainActor
final class ViewModelTasksBag {
  @TaskLocal
  static var bag: ViewModelTasksBag?

  var tasks: [ViewModelTaskID: ViewModelTask<Never>] = [:]
  var throwingTasks: [ViewModelTaskID: ViewModelTask<any Error>] = [:]

  var isEmpty: Bool {
    tasks.isEmpty && throwingTasks.isEmpty
  }
  
  @discardableResult
  func removeTaskIfCurrent(
    _ viewModelTask: ViewModelTask<Never>,
    id taskID: ViewModelTaskID,
  ) -> Bool {
    guard tasks[taskID] === viewModelTask else {
      return false
    }
    
    tasks.removeValue(forKey: taskID)
    return true
  }
  
  @discardableResult
  func removeTaskIfCurrent(
    _ viewModelTask: ViewModelTask<any Error>,
    id taskID: ViewModelTaskID,
  ) -> Bool {
    guard throwingTasks[taskID] === viewModelTask else {
      return false
    }
    
    throwingTasks.removeValue(forKey: taskID)
    return true
  }
}

/// Runs an asynchronous operation and waits for all view model tasks created
/// during that operation to finish.
///
/// Use this helper in tests when the code under test starts work with
/// ``ViewModel/task(id:name:priority:keepAlive:operation:)->Task<Void,Never>``. It keeps track of
/// tasks created during the operation, including tasks created by other tasks,
/// and returns only after the tracked task storage is empty.
///
/// The helper also supports throwing test operations. Errors thrown by the
/// operation are rethrown; errors from tracked view model tasks are ignored
/// while waiting for the tasks to finish.
///
/// ```swift
/// @Test
/// func savesNote() async {
///   let storage = NoteStorage()
///
///   @TestViewModelObject(environment: makeEnvironment(noteStorage: storage))
///   var viewModel = NoteEditorViewModel()
///   viewModel.title = "Buy milk"
///
///   #expect(storage.notes.isEmpty)
///
///   await waitViewModelTasks {
///     viewModel.save() // save function contains an async task
///   }
///
///   #expect(storage.notes.count == 1)
/// }
/// ```
nonisolated(nonsending) public func waitViewModelTasks(
  _ operation: nonisolated(nonsending) () async throws -> Void
) async rethrows {
  let bag = ViewModelTasksBag()
  try await ViewModelTasksBag.$bag.withValue(bag) {
    try await operation()

    repeat {
      await withTaskGroup { group in
        for (_, task) in await bag.tasks {
          group.addTask {
            await task.task?.value
          }
        }
        for (_, task) in await bag.throwingTasks {
          group.addTask {
            try? await task.task?.value
          }
        }
      }
    } while await !bag.isEmpty
  }
}
