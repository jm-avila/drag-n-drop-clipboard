// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Shelflet",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "ShelfletCore", targets: ["ShelfletCore"]),
        .executable(name: "Shelflet", targets: ["Shelflet"]),
        .executable(name: "ShelfletCoreProbe", targets: ["ShelfletCoreProbe"])
    ],
    targets: [
        .target(name: "ShelfletCore"),
        .executableTarget(name: "Shelflet", dependencies: ["ShelfletCore"]),
        .executableTarget(name: "ShelfletCoreProbe", dependencies: ["ShelfletCore"])
    ]
)
