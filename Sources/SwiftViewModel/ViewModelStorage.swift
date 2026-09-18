import Foundation
import os
import SwiftUI

final class ViewModelStorage {
  typealias Storage = [ObjectIdentifier: Data]
  struct Data {
    var environment: EnvironmentValues? = nil
    var tasks: [ViewModelTaskID: ViewModelTask<Never>] = [:]
    var throwingTasks: [ViewModelTaskID: ViewModelTask<any Error>] = [:]
  }
  
  var storage: Storage = [:]

  init() {}
  
  @discardableResult
  func removeTaskIfCurrent(
    _ viewModelTask: ViewModelTask<Never>,
    id taskID: ViewModelTaskID,
    for viewModelID: ObjectIdentifier
  ) -> Bool {
    guard storage[viewModelID]?.tasks[taskID] === viewModelTask else {
      return false
    }
    
    storage[viewModelID]?.tasks.removeValue(forKey: taskID)
    return true
  }
  
  @discardableResult
  func removeTaskIfCurrent(
    _ viewModelTask: ViewModelTask<any Error>,
    id taskID: ViewModelTaskID,
    for viewModelID: ObjectIdentifier
  ) -> Bool {
    guard storage[viewModelID]?.throwingTasks[taskID] === viewModelTask else {
      return false
    }
    
    storage[viewModelID]?.throwingTasks.removeValue(forKey: taskID)
    return true
  }
}

@MainActor
let viewModelStorage = ViewModelStorage()
