// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ProxSync",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(name: "ProxSyncCore", targets: ["ProxSyncCore"]),
        .library(name: "ProxSyncNearby", targets: ["ProxSyncNearby"]),
        .library(name: "ProxSyncHealth", targets: ["ProxSyncHealth"]),
        .library(name: "ProxSyncREST", targets: ["ProxSyncREST"]),
        .library(name: "ProxSyncLocal", targets: ["ProxSyncLocal"]),
        .library(name: "ProxSyncSupabase", targets: ["ProxSyncSupabase"]),
        .library(name: "ProxSyncAuth", targets: ["ProxSyncAuth"]),
        .library(name: "ProxSyncAuthSupabase", targets: ["ProxSyncAuthSupabase"]),
    ],
    targets: [
        .target(
            name: "ProxSyncCore",
            path: "Sources/ProxSyncCore"
        ),
        .target(
            name: "ProxSyncNearby",
            dependencies: ["ProxSyncCore"],
            path: "Sources/ProxSyncNearby"
        ),
        .target(
            name: "ProxSyncHealth",
            dependencies: ["ProxSyncCore"],
            path: "Sources/ProxSyncHealth"
        ),
        .target(
            name: "ProxSyncREST",
            dependencies: ["ProxSyncCore", "ProxSyncLocal"],
            path: "Sources/ProxSyncREST"
        ),
        .target(
            name: "ProxSyncLocal",
            dependencies: ["ProxSyncCore"],
            path: "Sources/ProxSyncLocal"
        ),
        .target(
            name: "ProxSyncSupabase",
            dependencies: ["ProxSyncCore", "ProxSyncLocal", "ProxSyncREST"],
            path: "Sources/ProxSyncSupabase"
        ),
        .target(
                   name: "ProxSyncAuth",
                   path: "Sources/ProxSyncAuth"
        ),
       .target(
           name: "ProxSyncAuthSupabase",
           dependencies: ["ProxSyncAuth"],
           path: "Sources/ProxSyncAuthSupabase"
       ),
        .testTarget(
            name: "ProxSyncCoreTests",
            dependencies: ["ProxSyncCore"],
            path: "Tests/ProxSyncCoreTests"
        )
    ]
)
