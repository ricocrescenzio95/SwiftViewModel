import Testing
import SwiftUI
@testable import SwiftViewModel

@Suite("ViewModel storage and lifecycle", .serialized)
@MainActor
struct ViewModelStorageTests {
  @Test
  func testViewModelObjectInstallsEnvironment() {
    var environment = EnvironmentValues()
    environment.locale = Locale(identifier: "it_IT")

    @TestViewModelObject(environment: environment)
    var viewModel = StorageTestViewModel()

    #expect(viewModel.installedLocale == "it_IT")
  }

  @Test
  func environmentIsStoredForViewModel() {
    let viewModel = StorageTestViewModel()
    var environment = EnvironmentValues()
    environment.locale = Locale(identifier: "it_IT")

    @TestViewModelObject(environment: environment)
    var wrappedViewModel = viewModel

    #expect(viewModelStorage.storage[viewModel.id]?.environment?.locale == environment.locale)
    _ = wrappedViewModel
  }

  @Test
  func testViewModelObjectCallsEnvironmentReadyOnce() async {
    @TestViewModelObject
    var viewModel = StorageTestViewModel()

    #expect(viewModel.environmentReadyCount == 1)
  }

  @Test
  func taskIsStoredUntilItFinishes() async {
    let viewModel = StorageTestViewModel()
    let started = AsyncSignal()
    let mayFinish = AsyncSignal()

    let task = viewModel.task {
      started.signal()
      await mayFinish.wait()
    }

    await started.wait()
    #expect(viewModelStorage.storage[viewModel.id]?.tasks.count == 1)

    mayFinish.signal()
    _ = await task.result

    #expect(viewModelStorage.storage[viewModel.id]?.tasks.isEmpty == true)
  }

  @Test
  func oldTaskCleanupDoesNotRemoveReplacement() async {
    let viewModel = StorageTestViewModel()
    let newTaskMayFinish = AsyncSignal()

    let oldTask = viewModel.task(id: "work") {
      try? await Task.sleep(for: .milliseconds(50))
      guard !Task.isCancelled else { return }
    }

    let newTask = viewModel.task(id: "work") {
      await newTaskMayFinish.wait()
    }

    _ = await oldTask.result
    #expect(viewModelStorage.storage[viewModel.id]?.tasks.count == 1)

    newTaskMayFinish.signal()
    _ = await newTask.result
  }

  @Test
  func throwingTaskIsRemovedAfterCompletion() async {
    let viewModel = StorageTestViewModel()
    let task = viewModel.task { throw StorageTestError.expected }

    _ = await task.result

    #expect(viewModelStorage.storage[viewModel.id]?.throwingTasks.isEmpty == true)
  }

  @Test
  func storageIsRemovedWhenTestWrapperIsReleased() {
    let viewModelID: ObjectIdentifier

    do {
      let viewModel = StorageTestViewModel()
      viewModelID = viewModel.id

      @TestViewModelObject
      var wrappedViewModel = viewModel
      _ = wrappedViewModel

      #expect(viewModelStorage.storage[viewModelID] != nil)
    }

    #expect(viewModelStorage.storage[viewModelID] == nil)
  }
}

private final class StorageTestViewModel: ViewModel {
  private(set) var environmentReadyCount = 0
  private(set) var installedLocale: String?

  func onEnvironmentReady() {
    environmentReadyCount += 1
    installedLocale = environment.locale.identifier
  }
}

@MainActor
private final class AsyncSignal: Sendable {
  private var continuation: CheckedContinuation<Void, Never>?
  private var isSignaled = false

  func wait() async {
    if isSignaled { return }

    await withCheckedContinuation { continuation in
      self.continuation = continuation
    }
  }

  func signal() {
    isSignaled = true
    continuation?.resume()
    continuation = nil
  }
}

private enum StorageTestError: Error {
  case expected
}
