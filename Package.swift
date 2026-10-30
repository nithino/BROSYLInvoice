// swift-tools-version: 5.10
import PackageDescription
let package = Package(name: "BrosylWorkshop", platforms: [.macOS(.v13)], products: [.executable(name: "BrosylWorkshop", targets: ["BrosylApp"])], targets: [.target(name: "BrosylCore"), .executableTarget(name: "BrosylApp", dependencies: ["BrosylCore"], resources: [.process("Resources")]), .testTarget(name: "BrosylCoreTests", dependencies: ["BrosylCore"])])
