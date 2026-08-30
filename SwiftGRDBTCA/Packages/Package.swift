// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
  name: "Packages",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "Models", targets: ["Models"])
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.11.0", traits: ["Tagged"]),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.17.0"),
    .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.1.0"),
    .package(url: "https://github.com/pointfreeco/swift-sharing", from: "2.10.0"),
    .package(url: "https://github.com/pointfreeco/swift-structured-queries", from: "0.38.0")
  ],
  targets: [
    .target(
      name: "Models",
      dependencies: [
        .product(name: "SQLiteData", package: "sqlite-data", condition: nil),
        .product(name: "Dependencies", package: "swift-dependencies", condition: nil),
        .product(name: "IdentifiedCollections", package: "swift-identified-collections", condition: nil),
        .product(name: "Sharing", package: "swift-sharing", condition: nil),
        .product(name: "StructuredQueries", package: "swift-structured-queries", condition: nil)
      ]
    ),
    .testTarget(
      name: "ModelsTests",
      dependencies: [
        "Models",
        .product(name: "Dependencies", package: "swift-dependencies", condition: nil)
      ]
    ),
  ]
)
