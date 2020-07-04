// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "MorganLetters",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", "3.3.3"..<"3.3.4"),

        // 🍃 An expressive, performant, and extensible templating language built for Swift.
        .package(url: "https://github.com/vapor/leaf.git", "3.0.2"..<"3.0.3"),
        .package(url: "https://github.com/nodes-vapor/bootstrap.git", "1.0.0"..<"1.0.1"),
        .package(url: "https://github.com/vzsg/Curly.git", "0.7.0"..<"0.7.1")
    ],
    targets: [
        .target(name: "App", dependencies: ["Leaf", "Vapor", "Bootstrap", "CurlyClient"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

