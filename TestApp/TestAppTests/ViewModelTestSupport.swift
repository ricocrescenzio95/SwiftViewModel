import SwiftUI
@testable import TestApp

func makeEnvironment(noteStorage: NoteStorage) -> EnvironmentValues {
  var environment = EnvironmentValues()
  environment[NoteStorage.self] = noteStorage
  return environment
}
