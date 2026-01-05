// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if arch(arm64)
let exclude = ["blake3_avx2_x86-64_unix.S", "blake3_avx512_x86-64_unix.S", "blake3_sse2_x86-64_unix.S", "blake3_sse41_x86-64_unix.S"]
#else
let exclude = ["blake3_neon.c"]
#endif


let package = Package(
    name: "SwiftBlake3",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftBlake3",
            targets: ["SwiftBlake3"]
        ),
    ],
    targets: [
        
        .target(name: "CBlake3",
                path: "Sources/blake3-1.8.2",
                exclude: exclude,
                cSettings: [
                    .define("BLAKE_USE_NEON", to: "1", .when(platforms: [.macOS, .iOS, .tvOS, .watchOS])),
                ]),
        
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftBlake3",
            dependencies: [
                "CBlake3"
            ],
        ),
        .testTarget(
            name: "SwiftBlake3Tests",
            dependencies: ["SwiftBlake3"],
            resources: [
                .process("test_vectors")
            ]
        ),
    ]
)
