// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "FloatCompareWasm",
  products: [
    .library(
      name: "FloatCompareWasm",
      targets: ["FloatCompareWasm"])
  ],
  dependencies: [
    .package(url: "https://github.com/swiftwasm/WasmKit", from: "0.1.5"),
    .package(url: "https://github.com/realm/SwiftLint", from: "0.58.2"),
    .package(
      url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3"
    ),
  ],
  targets: [
    .target(
      name: "FloatCompareWasm",
      dependencies: [
        .product(name: "WasmKit", package: "WasmKit"),
        .product(name: "WAT", package: "WasmKit"),
      ]
    ),
    .testTarget(
      name: "FloatCompareWasmTests",
      dependencies: ["FloatCompareWasm"]
    ),
  ]
)
