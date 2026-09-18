import os
import Dispatch
import Foundation

/// Emits a SwiftViewModel runtime warning in debug builds.
///
/// SwiftViewModel uses this helper for diagnostics that should appear in Xcode's
/// runtime issue stream. In release builds, the function doesn't emit a log.
///
/// - Parameter message: The diagnostic message to display.
@_transparent
public func __runtimeWarning(
  _ message: String
) {
  #if DEBUG
  let dso: UnsafeMutableRawPointer = {
    var info = Dl_info()
    dladdr(
      dlsym(
        dlopen(nil, RTLD_LAZY),
        """
        $s10Foundation15AttributeScopesO7Swif\
        tUIE05swiftE0AcDE0D12UIAttributesVmvg
        """
      ),
      &info
    )
    return info.dli_fbase
  }()

  let log = OSLog(
    subsystem: "com.apple.runtime-issues",
    category: "SwiftViewModel"
  )
  os_log(
    .fault,
    dso: dso,
    log: log,
    "%{public}@",
    message
  )
  #endif
}
