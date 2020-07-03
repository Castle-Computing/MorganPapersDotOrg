// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "MorganLetters",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),

        // 🍃 An expressive, performant, and extensible templating language built for Swift.
        .package(url: "https://github.com/vapor/leaf.git", from: "3.0.0"),
        .package(url: "https://github.com/nodes-vapor/bootstrap.git", from: "1.0.0"),
        .package(url: "https://github.com/vzsg/Curly.git", from: "0.6.0")
    ],
    targets: [
        .target(name: "App", dependencies: ["Leaf", "Vapor", "Bootstrap", "CurlyClient"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

