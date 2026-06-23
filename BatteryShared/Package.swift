// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BatteryShared",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "BatteryShared", targets: ["BatteryShared"])
    ],
    targets: [
        .target(name: "BatteryShared")
    ]
)
