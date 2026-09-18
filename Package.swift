// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "ShortcutFinder", platforms: [.macOS(.v14)], products: [.executable(name: "ShortcutFinder", targets: ["ShortcutFinder"])], targets: [
.target(name: "ShortcutCore", resources: [.process("Resources")]),
.executableTarget(name: "ShortcutFinder", dependencies: ["ShortcutCore"]),
.testTarget(name: "ShortcutCoreTests", dependencies: ["ShortcutCore"]),
.testTarget(name: "ShortcutUITests", dependencies: ["ShortcutFinder"])
])
