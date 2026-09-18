// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required by this package.

import PackageDescription

let package = Package(
  name: "swift-view-model",
  platforms: [.macOS(.v14), .iOS(.v17), .watchOS(.v10), .tvOS(.v17)],
  products: [
    .library(
      name: "SwiftViewModel",
      targets: ["SwiftViewModel"]
    ),
  ],
  dependencies: [
    
  ],
  targets: [
    .target(
      name: "SwiftViewModel",
    ),
    .testTarget(
      name: "SwiftViewModelTests",
      dependencies: ["SwiftViewModel"]
    ),
  ]
)
