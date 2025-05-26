// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ShipkitApi",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // 🪶 Fluent driver for SQLite.
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.6.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        // AfterShip API Client
        .package(url: "ssh://git@github.com/mike-douglas/swift-aftership.git", branch: "main"),
        // Metrics
        .package(url: "https://github.com/swift-server/swift-prometheus.git", from: "2.0.0"),
        // Email validation
        .package(url: "https://github.com/ekscrypto/SwiftEmailValidator.git", from: "1.0.4"),
    ],
    targets: [
        .executableTarget(
            name: "ShipkitApi",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "AfterShip", package: "swift-aftership"),
                .product(name: "Prometheus", package: "swift-prometheus"),
                .product(name: "SwiftEmailValidator", package: "SwiftEmailValidator"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ShipkitApiTests",
            dependencies: [
                .target(name: "ShipkitApi"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        ),
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
