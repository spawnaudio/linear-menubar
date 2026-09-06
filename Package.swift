// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LinearFocus",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "LinearFocus", targets: ["LinearFocus"])],
    targets: [
        .target(name: "FocusCore"),
        .executableTarget(name: "LinearFocus", dependencies: ["FocusCore"]),
        .testTarget(name: "FocusCoreTests", dependencies: ["FocusCore"])
    ],
    swiftLanguageModes: [.v5]
)
