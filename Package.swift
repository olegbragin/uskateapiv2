// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "USkateApiV2",
    platforms: [
       .macOS(.v13),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        .package(url: "https://github.com/dankinsoid/VaporToOpenAPI.git", from: "4.7.1")
    ],
    targets: [
        .executableTarget(
            name: "USkateApiV2",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "VaporToOpenAPI", package: "VaporToOpenAPI")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "USkateApiV2Tests",
            dependencies: [
                .target(name: "USkateApiV2"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
    // Enable better optimizations when building in Release configuration. Despite the use of
    // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
    // builds. See <https://github.com/swift-server/guides/blob/main/docs/building.md#building-for-production> for details.
    .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
] }
