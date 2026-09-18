import Foundation
import Testing
@testable import SwiftViewModel

@Suite("ViewModel tasks")
@MainActor
struct ViewModelTaskTests {
  @Test
  func taskRunsOperation() async {
    let viewModel = TestViewModel()

    await waitViewModelTasks {
      viewModel.start { viewModel.value = 42 }
    }

    #expect(viewModel.value == 42)
  }

  @Test
  func taskCanBeThrowing() async {
    let viewModel = TestViewModel()

    await waitViewModelTasks {
      viewModel.task { throw TestError.expected }
    }

    #expect(viewModel.value == 0)
  }

  @Test
  func waitViewModelTasksRethrowsOperationError() async {
    await #expect(throws: TestError.expected) {
      try await waitViewModelTasks { throw TestError.expected }
    }
  }

  @Test
  func waitViewModelTasksWaitsForAsyncWork() async {
    let viewModel = TestViewModel()

    await waitViewModelTasks {
      viewModel.start {
        await Task.yield()
        viewModel.value = 42
      }
    }

    #expect(viewModel.value == 42)
  }

  @Test
  func startingTaskWithSameIDCancelsPreviousTask() async {
    let viewModel = TestViewModel()

    await waitViewModelTasks {
      viewModel.start(id: "work") {
        try? await Task.sleep(for: .seconds(1))
        guard !Task.isCancelled else { return }
        viewModel.value = 1
      }

      viewModel.start(id: "work") { viewModel.value = 2 }
    }

    #expect(viewModel.value == 2)
  }

  @Test
  func taskCanBeCancelledExplicitly() async {
    let viewModel = TestViewModel()
    let task = viewModel.task {
      try? await Task.sleep(for: .seconds(1))
      guard !Task.isCancelled else { return }
      viewModel.value = 1
    }

    task.cancel()
    _ = await task.result

    #expect(viewModel.value == 0)
  }

  @Test
  func tasksWithDifferentIDsRunIndependently() async {
    let viewModel = TestViewModel()

    await waitViewModelTasks {
      viewModel.start(id: "first") { viewModel.value += 1 }
      viewModel.start(id: "second") { viewModel.value += 2 }
    }

    #expect(viewModel.value == 3)
  }

  @Test
  func multipleTasksAreAllWaitedFor() async {
    let viewModel = TestViewModel()

    await waitViewModelTasks {
      for value in 1...5 {
        viewModel.start(id: value) {
          await Task.yield()
          viewModel.value += value
        }
      }
    }

    #expect(viewModel.value == 15)
  }

  @Test
  func throwingTaskIsRemovedAfterFailure() async {
    let viewModel = TestViewModel()
    let task = viewModel.task { throw TestError.expected }

    _ = await task.result

    #expect(viewModel.value == 0)
  }

  @Test
  func keepAliveTaskCanFinish() async {
    let viewModel = TestViewModel()
    let task = viewModel.task(keepAlive: true) { viewModel.value = 42 }

    _ = await task.result

    #expect(viewModel.value == 42)
  }
}

private final class TestViewModel: ViewModel {
  var value = 0

  func start<ID: Hashable & Sendable>(
    id: ID = UUID(),
    operation: @escaping @MainActor () async -> Void
  ) {
    task(id: id) { await operation() }
  }
}

private enum TestError: Error {
  case expected
}
