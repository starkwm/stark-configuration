// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "StarkConfiguration",
  platforms: [.macOS(.v26)],
  products: [.library(name: "StarkConfiguration", targets: ["StarkConfiguration"])],
  targets: [
    .target(name: "StarkConfiguration"),
    .testTarget(name: "StarkConfigurationTests", dependencies: ["StarkConfiguration"]),
  ],
  swiftLanguageModes: [.v6]
)
