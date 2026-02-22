// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CardShowProFeature",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CardShowProFeature",
            targets: ["CardShowProFeature"]
        ),
    ],
    dependencies: [
        // Supabase Swift SDK for backend and authentication
        .package(
            url: "https://github.com/supabase/supabase-swift",
            exact: "2.5.1"
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CardShowProFeature",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "CardShowProFeatureTests",
            dependencies: [
                "CardShowProFeature"
            ]
        ),
    ]
)
