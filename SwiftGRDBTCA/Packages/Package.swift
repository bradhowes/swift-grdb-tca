// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
  name: "Packages",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(name: "SharedGRDB", targets: ["SharedGRDB"]),
    .library(name: "Models", targets: ["Models"]),
    .library(name: "MacrosAPI", targets: ["MacrosAPI"]),
    .executable(name: "MacrosClient", targets: ["MacrosClient"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.6.3"),
    .package(url: "https://github.com/groue/GRDB.swift", branch: "v7.0.0-beta.7"),
    .package(url: "https://github.com/pointfreeco/swift-sharing", branch: "main"),
    .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
    .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.1")
  ],
  targets: [
    .target(
      name: "Models",
      dependencies: [
        "SharedGRDB",
        .product(name: "Dependencies", package: "swift-dependencies", condition: nil),
        .product(name: "GRDB", package: "GRDB.swift", condition: nil),
        .product(name: "Sharing", package: "swift-sharing", condition: nil),
        .product(name: "Tagged", package: "swift-tagged", condition: nil)
      ]
    ),
    .target(
      name: "SharedGRDB",
      dependencies: [
        .product(name: "Dependencies", package: "swift-dependencies", condition: nil),
        .product(name: "GRDB", package: "GRDB.swift", condition: nil),
        .product(name: "Sharing", package: "swift-sharing", condition: nil),
        .product(name: "Tagged", package: "swift-tagged", condition: nil)
      ]
    ),
    .macro(
      name: "Macros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
      ]
    ),
    .target(name: "MacrosAPI", dependencies: ["Macros"]),
    .executableTarget(name: "MacrosClient", dependencies: ["MacrosAPI"]),
    .testTarget(
      name: "SharedGRDBTests",
      dependencies: [
        "Models",
        "SharedGRDB"
      ]
    ),
    .testTarget(
      name: "ModelsTests",
      dependencies: [
        "Models",
        .product(name: "Dependencies", package: "swift-dependencies", condition: nil),
        .product(name: "GRDB", package: "GRDB.swift", condition: nil),
        .product(name: "Sharing", package: "swift-sharing", condition: nil),
        .product(name: "Tagged", package: "swift-tagged", condition: nil)
      ]
    ),
  ]
)
